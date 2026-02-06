import PhotosUI
import SwiftUI

// MARK: - Chat Input Bar

struct ChatInputBar: View {
    @Binding var messageText: String
    @Binding var selectedPhotos: [PhotosPickerItem]
    @Binding var selectedImages: [UIImage]
    @FocusState.Binding var isFocused: Bool

    let canSend: Bool
    let onSend: () async -> Void
    let onRemoveImage: (Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 이미지 프리뷰
            if !selectedImages.isEmpty {
                imagePreviewSection
            }

            // 입력 영역
            HStack(spacing: 12) {
                // 파일 첨부 버튼
                PhotosPicker(
                    selection: $selectedPhotos,
                    maxSelectionCount: 5,
                    matching: .images
                ) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray60)
                }

                // Capsule 모양 TextField
                TextField("메시지를 입력하세요", text: $messageText)
                    .font(.pretendard(.body2, .regular))
                    .foregroundColor(.gray90)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.gray15)
                    .clipShape(Capsule())
                    .focused($isFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        Task { await onSend() }
                    }

                // 전송 버튼
                Button {
                    Task { await onSend() }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.title3)
                        .foregroundColor(canSend ? .deepCoast : .gray45)
                }
                .disabled(!canSend)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.gray0)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.gray30)
                .frame(height: 1)
        }
    }

    private var imagePreviewSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(color: .gray90.opacity(0.12), radius: 4, x: 0, y: 2)

                        Button {
                            onRemoveImage(index)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.gray0)
                                .background(Circle().fill(Color.gray90.opacity(0.6)))
                        }
                        .offset(x: 4, y: -4)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.gray15)
    }
}
