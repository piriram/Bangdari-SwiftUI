import Combine
import Foundation

// MARK: - Chat Room List State

struct ChatRoomListState {
    var chatRooms: [ChatRoomResponse] = []
    var isLoading: Bool = false
    var errorMessage: String?

    // 현재 로그인 사용자 ID
    var myUserId: String = ""
}

// MARK: - Chat Room List Intent

@MainActor
final class ChatRoomListIntent: ObservableObject {
    @Published private(set) var state = ChatRoomListState()

    private let chatRepository: ChatRepository

    init(chatRepository: ChatRepository? = nil) {
        self.chatRepository = chatRepository ?? DIContainer.shared.makeChatRepository()
        loadMyUserId()
    }

    // MARK: - Setup

    private func loadMyUserId() {
        state.myUserId = KeychainManager.shared.userId ?? ""
    }

    // MARK: - Actions

    func loadChatRooms() async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            let rooms = try await chatRepository.fetchChatRooms()
            state.chatRooms = rooms
        } catch let error as NetworkError {
            state.errorMessage = error.message
        } catch {
            state.errorMessage = "채팅방 목록을 불러오는 중 오류가 발생했습니다."
        }

        state.isLoading = false
    }

    func createChatRoom(opponentId: String) async -> ChatRoomResponse? {
        do {
            let room = try await chatRepository.createOrGetChatRoom(opponentId: opponentId)
            // 새 채팅방이면 목록에 추가
            if !state.chatRooms.contains(where: { $0.room_id == room.room_id }) {
                state.chatRooms.insert(room, at: 0)
            }
            return room
        } catch {
            return nil
        }
    }

    func refresh() async {
        await loadChatRooms()
    }
}
