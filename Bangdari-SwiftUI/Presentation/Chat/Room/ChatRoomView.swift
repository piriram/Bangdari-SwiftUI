import Kingfisher
import PhotosUI
import SwiftUI

// MARK: - Chat Room View

struct ChatRoomView: View {
    @StateObject private var intent: ChatRoomIntent
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isInputFocused: Bool

    init(roomId: String, opponent: UserInfo? = nil) {
        _intent = StateObject(wrappedValue: ChatRoomIntent(roomId: roomId, opponent: opponent))
    }

    var body: some View {
        VStack(spacing: 0) {
            // 네비게이션 바
            CustomNavigationBar(onBack: { dismiss() }) {
                HStack(spacing: 8) {
                    Text(intent.state.opponent?.nick ?? "채팅")
                        .font(.pretendardBody1Bold)
                        .foregroundColor(.gray75)

                    // 연결 상태 표시
                    if intent.state.isConnected {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                    }
                }
            }

            // 메시지 목록
            messageList

            // 입력창
            messageInputBar
        }
        .navigationBarHidden(true)
        .task {
            await intent.onAppear()
        }
        .onDisappear {
            intent.onDisappear()
        }
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    // 이전 메시지 불러오기 버튼
                    if intent.state.hasMore && !intent.state.messages.isEmpty {
                        Button {
                            Task { await intent.loadMoreMessages() }
                        } label: {
                            if intent.state.isLoadingMore {
                                ProgressView()
                            } else {
                                Text("이전 메시지 불러오기")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 8)
                    }

                    // 메시지 버블
                    ForEach(intent.state.messages) { message in
                        messageBubble(message)
                            .id(message.chat_id)
                    }
                }
                .padding()
            }
            .onChange(of: intent.state.messages.count) { _, _ in
                // 새 메시지 시 스크롤
                scrollToBottom(proxy: proxy)
            }
            .onAppear {
                scrollToBottom(proxy: proxy)
            }
        }
        .background(Color(.systemGroupedBackground))
        .overlay {
            if intent.state.isLoading && intent.state.messages.isEmpty {
                ProgressView()
            } else if let error = intent.state.errorMessage, intent.state.messages.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastId = intent.state.messages.last?.chat_id {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }

    // MARK: - Message Bubble

    private func messageBubble(_ message: ChatResponse) -> some View {
        let isMe = message.sender.user_id == intent.state.myUserId
        let prevMessage = previousMessage(for: message)
        let nextMessage = nextMessage(for: message)

        // 연속 메시지 판단: 같은 발신자 & 1분 이내
        let isContinuous = isContinuousMessage(current: message, previous: prevMessage)
        let isLastInGroup = !isContinuousMessage(current: nextMessage, previous: message)

        return VStack(spacing: 2) {
            // 날짜 구분선 (날짜 변경 시)
            if shouldShowDateDivider(current: message, previous: prevMessage) {
                DateDivider(date: parseDate(message.createdAt) ?? Date())
            }

            HStack(alignment: .bottom, spacing: 8) {
                if isMe { Spacer(minLength: 60) }

                // 상대방 프로필 (연속 메시지가 아닐 때만)
                if !isMe && !isContinuous {
                    profileImage(message.sender.profileImage)
                } else if !isMe {
                    // 연속 메시지일 때는 빈 공간 유지
                    Color.clear
                        .frame(width: 36, height: 36)
                }

                VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
                    // 닉네임 (상대방 & 연속 메시지가 아닐 때만)
                    if !isMe && !isContinuous {
                        Text(message.sender.nick)
                            .font(.pretendard(.caption1, .medium))
                            .foregroundColor(.gray60)
                    }

                    // 파일이 있으면 이미지 표시
                    if !message.files.isEmpty {
                        fileContent(message.files)
                    }

                    // 메시지 버블 + 시간
                    HStack(alignment: .bottom, spacing: 6) {
                        if isMe && isLastInGroup {
                            timeText(message.createdAt)
                        }

                        if !message.content.isEmpty {
                            MessageBubble(content: message.content, isMe: isMe)
                        }

                        if !isMe && isLastInGroup {
                            timeText(message.createdAt)
                        }
                    }
                }

                if !isMe { Spacer(minLength: 60) }
            }
        }
    }

    @ViewBuilder
    private func profileImage(_ urlString: String?) -> some View {
        if let urlString,
           let url = URL(string: Secrets.baseURL + "/" + urlString) {
            KFImage.auth(url: url)
                .placeholder {
                    Circle()
                        .fill(Color(.systemGray5))
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 36, height: 36)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
        }
    }

    @ViewBuilder
    private func fileContent(_ files: [String]) -> some View {
        // TODO: PDF 파일 지원
        // - 파일 확장자 체크 (.pdf)
        // - PDF는 썸네일 + 파일명 표시
        // - 탭 시 PDF 뷰어 모달로 표시
        ForEach(files, id: \.self) { file in
            if let url = URL(string: Secrets.baseURL + "/" + file) {
                KFImage.auth(url: url)
                    .placeholder {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .frame(width: 200, height: 150)
                            .overlay {
                                ProgressView()
                            }
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: 200, maxHeight: 200)
                    .cornerRadius(12)
                    .shadow(color: .gray90.opacity(0.12), radius: 4, x: 0, y: 2)
            }
        }
    }

    // MARK: - Input Bar

    private var messageInputBar: some View {
        ChatInputBar(
            messageText: Binding(
                get: { intent.state.messageText },
                set: { intent.updateMessageText($0) }
            ),
            selectedPhotos: Binding(
                get: { intent.state.selectedPhotos },
                set: { intent.updateSelectedPhotos($0) }
            ),
            selectedImages: .constant(intent.state.selectedImages),
            isFocused: $isInputFocused,
            canSend: canSend,
            onSend: { await intent.sendMessage() },
            onRemoveImage: { intent.removeImage(at: $0) }
        )
    }

    private var canSend: Bool {
        let hasText = !intent.state.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasImages = !intent.state.selectedImages.isEmpty
        return (hasText || hasImages) && !intent.state.isSending
    }

    // MARK: - Helpers

    // MARK: - Message Grouping

    private func previousMessage(for message: ChatResponse) -> ChatResponse? {
        guard let index = intent.state.messages.firstIndex(where: { $0.chat_id == message.chat_id }),
              index > 0 else { return nil }
        return intent.state.messages[index - 1]
    }

    private func nextMessage(for message: ChatResponse) -> ChatResponse? {
        guard let index = intent.state.messages.firstIndex(where: { $0.chat_id == message.chat_id }),
              index < intent.state.messages.count - 1 else { return nil }
        return intent.state.messages[index + 1]
    }

    private func isContinuousMessage(current: ChatResponse?, previous: ChatResponse?) -> Bool {
        guard let current, let previous else { return false }

        // 같은 발신자인지 확인
        guard current.sender.user_id == previous.sender.user_id else { return false }

        // 1분 이내인지 확인
        guard let currentDate = parseDate(current.createdAt),
              let previousDate = parseDate(previous.createdAt) else { return false }

        return currentDate.timeIntervalSince(previousDate) < 60
    }

    private func shouldShowDateDivider(current: ChatResponse, previous: ChatResponse?) -> Bool {
        guard let previous else { return true } // 첫 메시지는 날짜 표시

        guard let currentDate = parseDate(current.createdAt),
              let previousDate = parseDate(previous.createdAt) else { return false }

        let calendar = Calendar.current
        return !calendar.isDate(currentDate, inSameDayAs: previousDate)
    }

    private func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: dateString) {
            return date
        }

        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateString)
    }

    private func timeText(_ dateString: String) -> some View {
        Text(formatTime(dateString))
            .font(.pretendard(.caption2, .medium))
            .foregroundColor(.gray60)
    }

    private func formatTime(_ dateString: String) -> String {
        guard let date = parseDate(dateString) else { return "" }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        return dateFormatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ChatRoomView(roomId: "test-room")
    }
}
