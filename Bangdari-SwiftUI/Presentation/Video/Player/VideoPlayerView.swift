import SwiftUI
import AVKit

// MARK: - Video Player View

struct VideoPlayerView: View {
    let video: VideoResponse
    let isCurrentVideo: Bool
    let streamURL: String?
    let onLikeTap: () -> Void

    @StateObject private var playerManager = VideoPlayerManager.shared

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            if let player = playerManager.player, streamURL != nil {
                VideoPlayer(player: player)
                    .disabled(true)  // 기본 컨트롤 숨김
                    .ignoresSafeArea()
            } else {
                ProgressView()
                    .tint(.white)
            }

            // 오버레이 (제목, 좋아요 등)
            VideoOverlayView(
                video: video,
                onLikeTap: onLikeTap
            )
        }
        .onAppear {
            if isCurrentVideo, let url = streamURL {
                playerManager.loadAndPlay(url: url, videoId: video.video_id)
            }
        }
        .onChange(of: isCurrentVideo) { _, newValue in
            if newValue, let url = streamURL {
                playerManager.loadAndPlay(url: url, videoId: video.video_id)
            } else {
                playerManager.pause()
            }
        }
        .onDisappear {
            playerManager.pause()
        }
    }
}

// MARK: - Video Overlay View

struct VideoOverlayView: View {
    let video: VideoResponse
    let onLikeTap: () -> Void

    var body: some View {
        VStack {
            Spacer()

            HStack(alignment: .bottom) {
                // 좌측 하단: 제목, 설명, 조회수, 재생시간
                VStack(alignment: .leading, spacing: 8) {
                    Text(video.title)
                        .font(.pretendardBody1Bold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)

                    Text(video.description)
                        .font(.pretendardCaption1)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)

                    HStack(spacing: 12) {
                        Text("조회수 \(formatCount(video.view_count))")
                            .font(.pretendardCaption2)
                            .foregroundColor(.white.opacity(0.8))

                        Text(formatDuration(video.duration))
                            .font(.pretendardCaption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                }
                .padding(.leading, 20)
                .padding(.bottom, 40)

                Spacer()

                // 우측 하단: 좋아요 버튼
                VStack(spacing: 4) {
                    Button(action: onLikeTap) {
                        Image(systemName: video.is_liked ? "heart.fill" : "heart")
                            .font(.system(size: 28))
                            .foregroundColor(video.is_liked ? .red : .white)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    }

                    Text("\(formatCount(video.like_count))")
                        .font(.pretendardCaption2)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Helper Methods

    private func formatCount(_ count: Int) -> String {
        if count >= 10000 {
            return String(format: "%.1f만", Double(count) / 10000)
        } else if count >= 1000 {
            return String(format: "%.1fk", Double(count) / 1000)
        } else {
            return "\(count)"
        }
    }

    private func formatDuration(_ seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}
