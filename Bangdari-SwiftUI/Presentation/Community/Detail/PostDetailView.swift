import Kingfisher
import SwiftUI

// MARK: - Post Detail View

struct PostDetailView: View {
    @StateObject private var intent: PostDetailIntent
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isCommentFocused: Bool

    init(postId: String) {
        _intent = StateObject(wrappedValue: PostDetailIntent(postId: postId))
    }

    var body: some View {
        VStack(spacing: 0) {
            // 네비게이션 바
            CustomNavigationBar(onBack: { dismiss() }) {
                Text("게시글")
                    .font(NavBarStyle.titleFont)
                    .foregroundColor(NavBarStyle.titleColor)
            } trailing: {
                likeButton
            }

            // 콘텐츠
            Group {
                if intent.state.isLoading && intent.state.post == nil {
                    ProgressView()
                } else if let post = intent.state.post {
                    detailContent(post)
                } else if let error = intent.state.errorMessage {
                    errorView(error)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await intent.loadDetail()
        }
    }

    // MARK: - Detail Content

    private func detailContent(_ post: PostDetailResponse) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 이미지 갤러리
                    if !post.files.isEmpty {
                        imageGallery(post.files)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        // 카테고리
                        Text(post.category)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)

                        // 제목
                        Text(post.title)
                            .font(.title2)
                            .fontWeight(.bold)

                        // 작성자 정보
                        HStack {
                            KFImage.auth(url: profileImageURL(post.creator.profileImage))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 32, height: 32)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(Circle())

                            Text(post.creator.nick)
                                .font(.subheadline)

                            Spacer()

                            Text(formatDate(post.createdAt))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Divider()

                        // 본문
                        Text(post.content)
                            .font(.body)

                        // 좋아요 수
                        HStack {
                            Image(systemName: post.is_like ? "heart.fill" : "heart")
                                .foregroundColor(post.is_like ? .red : .secondary)
                            Text("\(post.like_count)")
                                .foregroundColor(.secondary)
                        }
                        .font(.subheadline)

                        Divider()

                        // 댓글 섹션
                        commentsSection(post.comments)
                    }
                    .padding(.horizontal, 16)
                }
            }

            // 댓글 입력
            commentInputBar
        }
    }

    // MARK: - Image Gallery

    private func imageGallery(_ files: [String]) -> some View {
        TabView {
            ForEach(files, id: \.self) { file in
                KFImage.auth(url: URL(string: Secrets.baseURL + "/" + file))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .background(Color.gray.opacity(0.2))
            }
        }
        .frame(height: 250)
        .tabViewStyle(.page)
    }

    // MARK: - Comments Section

    private func commentsSection(_ comments: [PostComment]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("댓글 \(comments.count)")
                .font(.headline)

            if comments.isEmpty {
                Text("아직 댓글이 없습니다.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(comments) { comment in
                    commentRow(comment)

                    // 대댓글
                    if let replies = comment.replies, !replies.isEmpty {
                        ForEach(replies) { reply in
                            commentRow(reply, isReply: true)
                        }
                    }
                }
            }
        }
    }

    private func commentRow(_ comment: PostComment, isReply: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if isReply {
                Image(systemName: "arrow.turn.down.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 8)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.creator.nick)
                        .font(.caption)
                        .fontWeight(.medium)

                    Spacer()

                    Text(formatDate(comment.createdAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Text(comment.content)
                    .font(.subheadline)

                // 답글 버튼
                if !isReply {
                    Button {
                        intent.setReplyingTo(comment)
                        isCommentFocused = true
                    } label: {
                        Text("답글")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(10)
        .background(isReply ? Color(.systemGray6) : Color(.systemGray5))
        .cornerRadius(8)
    }

    // MARK: - Comment Input Bar

    private var commentInputBar: some View {
        VStack(spacing: 0) {
            // 답글 대상 표시
            if let replyingTo = intent.state.replyingTo {
                HStack {
                    Text("@\(replyingTo.creator.nick)에게 답글")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button {
                        intent.setReplyingTo(nil)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
            }

            Divider()

            HStack(spacing: 12) {
                TextField("댓글을 입력하세요", text: Binding(
                    get: { intent.state.commentText },
                    set: { intent.updateCommentText($0) }
                ))
                .textFieldStyle(.roundedBorder)
                .focused($isCommentFocused)

                Button {
                    Task { await intent.submitComment() }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(intent.state.commentText.isEmpty ? .gray : .blue)
                }
                .disabled(intent.state.commentText.isEmpty || intent.state.isCommentLoading)
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Like Button

    private var likeButton: some View {
        Button {
            Task { await intent.toggleLike() }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: intent.state.isLiked ? "heart.fill" : "heart")
                    .foregroundColor(intent.state.isLiked ? .red : .gray)
                Text("\(intent.state.likeCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .disabled(intent.state.isLikeLoading)
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

            Button("다시 시도") {
                Task { await intent.loadDetail() }
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Helpers

    private func profileImageURL(_ path: String?) -> URL? {
        guard let path else { return nil }
        return URL(string: Secrets.baseURL + "/" + path)
    }

    private func formatDate(_ dateString: String) -> String {
        String(dateString.prefix(10))
    }
}

#Preview {
    NavigationStack {
        PostDetailView(postId: "test")
    }
}
