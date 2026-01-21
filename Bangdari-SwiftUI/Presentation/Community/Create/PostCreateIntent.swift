import Combine
import CoreLocation
import Foundation

// MARK: - Post Create State

struct PostCreateState {
    var category: String = ""
    var title: String = ""
    var content: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    var isSuccess: Bool = false

    // 위치
    var location: CLLocationCoordinate2D?

    var canSubmit: Bool {
        !category.isEmpty && !title.isEmpty && !content.isEmpty && location != nil
    }
}

// MARK: - Post Create Intent

@MainActor
final class PostCreateIntent: ObservableObject {
    @Published private(set) var state = PostCreateState()

    private let postRepository: PostRepository
    private let locationManager = CLLocationManager()

    // 카테고리 옵션
    let categories = ["일상", "정보", "질문", "후기", "기타"]

    init(postRepository: PostRepository? = nil) {
        self.postRepository = postRepository ?? DIContainer.shared.makePostRepository()
        setupLocation()
    }

    // MARK: - Setup

    private func setupLocation() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        if let location = locationManager.location {
            state.location = location.coordinate
        }
    }

    // MARK: - Actions

    func updateCategory(_ category: String) {
        state.category = category
    }

    func updateTitle(_ title: String) {
        state.title = title
    }

    func updateContent(_ content: String) {
        state.content = content
    }

    func submit() async {
        guard state.canSubmit, let location = state.location else { return }

        state.isLoading = true
        state.errorMessage = nil

        let request = PostCreateRequest(
            category: state.category,
            title: state.title,
            content: state.content,
            longitude: location.longitude,
            latitude: location.latitude,
            files: nil
        )

        do {
            _ = try await postRepository.createPost(request: request)
            state.isSuccess = true
        } catch let error as NetworkError {
            state.errorMessage = error.message
        } catch {
            state.errorMessage = "게시글 작성 중 오류가 발생했습니다."
        }

        state.isLoading = false
    }
}
