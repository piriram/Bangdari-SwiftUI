import Foundation

// MARK: - Chat Message Response

struct ChatResponse: Decodable, Identifiable, Equatable {
    let chat_id: String
    let room_id: String
    let content: String
    let createdAt: String
    let sender: UserInfo
    let files: [String]

    var id: String { chat_id }

    private enum CodingKeys: String, CodingKey {
        case chat_id, room_id, content, createdAt, updatedAt, sender, files
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        chat_id = try container.decode(String.self, forKey: .chat_id)
        room_id = try container.decode(String.self, forKey: .room_id)
        content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
        createdAt = try container.decode(String.self, forKey: .createdAt)
        sender = try container.decode(UserInfo.self, forKey: .sender)
        files = try container.decodeIfPresent([String].self, forKey: .files) ?? []
    }

    static func == (lhs: ChatResponse, rhs: ChatResponse) -> Bool {
        lhs.chat_id == rhs.chat_id
    }
}

// MARK: - Chat Room Response

struct ChatRoomResponse: Decodable, Identifiable, Equatable {
    let room_id: String
    let createdAt: String
    let updatedAt: String
    let participants: [UserInfo]
    let lastChat: ChatResponse?

    var id: String { room_id }

    /// 상대방 정보 추출 (현재 로그인 사용자 제외)
    func opponent(myUserId: String) -> UserInfo? {
        participants.first { $0.user_id != myUserId }
    }

    static func == (lhs: ChatRoomResponse, rhs: ChatRoomResponse) -> Bool {
        lhs.room_id == rhs.room_id
    }
}

// MARK: - Chat Room List Response

struct ChatRoomListResponse: Decodable {
    let data: [ChatRoomResponse]
}

// MARK: - Chat List Response

struct ChatListResponse: Decodable {
    let data: [ChatResponse]
}

// MARK: - Chat File Upload Response

struct ChatFileResponse: Decodable {
    let files: [String]
}

// MARK: - Request DTOs

struct CreateChatRoomRequest: Encodable {
    let opponent_id: String
}

struct SendMessageRequest: Encodable {
    let content: String
    let files: [String]?

    init(content: String, files: [String]? = nil) {
        self.content = content
        self.files = files
    }
}
