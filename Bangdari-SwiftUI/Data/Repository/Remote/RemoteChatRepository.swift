import Foundation

// MARK: - Remote Chat Repository

final class RemoteChatRepository: ChatRepository {
    private let network = NetworkService.shared

    // MARK: - Chat Room

    func createOrGetChatRoom(opponentId: String) async throws -> ChatRoomResponse {
        let body = CreateChatRoomRequest(opponent_id: opponentId)
        return try await network.request(.createChatRoom, body: body, type: ChatRoomResponse.self)
    }

    func fetchChatRooms() async throws -> [ChatRoomResponse] {
        let response = try await network.request(.chatRooms, type: ChatRoomListResponse.self)
        return response.data
    }

    // MARK: - Messages

    func sendMessage(roomId: String, content: String, files: [String]?) async throws -> ChatResponse {
        let endpoint = APIEndpoint.sendMessage(roomId: roomId)
        let body = SendMessageRequest(content: content, files: files)
        return try await network.request(endpoint, body: body, type: ChatResponse.self)
    }

    func fetchMessages(roomId: String, next: String?) async throws -> [ChatResponse] {
        let endpoint = APIEndpoint.chatMessages(roomId: roomId, next: next)
        let response = try await network.request(endpoint, type: ChatListResponse.self)
        return response.data
    }

    // MARK: - File Upload

    func uploadFiles(roomId: String, files: [Data]) async throws -> [String] {
        let endpoint = APIEndpoint.uploadChatFiles(roomId: roomId)
        let response = try await network.uploadFiles(endpoint, files: files, type: ChatFileResponse.self)
        return response.files
    }
}
