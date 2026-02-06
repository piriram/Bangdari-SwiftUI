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
        guard let videoURL = URL(string: url) else {
            print("Invalid video URL: \(url)")
            return
        }

        // 이미 같은 비디오가 재생 중이면 재생만
        if currentVideoId == videoId {
            play()
            return
        }

        // 새 비디오 로드
        stop()
        currentVideoId = videoId

        let playerItem = AVPlayerItem(url: videoURL)
        player?.replaceCurrentItem(with: playerItem)
        play()
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
