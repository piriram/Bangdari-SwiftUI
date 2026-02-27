import Combine
import Foundation
import PhotosUI
import SwiftUI

// MARK: - Chat Room State

struct ChatRoomState {
    var messages: [ChatResponse] = []
    var isLoading: Bool = false
    var isLoadingMore: Bool = false
    var isSending: Bool = false
    var errorMessage: String?

    // 메시지 입력
    var messageText: String = ""

    // 파일 업로드
    var selectedPhotos: [PhotosPickerItem] = []
    var selectedImages: [UIImage] = []
    var isUploadingFiles: Bool = false

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
            // 메시지를 시간순으로 표시 (위 = 오래된 것, 아래 = 최신 것)
            state.messages = messages
            state.oldestMessageDate = messages.first?.createdAt
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
            // 이전 메시지를 앞에 추가 (오래된 메시지)
            state.messages.insert(contentsOf: messages, at: 0)
            state.oldestMessageDate = messages.first?.createdAt
            state.hasMore = !messages.isEmpty
        } catch {
            // 페이지네이션 에러는 조용히 처리
        }

        state.isLoadingMore = false
    }

    func sendMessage() async {
        let content = state.messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasContent = !content.isEmpty
        let hasImages = !state.selectedImages.isEmpty

        guard hasContent || hasImages else { return }

        // TODO: 파일 검증 로직 추가
        // - 5MB 용량 제한 체크
        // - 5개 개수 제한 체크
        // - 허용 확장자 체크 (jpg, jpeg, png, gif, pdf)
        // - 검증 실패 시 사용자에게 알림

        state.isSending = true
        let savedContent = content
        let savedImages = state.selectedImages

        // 입력창 즉시 비우기
        state.messageText = ""
        state.selectedImages = []
        state.selectedPhotos = []

        do {
            // TODO: 업로드 진행률 표시
            // - isUploadingFiles 상태 활용
            // - 파일별 진행률 표시

            // 1. 파일이 있으면 먼저 업로드
            var fileUrls: [String]? = nil
            if !savedImages.isEmpty {
                let filesData = savedImages.compactMap { $0.jpegData(compressionQuality: 0.8) }
                fileUrls = try await chatRepository.uploadFiles(roomId: roomId, files: filesData)
            }

            // 2. 메시지 전송
            let message = try await chatRepository.sendMessage(
                roomId: roomId,
                content: content,
                files: fileUrls
            )

            // 메시지 추가 (중복 체크)
            appendMessageIfNeeded(message)
        } catch {
            // 전송 실패 시 복원
            state.messageText = savedContent
            state.selectedImages = savedImages
        }

        state.isSending = false
    }

    func updateMessageText(_ text: String) {
        state.messageText = text
    }

    // MARK: - File Upload

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
        state.selectedPhotos.remove(at: index)
    }

    // MARK: - Socket Helpers

    private func appendMessageIfNeeded(_ message: ChatResponse) {
        // 중복 방지 (REST 응답 + Socket 수신 중복 가능)
        guard !state.messages.contains(where: { $0.chat_id == message.chat_id }) else { return }
        state.messages.append(message)
    }
}
