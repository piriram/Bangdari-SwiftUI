import Kingfisher
import SwiftUI
import WaterfallGrid

// MARK: - Community List View

struct CommunityListView: View {
    @StateObject private var intent = CommunityListIntent()
    @StateObject private var videoIntent = VideoListIntent()
    @State private var selectedCategory: String?
    @State private var searchText = ""
    @State private var currentVideoIndex: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            // 커스텀 네비게이션 바
            CustomNavigationBar(showDefaultBackButton: false,backgroundColor: .gray15) {
                EmptyView()
            } center: {
                Text("커뮤니티")
                    .font(NavBarStyle.titleFont)
                    .foregroundColor(NavBarStyle.titleColor)
            } trailing: {
                NavigationLink(destination: PostCreateView {
                    Task { await intent.refresh() }
                }) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 20))
                        .foregroundColor(NavBarStyle.iconColor)
                }
            }

            // 콘텐츠
            Group {
                if intent.state.isLoading && intent.state.posts.isEmpty {
                    ProgressView()
                        .frame(maxHeight: .infinity)
                } else if let error = intent.state.errorMessage, intent.state.posts.isEmpty {
                    errorView(error)
                } else {
                    waterfallContent
                }
            }
        }
        .background(Color.gray15)
        .navigationBarHidden(true)
        .task {
            if intent.state.posts.isEmpty && !intent.state.isLoading {
                await intent.loadPosts()
            }
            if videoIntent.state.videos.isEmpty && !videoIntent.state.isLoading {
                await videoIntent.loadVideos()
            }
        }
    }

    // MARK: - Waterfall Content

    private var waterfallContent: some View {
        ScrollView {
            VStack(spacing: 18) {
                topControlsSection
                videoListSection
                postSection
            }
            .padding(.bottom, 24)
        }
        .refreshable {
            await intent.refresh()
        }
    }

    private var filteredPosts: [PostSummaryResponse] {
        intent.state.posts.filter { post in
            let matchesCategory = selectedCategory == nil || post.category == selectedCategory
            guard matchesCategory else { return false }

            let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !keyword.isEmpty else { return true }

            return post.title.localizedCaseInsensitiveContains(keyword)
                || post.content.localizedCaseInsensitiveContains(keyword)
                || post.creator.nick.localizedCaseInsensitiveContains(keyword)
        }
    }

    private var topControlsSection: some View {
        VStack(spacing: 12) {
            searchBar
            categoryFilter
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var postSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("동네 게시글")
                    .font(.pretendard(.body1, .semiBold))
                    .foregroundColor(.gray90)

                Spacer()

                Text("\(filteredPosts.count)개")
                    .font(.pretendard(.caption1, .medium))
                    .foregroundColor(.gray60)
            }
            .padding(.horizontal, 16)

            if filteredPosts.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 26))
                        .foregroundColor(.gray45)

                    Text("조건에 맞는 게시글이 없어요")
                        .font(.pretendard(.body2, .semiBold))
                        .foregroundColor(.gray75)

                    Text("검색어나 카테고리를 바꿔서 다시 찾아보세요")
                        .font(.pretendard(.caption1))
                        .foregroundColor(.gray60)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(Color.gray0)
                .cornerRadius(16)
                .padding(.horizontal, 16)
            } else {
                WaterfallGrid(filteredPosts, id: \.post_id) { post in
                    NavigationLink(destination: PostDetailView(postId: post.post_id)) {
                        PostCard(post: post)
                    }
                    .buttonStyle(.plain)
                }
                .gridStyle(columns: 2, spacing: 12)
                .padding(.horizontal, 16)
            }

            if intent.state.hasMore && !intent.state.posts.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
                    .onAppear {
                        Task { await intent.loadMore() }
                    }
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(.gray60)

            TextField("제목/내용/작성자 검색", text: $searchText)
                .font(.pretendardBody2)
                .foregroundColor(.gray90)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .onSubmit {
                    intent.updateSearchQuery(searchText)
                    Task { await intent.searchPosts() }
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    intent.updateSearchQuery("")
                    Task { await intent.refresh() }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.gray60)
                }
                .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.gray0)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.gray30, lineWidth: 1)
        )
        .cornerRadius(14)
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("카테고리")
                .font(.pretendard(.caption1, .medium))
                .foregroundColor(.gray60)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChipButton(
                        title: "전체",
                        isActive: selectedCategory == nil,
                        style: .filledActive
                    ) {
                        selectedCategory = nil
                    }

                    ForEach(intent.categories, id: \.self) { category in
                        FilterChipButton(
                            title: category,
                            isActive: selectedCategory == category,
                            style: .filledActive
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    // MARK: - Video List Section

    private var videoListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header with Action
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("숏폼 영상")
                        .font(.pretendard(.body1, .semiBold))
                        .foregroundColor(.gray90)

                    Text("요즘 인기 있는 방다리 커뮤니티 영상")
                        .font(.pretendard(.caption1))
                        .foregroundColor(.gray60)
                }

                Spacer()

                NavigationLink(destination: VideoListView()) {
                    HStack(spacing: 4) {
                        Text("더보기")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .font(.pretendard(.caption1, .semiBold))
                    .foregroundColor(.deepCoast)
                }
            }

            if videoIntent.state.isLoading && videoIntent.state.videos.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else if let error = videoIntent.state.errorMessage, videoIntent.state.videos.isEmpty {
                HStack {
                    Text(error)
                        .font(.pretendardCaption2)
                        .foregroundColor(.gray60)
                        .lineLimit(1)

                    Spacer()

                    Button("재시도") {
                        Task { await videoIntent.loadVideos() }
                    }
                    .font(.pretendardCaption2)
                    .foregroundColor(.deepCoast)
                }
            } else if videoIntent.state.videos.isEmpty {
                Text("등록된 비디오가 없습니다.")
                    .font(.pretendardCaption1)
                    .foregroundColor(.gray60)
            } else {
                // Horizontal Carousel
                VStack(spacing: 12) {
                    GeometryReader { geometry in
                        let cardWidth = max(240, (geometry.size.width - 32 - 12) * 0.75)
                        let cardHeight = cardWidth / 16 * 9

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(videoIntent.state.videos.enumerated()), id: \.element.id) { index, video in
                                    NavigationLink(destination: VideoDetailView(video: video, intent: videoIntent)) {
                                        VideoCarouselCard(
                                            thumbnailURL: thumbnailURL(for: video),
                                            title: video.title,
                                            width: cardWidth,
                                            height: cardHeight
                                        )
                                    }
                                    // .frame(width: cardWidth, height: cardHeight)
                                    .buttonStyle(.plain)
                                    .onAppear {
                                        currentVideoIndex = index
                                        Task {
                                            await videoIntent.ensureStreamURL(for: video.video_id)
                                            if index >= videoIntent.state.videos.count - 2 {
                                                await videoIntent.loadMore()
                                            }
                                        }
                                    }
                                }

                                if videoIntent.state.isLoadingMore {
                                    ProgressView()
                                        .frame(width: 60, height: cardHeight)
                                }
                            }
                            .padding(.horizontal, 16)
                            .scrollTargetLayout()
                        }
                        .scrollTargetBehavior(.viewAligned)
                    }
                    .frame(height: max(135, (max(240, (UIScreen.main.bounds.width - 32 - 12) * 0.75)) / 16 * 9))

                    // Page Indicator
                    if videoIntent.state.videos.count > 1 {
                        HStack(spacing: 6) {
                            ForEach(0..<min(videoIntent.state.videos.count, 5), id: \.self) { index in
                                Circle()
                                    .fill(currentVideoIndex == index ? Color.deepCoast : Color.gray45)
                                    .frame(width: currentVideoIndex == index ? 10 : 8,
                                           height: currentVideoIndex == index ? 10 : 8)
                                    .animation(.spring(response: 0.3), value: currentVideoIndex)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.gray0)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray30, lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    private func thumbnailURL(for video: VideoResponse) -> URL? {
        MockImageMapper.resolvedImageURL(from: video.thumbnail_url)
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(.deepCoast)

            Text(message)
                .font(.pretendard(.body2))
                .foregroundColor(.gray75)
                .multilineTextAlignment(.center)

            Button("다시 시도") {
                Task { await intent.loadPosts() }
            }
            .font(.pretendard(.body3, .semiBold))
            .foregroundColor(.gray0)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(Color.deepCoast)
            .cornerRadius(10)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
        .background(Color.gray0)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray30, lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Video Carousel Card

private struct VideoCarouselCard: View {
    let thumbnailURL: URL?
    let title: String
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Thumbnail Image
            KFImage.auth(url: thumbnailURL)
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .clipped()
                .background(Color.gray30)

            // Gradient Overlay
            LinearGradient(
                colors: [.black.opacity(0.0), .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Play Icon
            Image(systemName: "play.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Title
            Text(title)
                .font(.yeongdeokCaption1())
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// Legacy card for backward compatibility (if needed elsewhere)
private struct CommunityVideoThumbnailCard: View {
    let thumbnailURL: URL?
    let title: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            KFImage.auth(url: thumbnailURL)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .aspectRatio(16 / 9, contentMode: .fit)
                .clipped()
                .background(Color.gray30)

            LinearGradient(
                colors: [.black.opacity(0.0), .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )

            Text(title)
                .font(.yeongdeokCaption1())
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.gray30, lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CommunityListView()
    }
}
