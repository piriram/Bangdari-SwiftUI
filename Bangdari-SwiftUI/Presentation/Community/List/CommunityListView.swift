import Kingfisher
import SwiftUI

// MARK: - Community List View

struct CommunityListView: View {
    @StateObject private var intent = CommunityListIntent()
    @State private var showCreatePost = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // 네비게이션 바
            CustomNavigationBar(onBack: { dismiss() }) {
                Text("커뮤니티")
                    .font(.pretendardBody1Bold)
                    .foregroundColor(.gray90)
            } trailing: {
                Button {
                    showCreatePost = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 20))
                        .foregroundColor(.gray90)
                }
            }

            // 검색바
            SearchBar(
                text: Binding(
                    get: { intent.state.searchQuery },
                    set: { intent.updateSearchQuery($0) }
                ),
                placeholder: "게시글 검색",
                onSubmit: {
                    Task { await intent.searchPosts() }
                }
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray0)

            // 콘텐츠
            Group {
                if intent.state.isLoading && intent.state.posts.isEmpty {
                    PostListSkeleton()
                } else if let error = intent.state.errorMessage, intent.state.posts.isEmpty {
                    errorView(error)
                } else {
                    postList
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showCreatePost) {
            NavigationStack {
                PostCreateView {
                    Task { await intent.refresh() }
                }
            }
        }
        .task {
            await intent.loadPosts()
        }
    }

    // MARK: - Post List

    private var postList: some View {
        List {
            ForEach(intent.state.posts) { post in
                NavigationLink(destination: PostDetailView(postId: post.post_id)) {
                    postRow(post)
                }
            }

            // 더 불러오기
            if intent.state.hasMore && !intent.state.posts.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .onAppear {
                        Task { await intent.loadMore() }
                    }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await intent.refresh()
        }
    }

    // MARK: - Post Row

    private func postRow(_ post: PostSummaryResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 카테고리 + 작성자
            HStack {
                Badge(text: post.category, style: badgeStyle(for: post.category))

                Spacer()

                Text(post.creator.nick)
                    .font(.pretendardCaption1)
                    .foregroundColor(.gray60)
            }

            // 제목
            Text(post.title)
                .font(.pretendardBody2Bold)
                .foregroundColor(.gray90)
                .lineLimit(1)

            // 내용 미리보기
            Text(post.content)
                .font(.pretendardBody3)
                .foregroundColor(.gray75)
                .lineLimit(2)

            // 하단 정보
            HStack {
                // 썸네일
                if let firstFile = post.files.first {
                    KFImage.auth(url: URL(string: Secrets.baseURL + "/" + firstFile))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .background(Color.gray30)
                        .clipped()
                        .cornerRadius(8)
                }

                Spacer()

                // 좋아요 + 날짜
                HStack(spacing: 12) {
                    Label("\(post.like_count)", systemImage: post.is_like ? "heart.fill" : "heart")
                        .font(.pretendardCaption1)
                        .foregroundColor(post.is_like ? .red : .gray60)

                    Text(formatDate(post.createdAt))
                        .font(.pretendardCaption1)
                        .foregroundColor(.gray60)
                }
            }
        }
        .padding(.vertical, 8)
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

    // MARK: - Helpers

    private func formatDate(_ dateString: String) -> String {
        String(dateString.prefix(10))
    }

    // MARK: - Badge Style Mapping

    private func badgeStyle(for category: String) -> BadgeStyle {
        switch category {
        case "공지사항", "중요":
            return .accent     // DeepWood
        case "질문", "토론":
            return .primary    // DeepCoast
        case "후기", "정보":
            return .secondary  // BrightCoast
        default:
            return .neutral    // Gray45
        }
    }
}

#Preview {
    NavigationStack {
        CommunityListView()
    }
}
