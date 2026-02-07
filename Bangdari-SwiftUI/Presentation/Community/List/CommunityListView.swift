import Kingfisher
import SwiftUI
import WaterfallGrid

// MARK: - Community List View

struct CommunityListView: View {
    @StateObject private var intent = CommunityListIntent()
    @State private var selectedCategory: String?
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            // 커스텀 네비게이션 바
            CustomNavigationBar(showDefaultBackButton: false) {
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
                        .font(.system(size: NavBarStyle.iconMedium))
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
            await intent.loadPosts()
        }
    }

    // MARK: - Waterfall Content

    private var waterfallContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 검색바
                searchBar
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                // 카테고리 필터
                categoryFilter
                    .padding(.top, 12)

                // Waterfall 그리드
                WaterfallGrid(intent.state.posts, id: \.post_id) { post in
                    NavigationLink(destination: PostDetailView(postId: post.post_id)) {
                        PostCard(post: post)
                    }
                    .buttonStyle(.plain)
                }
                .gridStyle(columns: 2, spacing: 12)
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // 더 불러오기
                if intent.state.hasMore && !intent.state.posts.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .onAppear {
                            Task { await intent.loadMore() }
                        }
                }
            }
        }
        .refreshable {
            await intent.refresh()
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(.gray60)

            TextField("게시글 검색", text: $searchText)
                .font(.pretendardBody2)
                .foregroundColor(.gray90)
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
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.gray0)
        .cornerRadius(12)
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // 전체 버튼
                FilterChipButton(
                    title: "전체",
                    isActive: selectedCategory == nil
                ) {
                    selectedCategory = nil
                    Task { await intent.refresh() }
                }

                // 카테고리 버튼들
                ForEach(intent.categories, id: \.self) { category in
                    FilterChipButton(
                        title: category,
                        isActive: selectedCategory == category
                    ) {
                        selectedCategory = category
                        // TODO: 카테고리별 필터링 기능 추가
                        // intent.filterByCategory(category)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("다시 시도") {
                Task { await intent.loadPosts() }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CommunityListView()
    }
}
