import Foundation
import Combine

// MARK: - Video List State

struct VideoListState {
    var videos: [VideoResponse] = []
    var currentIndex: Int = 0
    var isLoading: Bool = false
    var isLoadingMore: Bool = false
    var errorMessage: String? = nil
    var nextCursor: String? = nil
    var hasMore: Bool = true
    var streamURLCache: [String: String] = [:]  // video_id: stream_url
}

// MARK: - Video List Intent

@MainActor
final class VideoListIntent: ObservableObject {
    @Published private(set) var state = VideoListState()

    private let repository: VideoRepository
    private let limit = 10
    private let initialPrefetchCount = 3
    private var prefetchTask: Task<Void, Never>?  // 이전 prefetch 취소용

    init(repository: VideoRepository) {
        self.repository = repository
    }

    convenience init() {
        self.init(repository: DIContainer.shared.makeVideoRepository())
    }

    // MARK: - Public Methods

    /// 초기 비디오 목록 로드
    func loadVideos() async {
        guard !state.isLoading else { return }
        state.isLoading = true
        state.errorMessage = nil

        do {
            let response = try await repository.fetchVideos(next: nil, limit: limit)
            state.videos = response.data
            state.nextCursor = response.next_cursor
            state.hasMore = response.hasMore

            // 초기 진입 시 2~3개를 미리 발급해 다음 영상 전환 지연 최소화
            let initialVideoIds = response.data.prefix(initialPrefetchCount).map(\.video_id)
            if let firstVideoId = initialVideoIds.first {
                await prefetchStreamURL(for: firstVideoId)

                for videoId in initialVideoIds.dropFirst() {
                    Task { [weak self] in
                        await self?.prefetchStreamURL(for: videoId)
                    }
                }
            }

            state.isLoading = false
        } catch let error as NetworkError {
            state.errorMessage = error.message
            state.isLoading = false
        } catch {
            state.errorMessage = "비디오 목록을 불러오는데 실패했습니다."
            state.isLoading = false
        }
    }

    /// 페이지네이션 (더 많은 비디오 로드)
    func loadMore() async {
        guard !state.isLoadingMore,
              state.hasMore,
              let cursor = state.nextCursor,
              !cursor.isEmpty else {
            return
        }

        state.isLoadingMore = true

        do {
            let response = try await repository.fetchVideos(next: cursor, limit: limit)
            state.videos.append(contentsOf: response.data)
            state.nextCursor = response.next_cursor
            state.hasMore = response.hasMore
            state.isLoadingMore = false
        } catch is NetworkError {
            state.isLoadingMore = false
            // 페이지네이션 에러는 조용히 처리 (사용자 경험 방해 안 함)
        } catch {
            state.isLoadingMore = false
        }
    }

    /// 현재 재생 중인 비디오 인덱스 업데이트
    func updateCurrentIndex(_ newIndex: Int) {
        print("📍 [INDEX] updateCurrentIndex: \(state.currentIndex) → \(newIndex)")
        state.currentIndex = newIndex

        // 이전 prefetch 작업 취소
        prefetchTask?.cancel()

        prefetchTask = Task {
            // Prefetch: 현재 비디오의 스트림 URL 발급 (우선, 재시도 로직 포함)
            if newIndex < state.videos.count {
                let currentVideoId = state.videos[newIndex].video_id
                print("   ⚡ Prefetching CURRENT video: \(currentVideoId)")
                
                // 현재 비디오는 토큰 갱신을 위해 새로 요청 (캐시 무시)
                await prefetchStreamURLWithRetry(for: currentVideoId)
            }

            // Prefetch: 다음 비디오의 스트림 URL 미리 발급 (백그라운드)
            let nextIndex = newIndex + 1
            if nextIndex < state.videos.count {
                let nextVideoId = state.videos[nextIndex].video_id
                if state.streamURLCache[nextVideoId] == nil {
                    print("   ⏭️  Prefetching NEXT video: \(nextVideoId)")
                    await prefetchStreamURL(for: nextVideoId)
                }
            }

            // 페이지네이션: 끝에서 2개 남았을 때 자동 로드
            if newIndex >= state.videos.count - 2 {
                await loadMore()
            }
        }
    }

    /// 좋아요 토글
    func toggleLike(for videoId: String) async {
        do {
            _ = try await repository.toggleLike(videoId: videoId, likeStatus: true)

            // 비디오 목록 다시 로드하여 최신 상태 반영
            await loadVideos()
        } catch {
            print("Failed to toggle like: \(error)")
        }
    }

    /// 스트림 URL 가져오기 (캐시 우선)
    func getStreamURL(for videoId: String) -> String? {
        let url = state.streamURLCache[videoId]
        print("🔍 [CACHE] getStreamURL for \(videoId): \(url != nil ? "✅ Found" : "❌ Not found")")
        if let url = url {
            print("   🔗 URL: \(url)")
        }
        return url
    }

    /// 스트림 URL 보장 (캐시 없으면 발급)
    func ensureStreamURL(for videoId: String) async {
        if state.streamURLCache[videoId] == nil {
            await prefetchStreamURL(for: videoId)
        }
    }

    /// 스트림 URL 새로 발급 (토큰 갱신)
    func refreshStreamURL(for videoId: String) async {
        await prefetchStreamURLWithRetry(for: videoId)
    }

    // MARK: - Private Methods

    /// 스트림 URL Prefetch (백그라운드)
    private func prefetchStreamURL(for videoId: String) async {
        guard state.streamURLCache[videoId] == nil else {
            return
        }

        do {
            let response = try await repository.fetchStreamURL(videoId: videoId)
            let selectedStreamPath = preferredStreamPath(from: response)

            // 🔍 DEBUG: 상대 경로 → 절대 URL 변환
            let absoluteURL = Secrets.baseURL + selectedStreamPath
            print("🎬 [VIDEO] Prefetched stream URL for \(videoId)")
            print("   📍 Master: \(response.stream_url)")
            print("   🎯 Selected: \(selectedStreamPath)")
            print("   🌐 Absolute: \(absoluteURL)")

            state.streamURLCache[videoId] = absoluteURL
        } catch {
            print("❌ Failed to prefetch stream URL for \(videoId): \(error)")
        }
    }

    /// 스트림 URL Prefetch with Retry (토큰 만료 대비)
    private func prefetchStreamURLWithRetry(for videoId: String) async {
        // 현재 비디오는 토큰이 만료될 수 있으므로 항상 새로 요청
        do {
            let response = try await repository.fetchStreamURL(videoId: videoId)
            let selectedStreamPath = preferredStreamPath(from: response)
            let absoluteURL = Secrets.baseURL + selectedStreamPath
            print("🎬 [VIDEO] Prefetched stream URL for \(videoId) (FRESH TOKEN)")
            print("   📍 Master: \(response.stream_url)")
            print("   🎯 Selected: \(selectedStreamPath)")
            print("   🌐 Absolute: \(absoluteURL)")

            state.streamURLCache[videoId] = absoluteURL
        } catch {
            print("❌ Failed to prefetch stream URL for \(videoId): \(error)")
        }
    }

    /// 임시 우회: subtitles가 포함된 master.m3u8 파싱 실패 시 quality m3u8 우선 사용
    private func preferredStreamPath(from response: VideoStreamResponse) -> String {
        guard !response.subtitles.isEmpty else {
            return response.stream_url
        }

        let qualityPriority = ["720p", "1080p", "480p"]
        for quality in qualityPriority {
            if let url = response.qualities.first(where: { $0.quality == quality })?.url {
                return url
            }
        }

        return response.qualities.first?.url ?? response.stream_url
    }
}
