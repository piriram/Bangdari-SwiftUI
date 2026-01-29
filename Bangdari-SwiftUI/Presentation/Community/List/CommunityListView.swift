import Kingfisher
import SwiftUI

// MARK: - Community List View

struct CommunityListView: View {
    @StateObject private var intent = CommunityListIntent()
    @State private var showCreatePost = false

    var body: some View {
        Group {
            if intent.state.isLoading && intent.state.posts.isEmpty {
                ProgressView()
            } else if let error = intent.state.errorMessage, intent.state.posts.isEmpty {
                errorView(error)
            } else {
                postList
            }
        }
        .searchable(text: Binding(
            get: { intent.state.searchQuery },
            set: { intent.updateSearchQuery($0) }
        ), prompt: "게시글 검색")
        .onSubmit(of: .search) {
            Task { await intent.searchPosts() }
        }
        .standardNavigationBar(title: "커뮤니티")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCreatePost = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
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
        VStack(alignment: .leading, spacing: 8) {
            // 카테고리 + 작성자
            HStack {
                Text(post.category)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(4)

                Spacer()

                Text(post.creator.nick)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // 제목
            Text(post.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)

            // 내용 미리보기
            Text(post.content)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            // 하단 정보
            HStack {
                // 썸네일
                if let firstFile = post.files.first {
                    KFImage.auth(url: URL(string: Secrets.baseURL + "/" + firstFile))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .background(Color.gray.opacity(0.2))
                        .clipped()
                        .cornerRadius(4)
                }

                Spacer()

                // 좋아요 + 날짜
                HStack(spacing: 12) {
                    Label("\(post.like_count)", systemImage: post.is_like ? "heart.fill" : "heart")
                        .font(.caption)
                        .foregroundColor(post.is_like ? .red : .secondary)

                    Text(formatDate(post.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
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
}

#Preview {
    NavigationStack {
        CommunityListView()
    }
}
