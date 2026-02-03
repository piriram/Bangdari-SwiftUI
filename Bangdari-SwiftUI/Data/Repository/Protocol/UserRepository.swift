import Foundation

// MARK: - User Repository Protocol

protocol UserRepository {
    // Profile
    func getMyProfile() async throws -> MyInfoResponseDTO
    func updateMyProfile(request: UpdateProfileRequest) async throws -> MyInfoResponseDTO
    func uploadProfileImage(imageData: Data) async throws -> ProfileImageUploadResponse
    func getUserProfile(userId: String) async throws -> UserInfoResponseDTO

    // Device Token
    func updateDeviceToken(token: String) async throws

    // Search
    func searchUsers(nick: String) async throws -> UserSearchResponse
}
