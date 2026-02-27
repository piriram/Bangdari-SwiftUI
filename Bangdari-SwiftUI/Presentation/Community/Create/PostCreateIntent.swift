import Combine
import CoreLocation
import Foundation
import PhotosUI
import SwiftUI

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

    // 이미지
    var selectedPhotos: [PhotosPickerItem] = []
    var selectedImages: [UIImage] = []
    var isUploadingFiles: Bool = false

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
    let categories = ["정보", "질문", "후기", "영상" ,"기타"]

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

    // MARK: - Image Actions

    func updateSelectedPhotos(_ items: [PhotosPickerItem]) {
        state.selectedPhotos = items
        Task {
            await loadImages(from: items)
        }
    }

    private func loadImages(from items: [PhotosPickerItem]) async {
        var loadedImages: [UIImage] = []

        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                loadedImages.append(image)
            }
        }

        state.selectedImages = loadedImages
    }

    func removeImage(at index: Int) {
        guard index < state.selectedImages.count else { return }
        state.selectedImages.remove(at: index)

        // PhotosPickerItem도 동기화
        if index < state.selectedPhotos.count {
            state.selectedPhotos.remove(at: index)
        }
    }

    private func compressImage(_ image: UIImage) -> Data {
        let resized = resizeIfNeeded(image, maxEdge: 1024)
        let data = resized.jpegData(compressionQuality: 0.8) ?? Data()
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

    // MARK: - Submit

    func submit() async {
        guard state.canSubmit, let location = state.location else { return }

        state.isLoading = true
        state.errorMessage = nil

        do {
            // 1. 이미지 업로드 (있는 경우)
            var uploadedFileUrls: [String]?
            if !state.selectedImages.isEmpty {
                state.isUploadingFiles = true
                let compressedFiles = state.selectedImages.map { compressImage($0) }
                uploadedFileUrls = try await postRepository.uploadFiles(files: compressedFiles)
                state.isUploadingFiles = false
            }

            // 2. 게시글 생성
            let request = PostCreateRequest(
                category: state.category,
                title: state.title,
                content: state.content,
                longitude: location.longitude,
                latitude: location.latitude,
                files: uploadedFileUrls
            )

            _ = try await postRepository.createPost(request: request)
            state.isSuccess = true
        } catch let error as NetworkError {
            state.errorMessage = error.message
        } catch {
            state.errorMessage = "게시글 작성 중 오류가 발생했습니다."
        }

        state.isUploadingFiles = false
        state.isLoading = false
    }
}
