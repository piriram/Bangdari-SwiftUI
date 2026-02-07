import SwiftUI

struct EstateCommentView: View {
    @StateObject private var intent: EstateCommentIntent
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isCommentFocused: Bool
    @State private var confirmDeleteCommentId: String? = nil

    init(estateId: String) {
        _intent = StateObject(wrappedValue: EstateCommentIntent(estateId: estateId))
    }

    var body: some View {
        VStack(spacing: 0) {
            // 네비게이션 바
            CustomNavigationBar(onBack: { dismiss() }) {
                Text("댓글 \(intent.state.comments.count)")
                    .font(NavBarStyle.titleFont)
                    .foregroundColor(NavBarStyle.titleColor)
            }

            // 콘텐츠
            ZStack(alignment: .bottom) {
                // 댓글 목록
                ScrollView {
                    VStack(spacing: 0) {
                        if intent.state.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if intent.state.comments.isEmpty {
                            emptyState
                        } else {
                            commentsSection
                        }
                    }
                    .padding(.bottom, 80) // 입력 바 공간
                }

                // 댓글 입력 바
                commentInputBar
                    .background(Color.gray0)
            }
        }
        .navigationBarHidden(true)
        .confirmationDialog("댓글을 삭제하시겠습니다?", isPresented: Binding(
            get: { confirmDeleteCommentId != nil },
            set: { if !$0 { confirmDeleteCommentId = nil } }
        )) {
            Button("삭제", role: .destructive) {
                if let commentId = confirmDeleteCommentId {
                    Task { await intent.deleteComment(commentId) }
                    confirmDeleteCommentId = nil
                }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("삭제된 댓글은 복구할 수 없습니다.")
        }
        .task {
            await intent.loadComments()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left")
                .font(.system(size: 48))
                .foregroundColor(.gray60)

            Text("아직 댓글이 없습니다")
                .font(.pretendard(.body2))
                .foregroundColor(.gray75)

            Text("첫 댓글을 작성해보세요!")
                .font(.pretendard(.caption1))
                .foregroundColor(.gray60)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }

    // MARK: - Comments Section

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(intent.state.comments) { comment in
                commentRow(comment)

                // 대댓글
                if let replies = comment.replies, !replies.isEmpty {
                    ForEach(replies) { reply in
                        commentRow(reply, isReply: true)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
    }

    // MARK: - Comment Row

    private func commentRow(_ comment: EstateComment, isReply: Bool = false) -> some View {
        let isOwner = comment.creator.user_id == intent.state.myUserId
        let isEditing = intent.state.editingCommentId == comment.comment_id

        return HStack(alignment: .top, spacing: 12) {
            if isReply {
                Image(systemName: "arrow.turn.down.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray60)
                    .padding(.leading, 20)
            }

            VStack(alignment: .leading, spacing: 6) {
                // 작성자 + 날짜 + 메뉴
                HStack {
                    Text(comment.creator.nick)
                        .font(.pretendard(.caption1, .semiBold))
                        .foregroundColor(.gray90)

                    Spacer()

                    Text(formatDate(comment.createdAt))
                        .font(.pretendard(.caption2))
                        .foregroundColor(.gray60)

                    if isOwner {
                        Menu {
                            Button {
                                intent.startEditing(comment)
                            } label: {
                                Label("수정", systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                confirmDeleteCommentId = comment.comment_id
                            } label: {
                                Label("삭제", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 16))
                                .foregroundColor(.gray60)
                        }
                    }
                }

                // 수정 모드 or 일반 표시
                if isEditing {
                    TextField("수정 중...", text: Binding(
                        get: { intent.state.editingText },
                        set: { intent.updateEditingText($0) }
                    ), axis: .vertical)
                    .lineLimit(1...4)
                    .font(.pretendard(.body2))
                    .textFieldStyle(.plain)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color.gray15)
                    .cornerRadius(8)

                    HStack(spacing: 12) {
                        Button {
                            intent.cancelEditing()
                        } label: {
                            Text("취소")
                                .font(.pretendard(.caption1, .medium))
                                .foregroundColor(.gray60)
                        }

                        Button {
                            Task { await intent.saveEdit() }
                        } label: {
                            Text("저장")
                                .font(.pretendard(.caption1, .semiBold))
                                .foregroundColor(.deepCoast)
                        }
                        .disabled(intent.state.editingText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.top, 4)
                } else {
                    // 댓글 내용
                    Text(comment.content)
                        .font(.pretendard(.body2))
                        .foregroundColor(.gray75)
                        .lineSpacing(4)

                    // 답글 버튼 (대댓글에는 표시 안함)
                    if !isReply {
                        Button {
                            intent.setReplyingTo(comment)
                            isCommentFocused = true
                        } label: {
                            Text("답글")
                                .font(.pretendard(.caption1, .medium))
                                .foregroundColor(.deepCoast)
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
        .padding(12)
        .background(isReply ? Color.gray15 : Color.gray30)
        .cornerRadius(12)
    }

    // MARK: - Comment Input Bar

    private var commentInputBar: some View {
        VStack(spacing: 0) {
            // 답글 대상 표시
            if let replyingTo = intent.state.replyingTo {
                HStack(spacing: 8) {
                    Text("@\(replyingTo.creator.nick)에게 답글")
                        .font(.pretendard(.caption1))
                        .foregroundColor(.gray75)

                    Spacer()

                    Button {
                        intent.setReplyingTo(nil)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray60)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.gray30)
            }

            Divider()

            // 입력 필드
            HStack(spacing: 12) {
                TextField("댓글을 입력하세요", text: Binding(
                    get: { intent.state.commentText },
                    set: { intent.updateCommentText($0) }
                ), axis: .vertical)
                .lineLimit(1...4)
                .font(.pretendard(.body2))
                .textFieldStyle(.plain)
                .focused($isCommentFocused)

                Button {
                    Task {
                        await intent.submitComment()
                    }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(
                            intent.state.commentText.isEmpty ? .gray60 : .deepCoast
                        )
                }
                .disabled(intent.state.commentText.isEmpty || intent.state.isCommentLoading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray0)
        }
        .background(
            Rectangle()
                .fill(Color.gray0)
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: -2)
        )
    }

    // MARK: - Date Formatter

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }

        let now = Date()
        let interval = now.timeIntervalSince(date)

        if interval < 60 {
            return "방금 전"
        } else if interval < 3600 {
            return "\(Int(interval / 60))분 전"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))시간 전"
        } else {
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "MM.dd"
            return dayFormatter.string(from: date)
        }
    }
}
