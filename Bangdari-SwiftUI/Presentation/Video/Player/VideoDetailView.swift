import SwiftUI
import AVKit

struct VideoDetailView: View {
    let video: VideoResponse
    @ObservedObject var intent: VideoListIntent

    @State private var player = AVPlayer()
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var currentStreamURL: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                playerSection
                    .frame(height: 230)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 10) {
                    Text(video.title)
                        .font(.pretendard(.body1))
                        .foregroundColor(.gray90)

                    Text(video.description)
                        .font(.pretendardBody2)
                        .foregroundColor(.gray75)
                        .lineSpacing(5)

                    HStack(spacing: 12) {
                        Text("조회수 \(video.view_count)")
                        Text("좋아요 \(video.like_count)")
                        Text(durationText(video.duration))
                    }
                    .font(.pretendardCaption1)
                    .foregroundColor(.gray45)
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("비디오 재생")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: video.video_id) {
            await loadStreamAndPlay()
        }
        .onDisappear {
            player.pause()
        }
    }

    private var playerSection: some View {
        ZStack {
            Color.black

            if currentStreamURL != nil {
                NativeVideoPlayerController(player: player)
            } else if isLoading {
                ProgressView("영상 준비 중")
                    .tint(.white)
                    .foregroundColor(.white)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                    Text(errorMessage ?? "영상을 재생할 수 없습니다.")
                        .font(.pretendardBody2)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
            }
        }
    }

    private func loadStreamAndPlay() async {
        isLoading = true
        errorMessage = nil

        if let cached = intent.getStreamURL(for: video.video_id) {
            playStream(cached)
        }

        await intent.refreshStreamURL(for: video.video_id)

        if let latest = intent.getStreamURL(for: video.video_id) {
            playStream(latest)
            isLoading = false
            return
        }

        if currentStreamURL == nil {
            errorMessage = "재생 URL을 가져오지 못했습니다."
        }
        isLoading = false
    }

    private func playStream(_ rawURL: String) {
        let normalizedURL = normalizedStreamURL(rawURL)
        guard let url = URL(string: normalizedURL) else {
            errorMessage = "재생 URL 형식이 올바르지 않습니다."
            return
        }

        currentStreamURL = normalizedURL
        errorMessage = nil
        player.replaceCurrentItem(with: AVPlayerItem(url: url))
        player.play()
    }

    private func normalizedStreamURL(_ rawURL: String) -> String {
        guard var components = URLComponents(string: rawURL) else {
            return rawURL
        }

        if components.path.hasPrefix("/v1/videos/stream/") {
            return rawURL
        }

        if components.path.hasPrefix("/videos/stream/") {
            components.path = "/v1" + components.path
            return components.url?.absoluteString ?? rawURL
        }

        return rawURL
    }

    private func durationText(_ seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

private struct NativeVideoPlayerController: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        controller.allowsPictureInPicturePlayback = true
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }
}
