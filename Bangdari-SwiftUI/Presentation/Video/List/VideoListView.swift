import SwiftUI
import Kingfisher

// MARK: - Video List View

struct VideoListView: View {
    @StateObject private var intent = VideoListIntent()

    var body: some View {
        Group {
            if intent.state.isLoading && intent.state.videos.isEmpty {
                ProgressView()
                    .tint(.gray60)
            } else if let errorMessage = intent.state.errorMessage, intent.state.videos.isEmpty {
                errorView(message: errorMessage)
            } else {
                videoFeedView
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("비디오")
        .navigationBarTitleDisplayMode(.large)
        .task {
            if intent.state.videos.isEmpty && !intent.state.isLoading {
                await intent.loadVideos()
            }
        }
    }

    private var videoFeedView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(intent.state.videos.enumerated()), id: \.element.id) { index, video in
                    NavigationLink {
                        VideoDetailView(video: video, intent: intent)
                    } label: {
                        VideoFeedCard(
                            video: video,
                            thumbnailURL: thumbnailURL(for: video)
                        )
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        Task {
                            await intent.ensureStreamURL(for: video.video_id)
                            if index >= intent.state.videos.count - 2 {
                                await intent.loadMore()
                            }
                        }
                    }
                }

                if intent.state.isLoadingMore {
                    ProgressView()
                        .tint(.gray60)
                        .padding(.vertical, 16)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Text(message)
                .font(.pretendardBody2)
                .foregroundColor(.gray90)
                .multilineTextAlignment(.center)

            Button(action: {
                Task {
                    await intent.loadVideos()
                }
            }) {
                Text("다시 시도")
                    .font(.pretendardBody2Bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.deepCoast)
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal, 24)
    }

    private func thumbnailURL(for video: VideoResponse) -> URL? {
        let separator = video.thumbnail_url.hasPrefix("/") ? "" : "/"
        return URL(string: Secrets.baseURL + separator + video.thumbnail_url)
    }
}

private struct VideoFeedCard: View {
    let video: VideoResponse
    let thumbnailURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                KFImage.auth(url: thumbnailURL)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .clipped()

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.white.opacity(0.92))
                    .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 2)
            }
            .background(Color.gray30)

            VStack(alignment: .leading, spacing: 6) {
                Text(video.title)
                    .font(.pretendardBody1Bold)
                    .foregroundColor(.gray75)
                    .lineLimit(2)

                Text(video.description)
                    .font(.pretendardBody2)
                    .foregroundColor(.gray75)
                    .lineLimit(3)

                HStack(spacing: 12) {
                    Text("조회수 \(video.view_count)")
                    Text("좋아요 \(video.like_count)")
                    Text(formattedDuration(video.duration))
                }
                .font(.pretendardCaption2)
                .foregroundColor(.gray45)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.gray30, lineWidth: 1)
        )
    }

    private func formattedDuration(_ seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        VideoListView()
    }
}
