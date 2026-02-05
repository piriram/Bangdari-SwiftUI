import Combine
import SwiftUI

// MARK: - Profile Edit State

struct ProfileEditState {
    // 원본 데이터 (변경 감지용)
    var originalNick: String = ""
    var originalIntroduction: String = ""
    var originalPhoneNum: String = ""
    var profileImageURL: String?

    // 편집 중 데이터
    var nick: String = ""
    var introduction: String = ""
    var phoneNum: String = ""
    var selectedImage: UIImage?

    var isLoading: Bool = false
    var errorMessage: String?
    var isUpdateSuccess: Bool = false

    // MARK: - Computed

    var hasChanges: Bool {
        nick != originalNick ||
        introduction != originalIntroduction ||
        phoneNum != originalPhoneNum ||
        selectedImage != nil
    }

    var nickValidationError: String? {
        guard !nick.isEmpty else { return "닉네임은 빈 문자열로 설정할 수 없습니다." }
        let forbidden: Set<Character> = Set("-.,?*@+^${}()|[]\\")
        guard !nick.contains(where: { forbidden.contains($0) }) else {
            return "닉네임에 사용할 수 없는 문자가 포함되어 있습니다."
        }
        return nil
    }

    var isSaveDisabled: Bool {
        !hasChanges || nickValidationError != nil || isLoading
    }
}

// MARK: - Profile Edit Intent

@MainActor
final class ProfileEditIntent: ObservableObject {
    @Published private(set) var state = ProfileEditState()

    private let userRepository: UserRepository

    init(userRepository: UserRepository? = nil) {
        self.userRepository = userRepository ?? DIContainer.shared.makeUserRepository()
    }

    // MARK: - Actions

    func loadProfile() async {
        state.isLoading = true
        state.errorMessage = nil
        defer { state.isLoading = false }

        do {
            let profile = try await userRepository.getMyProfile()

            // 원본 저장
            state.originalNick = profile.nick
            state.originalIntroduction = profile.introduction ?? ""
            state.originalPhoneNum = profile.phoneNum ?? ""
            if let imagePath = profile.profileImage {
                state.profileImageURL = Secrets.baseURL + imagePath
            }

            // 편집용 복사
            state.nick = profile.nick
            state.introduction = profile.introduction ?? ""
            state.phoneNum = profile.phoneNum ?? ""
        } catch {
            state.errorMessage = "프로필 정보를 가져오는 데 실패했습니다."
        }
    }

    func updateNick(_ value: String) {
        state.nick = value
    }

    func updateIntroduction(_ value: String) {
        state.introduction = value
    }

    func updatePhoneNum(_ value: String) {
        state.phoneNum = value
    }

    func setSelectedImage(_ image: UIImage) {
        state.selectedImage = image
    }

    func clearError() {
        state.errorMessage = nil
    }

    func saveProfile() async {
        state.isLoading = true
        state.errorMessage = nil
        defer { state.isLoading = false }

        do {
            var uploadedImagePath: String? = nil

            // 이미지가 변경된 경우 먼저 업로드
            if let image = state.selectedImage {
                let imageData = compressImage(image)
                let response = try await userRepository.uploadProfileImage(imageData: imageData)
                uploadedImagePath = response.profileImage
            }

            let request = UpdateProfileRequest(
                nick: state.nick,
                introduction: state.introduction,
                phoneNum: state.phoneNum,
                profileImage: uploadedImagePath
            )

            let updated = try await userRepository.updateMyProfile(request: request)

            // 원본 갱신
            state.originalNick = updated.nick
            state.originalIntroduction = updated.introduction ?? ""
            state.originalPhoneNum = updated.phoneNum ?? ""
            if let imagePath = updated.profileImage {
                state.profileImageURL = Secrets.baseURL + imagePath
            }

            state.selectedImage = nil
            state.isUpdateSuccess = true
        } catch {
            state.errorMessage = "프로필 저장에 실패했습니다."
        }
    }

    // MARK: - Private

    private func compressImage(_ image: UIImage) -> Data {
        let resized = resizeIfNeeded(image, maxEdge: 1024)
        let data = resized.jpegData(compressionQuality: 0.7) ?? Data()
        print("📸 Upload: \(data.count / 1024)KB (\(Int(resized.size.width))x\(Int(resized.size.height)))")
        return data
    }

    private func resizeIfNeeded(_ image: UIImage, maxEdge: CGFloat) -> UIImage {
        let (w, h) = (image.size.width * image.scale, image.size.height * image.scale)
        guard max(w, h) > maxEdge else { return image }
        let ratio = maxEdge / max(w, h)
        let newSize = CGSize(width: w * ratio, height: h * ratio)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
