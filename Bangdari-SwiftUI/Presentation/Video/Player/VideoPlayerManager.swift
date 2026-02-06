import AVKit
import Foundation
import Combine

// MARK: - Video Player Manager

@MainActor
final class VideoPlayerManager: NSObject, ObservableObject {
    static let shared = VideoPlayerManager()

    @Published private(set) var player: AVPlayer?
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentVideoId: String?

    private var timeObserver: Any?
    private var statusObservation: NSKeyValueObservation?
    private var errorObservation: NSKeyValueObservation?
    private let urlSession: URLSession
    private let keychain = KeychainManager.shared

    private override init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.urlSession = URLSession(configuration: config)

        super.init()
        setupPlayer()
    }

    // MARK: - Setup

    private func setupPlayer() {
        player = AVPlayer()
        player?.automaticallyWaitsToMinimizeStalling = true
    }

    // MARK: - Public Methods

    /// 비디오 로드 및 재생
    func loadAndPlay(url: String, videoId: String) {
        print("🎬 [PLAYER] loadAndPlay called")
        print("   🆔 videoId: \(videoId)")
        print("   🔗 url: \(url)")

        guard let videoURL = URL(string: url) else {
            print("❌ [PLAYER] Invalid video URL: \(url)")
            return
        }

        print("✅ [PLAYER] URL created successfully: \(videoURL)")

        // 이미 같은 비디오가 재생 중이면 재생만
        if currentVideoId == videoId {
            print("♻️  [PLAYER] Same video, resuming play")
            play()
            return
        }

        // 새 비디오 로드
        print("🔄 [PLAYER] Loading new video...")
        stop()
        currentVideoId = videoId

        // 커스텀 스킴 URL 생성 (AVAssetResourceLoader를 사용하기 위함)
        guard let customURL = createCustomSchemeURL(from: videoURL) else {
            print("❌ [PLAYER] Failed to create custom scheme URL")
            return
        }

        print("🎯 [PLAYER] Creating AVAsset with custom resource loader")

        // AVURLAsset 생성 및 ResourceLoader 설정
        let asset = AVURLAsset(url: customURL)
        asset.resourceLoader.setDelegate(
            self,
            queue: DispatchQueue(label: "com.bangdari.resourceloader")
        )

        let playerItem = AVPlayerItem(asset: asset)

        // AVPlayerItem 상태 모니터링
        statusObservation = playerItem.observe(\.status, options: [.new, .old]) { [weak self] item, change in
            DispatchQueue.main.async {
                print("📊 [PLAYER] Item status changed: \(item.status.rawValue)")
                switch item.status {
                case .readyToPlay:
                    print("✅ [PLAYER] Ready to play")
                case .failed:
                    print("❌ [PLAYER] Failed to load")
                    if let error = item.error {
                        print("   Error: \(error.localizedDescription)")
                    }
                case .unknown:
                    print("⏳ [PLAYER] Unknown status")
                @unknown default:
                    print("⚠️  [PLAYER] Unknown status: \(item.status.rawValue)")
                }
            }
        }

        // 에러 모니터링
        errorObservation = playerItem.observe(\.error, options: [.new]) { item, change in
            if let error = item.error {
                print("❌ [PLAYER] Item error: \(error.localizedDescription)")
                print("   Error details: \(error)")

                // AVPlayerItem errorLog 출력 (상세 정보)
                if let errorLog = item.errorLog() {
                    print("📋 [PLAYER] Error Log:")
                    for event in errorLog.events {
                        print("   - URI: \(event.uri ?? "nil")")
                        print("   - Error Status: \(event.errorStatusCode)")
                        print("   - Error Domain: \(event.errorDomain)")
                        print("   - Error Comment: \(event.errorComment ?? "nil")")
                        print("   - Server Address: \(event.serverAddress ?? "nil")")
                    }
                }
            }
        }

        player?.replaceCurrentItem(with: playerItem)
        play()
        print("▶️  [PLAYER] Playback started")
    }

    /// 재생
    func play() {
        player?.play()
        isPlaying = true
    }

    /// 일시정지
    func pause() {
        player?.pause()
        isPlaying = false
    }

    /// 정지 (완전 중단)
    func stop() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        currentVideoId = nil
        isPlaying = false
    }

    /// 특정 시간으로 이동
    func seek(to time: CMTime) {
        player?.seek(to: time)
    }

    // MARK: - Cleanup

    nonisolated deinit {
        // deinit는 main actor에서 실행되지 않으므로 player 직접 접근 불가
        // AVPlayer는 자동으로 정리됨
    }

    // MARK: - Private Helpers

    /// HTTPS URL을 커스텀 스킴 URL로 변환 (custom-https://)
    private func createCustomSchemeURL(from url: URL) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        // https를 custom-https로 변경
        if components.scheme == "https" {
            components.scheme = "custom-https"
        } else if components.scheme == "http" {
            components.scheme = "custom-http"
        }

        return components.url
    }

    /// 커스텀 스킴 URL을 실제 HTTPS URL로 복원
    private func convertToHTTPSURL(_ customURL: URL) -> URL {
        guard var components = URLComponents(url: customURL, resolvingAgainstBaseURL: false) else {
            return customURL
        }

        components.scheme = components.scheme?.replacingOccurrences(of: "custom-", with: "")
        return components.url ?? customURL
    }

    /// AVAssetResourceLoadingRequest 처리 (실제 네트워크 요청)
    @MainActor
    private func handleLoadingRequest(_ loadingRequest: AVAssetResourceLoadingRequest) async {
        guard let url = loadingRequest.request.url else {
            loadingRequest.finishLoading(with: NSError(
                domain: "VideoPlayerManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]
            ))
            return
        }

        // custom-https를 https로 복원
        let actualURL = convertToHTTPSURL(url)

        do {
            // 인증 헤더를 포함한 URLRequest 생성
            var request = URLRequest(url: actualURL)
            request.setValue(Secrets.sesacKey, forHTTPHeaderField: "SeSACKey")
            request.setValue("Bangdari-iOS/1.0", forHTTPHeaderField: "User-Agent")

            // Authorization 헤더 추가
            if let token = keychain.accessToken {
                request.setValue(token, forHTTPHeaderField: "Authorization")
                print("🔑 [RESOURCE] Token found: \(token.prefix(20))...")
            } else {
                print("⚠️  [RESOURCE] No accessToken in keychain")
            }

            print("📡 [RESOURCE] Fetching: \(actualURL.absoluteString)")
            print("📤 [RESOURCE] Request Headers:")
            print("   - SeSACKey: \(Secrets.sesacKey.prefix(10))...")
            print("   - User-Agent: Bangdari-iOS/1.0")
            if request.value(forHTTPHeaderField: "Authorization") != nil {
                print("   - Authorization: ✅ Present")
            } else {
                print("   - Authorization: ❌ Missing")
            }

            // 데이터 다운로드
            let (data, response) = try await urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "VideoPlayerManager", code: -2, userInfo: [
                    NSLocalizedDescriptionKey: "Invalid HTTP response"
                ])
            }

            print("✅ [RESOURCE] Response: \(httpResponse.statusCode)")
            print("📥 [RESOURCE] Response Headers:")
            print("   - Content-Type: \(httpResponse.value(forHTTPHeaderField: "Content-Type") ?? "nil")")
            print("   - Content-Length: \(httpResponse.value(forHTTPHeaderField: "Content-Length") ?? "nil")")
            print("📦 [RESOURCE] Data size: \(data.count) bytes")

            // HTTP 444 에러 상세 로깅
            if httpResponse.statusCode == 444 {
                print("🚨 [RESOURCE] HTTP 444 detected!")
                print("   All Response Headers:")
                for (key, value) in httpResponse.allHeaderFields {
                    print("   - \(key): \(value)")
                }

                // 응답 본문 출력 (에러 메시지 확인)
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 [RESOURCE] Response Body:")
                    print("   \(responseString)")
                } else {
                    print("📄 [RESOURCE] Response Body: (non-UTF8 data)")
                }
            }

            // 응답 헤더 전달 (Content-Type, Content-Length 등)
            if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") {
                loadingRequest.contentInformationRequest?.contentType = contentType
            }
            if let contentLength = httpResponse.value(forHTTPHeaderField: "Content-Length"),
               let length = Int64(contentLength) {
                loadingRequest.contentInformationRequest?.contentLength = length
            }
            loadingRequest.contentInformationRequest?.isByteRangeAccessSupported = true

            // 데이터 전달
            loadingRequest.dataRequest?.respond(with: data)
            loadingRequest.finishLoading()

        } catch {
            print("❌ [RESOURCE] Error: \(error.localizedDescription)")
            loadingRequest.finishLoading(with: error)
        }
    }
}

// MARK: - AVAssetResourceLoaderDelegate

extension VideoPlayerManager: AVAssetResourceLoaderDelegate {

    nonisolated func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
    ) -> Bool {
        print("🔄 [RESOURCE] Loading request: \(loadingRequest.request.url?.absoluteString ?? "nil")")

        Task {
            await handleLoadingRequest(loadingRequest)
        }

        return true
    }

    nonisolated func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        didCancel loadingRequest: AVAssetResourceLoadingRequest
    ) {
        print("❌ [RESOURCE] Request cancelled: \(loadingRequest.request.url?.absoluteString ?? "nil")")
    }
}
