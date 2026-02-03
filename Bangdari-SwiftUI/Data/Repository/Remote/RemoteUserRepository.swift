import Foundation

// MARK: - Remote User Repository

final class RemoteUserRepository: UserRepository {
    private let network = NetworkService.shared

    // MARK: - Profile

    func getMyProfile() async throws -> MyInfoResponseDTO {
        return try await network.request(
            .myProfile,
            type: MyInfoResponseDTO.self
        )
    }

    func updateMyProfile(request: UpdateProfileRequest) async throws -> MyInfoResponseDTO {
        return try await network.request(
            .updateMyProfile,
            body: request,
            type: MyInfoResponseDTO.self
        )
    }

    func uploadProfileImage(imageData: Data) async throws -> ProfileImageUploadResponse {
        return try await network.uploadFiles(
            .uploadProfileImage,
            files: [imageData],
            fieldName: "profile",
            type: ProfileImageUploadResponse.self
        )
    }

    func getUserProfile(userId: String) async throws -> UserInfoResponseDTO {
        return try await network.request(
            .userProfile(userId: userId),
            type: UserInfoResponseDTO.self
        )
    }

    // MARK: - Device Token

    func updateDeviceToken(token: String) async throws {
        let request = DeviceTokenRequest(deviceToken: token)
        try await network.requestWithoutResponse(
            .updateDeviceToken,
            body: request
        )
    }

    // MARK: - Search

    func searchUsers(nick: String) async throws -> UserSearchResponse {
        return try await network.request(
            .searchUsers(nick: nick),
            type: UserSearchResponse.self
        )
    }
}
