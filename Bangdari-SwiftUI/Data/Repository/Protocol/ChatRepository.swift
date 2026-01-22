import Foundation

// MARK: - Chat Repository Protocol

protocol ChatRepository {
    // MARK: - Chat Room

    /// 채팅방 생성 또는 기존 채팅방 조회
    func createOrGetChatRoom(opponentId: String) async throws -> ChatRoomResponse

    /// 채팅방 목록 조회
    func fetchChatRooms() async throws -> [ChatRoomResponse]

    // MARK: - Messages

    /// 메시지 전송
    func sendMessage(roomId: String, content: String, files: [String]?) async throws -> ChatResponse

    /// 채팅 내역 조회 (시간 기반 페이지네이션)
    /// - Parameters:
    ///   - roomId: 채팅방 ID
    ///   - next: 조회 기준 시각 (UTC). nil이면 전체 내역 조회
    func fetchMessages(roomId: String, next: String?) async throws -> [ChatResponse]

    // MARK: - File Upload

    /// 채팅방 파일 업로드
    func uploadFiles(roomId: String, files: [Data]) async throws -> [String]
}
