import Combine
import Foundation

// MARK: - Chat Room State

struct ChatRoomState {
    var messages: [ChatResponse] = []
    var isLoading: Bool = false
    var isLoadingMore: Bool = false
    var isSending: Bool = false
    var errorMessage: String?

    // 메시지 입력
    var messageText: String = ""

    // 페이지네이션 (시간 기반)
    var oldestMessageDate: String? = nil
    var hasMore: Bool = true

    // 사용자 정보
    var myUserId: String = ""
    var opponent: UserInfo?

    // Socket 연결 상태
    var isConnected: Bool = false
}

// MARK: - Chat Room Intent

@MainActor
final class ChatRoomIntent: ObservableObject {
    @Published private(set) var state = ChatRoomState()

    private let chatRepository: ChatRepository
    private let roomId: String
    private var socketManager: ChatSocketManager?

    init(roomId: String, opponent: UserInfo? = nil, chatRepository: ChatRepository? = nil) {
        self.roomId = roomId
        self.chatRepository = chatRepository ?? DIContainer.shared.makeChatRepository()
        state.opponent = opponent
        loadMyUserId()
    }

    // MARK: - Lifecycle

    func onAppear() async {
        await loadMessages()
        setupSocket()
    }

    func onDisappear() {
        socketManager?.disconnect()
        socketManager = nil
    }

    // MARK: - Setup

    private func loadMyUserId() {
        state.myUserId = KeychainManager.shared.userId ?? ""
    }

    private func setupSocket() {
        socketManager = ChatSocketManager(roomId: roomId)

        socketManager?.onMessage = { [weak self] message in
            Task { @MainActor in
                self?.appendMessageIfNeeded(message)
            }
        }

        socketManager?.onConnectionChanged = { [weak self] connected in
            Task { @MainActor in
                self?.state.isConnected = connected
            }
        }

        socketManager?.connect()
    }

    // MARK: - Actions

    func loadMessages() async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            let messages = try await chatRepository.fetchMessages(roomId: roomId, next: nil)
            // 메시지를 오래된 순서로 정렬 (위에서 아래로 시간순)
            state.messages = messages.reversed()
            state.oldestMessageDate = messages.last?.createdAt
            state.hasMore = !messages.isEmpty
        } catch let error as NetworkError {
            state.errorMessage = error.message
        } catch {
            state.errorMessage = "메시지를 불러오는 중 오류가 발생했습니다."
        }

        state.isLoading = false
    }

    func loadMoreMessages() async {
        guard !state.isLoadingMore, state.hasMore, let next = state.oldestMessageDate else { return }

        state.isLoadingMore = true

        do {
            let messages = try await chatRepository.fetchMessages(roomId: roomId, next: next)
            // 이전 메시지를 앞에 추가
            state.messages.insert(contentsOf: messages.reversed(), at: 0)
            state.oldestMessageDate = messages.last?.createdAt
            state.hasMore = !messages.isEmpty
        } catch {
            // 페이지네이션 에러는 조용히 처리
        }

        state.isLoadingMore = false
    }

    func sendMessage() async {
        let content = state.messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        state.isSending = true
        state.messageText = "" // 입력창 즉시 비우기

        do {
            let message = try await chatRepository.sendMessage(
                roomId: roomId,
                content: content,
                files: nil
            )
            // 메시지 추가 (중복 체크)
            appendMessageIfNeeded(message)
        } catch {
            // 전송 실패 시 메시지 복원
            state.messageText = content
        }

        state.isSending = false
    }

    func updateMessageText(_ text: String) {
        state.messageText = text
    }

    // MARK: - Socket Helpers

    private func appendMessageIfNeeded(_ message: ChatResponse) {
        // 중복 방지 (REST 응답 + Socket 수신 중복 가능)
        guard !state.messages.contains(where: { $0.chat_id == message.chat_id }) else { return }
        state.messages.append(message)
    }
}
