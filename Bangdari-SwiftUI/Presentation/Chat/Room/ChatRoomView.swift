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
                        .foregroundColor(.gray90)

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

        return HStack(alignment: .bottom, spacing: 8) {
            if isMe { Spacer(minLength: 60) }

            // 상대방 프로필 (상대 메시지만)
            if !isMe {
                profileImage(message.sender.profileImage)
            }

            VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
                // 닉네임 (상대방만)
                if !isMe {
                    Text(message.sender.nick)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // 파일이 있으면 이미지 표시
                if !message.files.isEmpty {
                    fileContent(message.files)
                }

                // 텍스트 메시지
                if !message.content.isEmpty {
                    Text(message.content)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(isMe ? Color.accentColor : Color(.systemGray5))
                        .foregroundColor(isMe ? .white : .primary)
                        .cornerRadius(18)
                }

                // 시간
                Text(formatTime(message.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if !isMe { Spacer(minLength: 60) }
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
            }
        }
    }

    // MARK: - Input Bar

    private var messageInputBar: some View {
        VStack(spacing: 0) {
            // 선택된 이미지 프리뷰
            if !intent.state.selectedImages.isEmpty {
                selectedImagesPreview
            }

            HStack(spacing: 12) {
                // 파일 첨부 버튼
                PhotosPicker(
                    selection: Binding(
                        get: { intent.state.selectedPhotos },
                        set: { intent.updateSelectedPhotos($0) }
                    ),
                    maxSelectionCount: 5,
                    matching: .images
                ) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }

                // 텍스트 입력
                TextField("메시지를 입력하세요", text: Binding(
                    get: { intent.state.messageText },
                    set: { intent.updateMessageText($0) }
                ))
                .textFieldStyle(.roundedBorder)
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit {
                    Task { await intent.sendMessage() }
                }

                // 전송 버튼
                Button {
                    Task { await intent.sendMessage() }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.title3)
                        .foregroundColor(canSend ? .accentColor : .secondary)
                }
                .disabled(!canSend)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private var selectedImagesPreview: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(intent.state.selectedImages.enumerated()), id: \.offset) { index, image in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        // 삭제 버튼
                        Button {
                            intent.removeImage(at: index)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                        .offset(x: 4, y: -4)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGray6))
    }

    private var canSend: Bool {
        let hasText = !intent.state.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasImages = !intent.state.selectedImages.isEmpty
        return (hasText || hasImages) && !intent.state.isSending
    }

    // MARK: - Helpers

    private func formatTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: dateString) else {
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: dateString) else {
                return ""
            }
            return formatTimeOnly(date)
        }

        return formatTimeOnly(date)
    }

    private func formatTimeOnly(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "a h:mm"
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
