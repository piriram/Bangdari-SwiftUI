import SwiftUI

// MARK: - Video List View

struct VideoListView: View {
    @StateObject private var intent = VideoListIntent()

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            if intent.state.isLoading && intent.state.videos.isEmpty {
                // 초기 로딩
                ProgressView()
                    .tint(.white)
            } else if let errorMessage = intent.state.errorMessage, intent.state.videos.isEmpty {
                // 에러 상태
                VStack(spacing: 16) {
                    Text(errorMessage)
                        .font(.pretendardBody2)
                        .foregroundColor(.white)
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
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 40)
            } else if !intent.state.videos.isEmpty {
                // 비디오 목록 (TabView 페이징)
                TabView(selection: Binding(
                    get: { intent.state.currentIndex },
                    set: { intent.updateCurrentIndex($0) }
                )) {
                    ForEach(Array(intent.state.videos.enumerated()), id: \.element.id) { index, video in
                        VideoPlayerView(
                            video: video,
                            isCurrentVideo: index == intent.state.currentIndex,
                            streamURL: intent.getStreamURL(for: video.video_id),
                            onLikeTap: {
                                Task {
                                    await intent.toggleLike(for: video.video_id)
                                }
                            }
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()

                // 로딩 인디케이터 (페이지네이션)
                if intent.state.isLoadingMore {
                    VStack {
                        Spacer()
                        ProgressView()
                            .tint(.white)
                            .padding(.bottom, 60)
                    }
                }
            }
        }
        .task {
            if intent.state.videos.isEmpty && !intent.state.isLoading {
                await intent.loadVideos()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VideoListView()
}
