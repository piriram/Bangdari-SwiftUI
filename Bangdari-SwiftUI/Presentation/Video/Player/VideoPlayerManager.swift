import AVKit
import Foundation
import Combine

// MARK: - Video Player Manager

@MainActor
final class VideoPlayerManager: ObservableObject {
    static let shared = VideoPlayerManager()

    @Published private(set) var player: AVPlayer?
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentVideoId: String?

    private var timeObserver: Any?
    private var statusObservation: NSKeyValueObservation?
    private var errorObservation: NSKeyValueObservation?

    private init() {
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

        // API 문서: "스트리밍 파일(.m3u8, .m4s)은 URL에 토큰이 포함되어 별도 인증 없이 재생 가능"
        print("🎯 [PLAYER] Creating AVPlayerItem with token in URL (no auth headers)")
        let playerItem = AVPlayerItem(url: videoURL)

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
}
