import PhotosUI
import SwiftUI

// MARK: - Post Create View

struct PostCreateView: View {
    @StateObject private var intent = PostCreateIntent()
    @Environment(\.dismiss) private var dismiss
    var onSuccess: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            // 네비게이션 바
            CustomNavigationBar(showDefaultBackButton: false) {
                Button("취소") {
                    dismiss()
                }
                .font(NavBarStyle.buttonFont)
                .foregroundColor(NavBarStyle.buttonColor)
            } center: {
                Text("글 작성")
                    .font(NavBarStyle.titleFont)
                    .foregroundColor(NavBarStyle.titleColor)
            } trailing: {
                Button("등록") {
                    Task { await intent.submit() }
                }
                .font(NavBarStyle.buttonFont)
                .foregroundColor(intent.state.canSubmit && !intent.state.isLoading ? NavBarStyle.buttonColorPrimary : .gray60)
                .disabled(!intent.state.canSubmit || intent.state.isLoading)
            }

            // 콘텐츠
            ScrollView {
                VStack(spacing: 20) {
                    // 이미지 미리보기 (선택된 이미지가 있을 때만)
                    if !intent.state.selectedImages.isEmpty {
                        imagePreviewSection
                    }

                    // 이미지 추가 버튼
                    imagePickerSection

                    // 카테고리 선택
                    categorySection

                    // 제목 입력
                    titleSection

                    // 내용 입력
                    contentSection

                    // 에러 메시지
                    if let error = intent.state.errorMessage {
                        errorSection(error)
                    }
                }
                .padding(.vertical, 20)
            }
            .background(Color.gray15)
            .disabled(intent.state.isLoading)
            .overlay {
                if intent.state.isLoading {
                    loadingOverlay
                }
            }
        }
        .navigationBarHidden(true)
        .onChange(of: intent.state.isSuccess) { _, success in
            if success {
                onSuccess?()
                dismiss()
            }
        }
    }

    // MARK: - Image Preview Section

    private var imagePreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("사진 미리보기")
                .font(.pretendard(.body2, .semiBold))
                .foregroundColor(.gray90)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(intent.state.selectedImages.enumerated()), id: \.offset) { index, image in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .gray90.opacity(0.12), radius: 4, x: 0, y: 2)

                            Button {
                                intent.removeImage(at: index)
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
            }
        }
    }

    // MARK: - Image Picker Section

    private var imagePickerSection: some View {
        VStack(spacing: 0) {
            PhotosPicker(
                selection: Binding(
                    get: { intent.state.selectedPhotos },
                    set: { intent.updateSelectedPhotos($0) }
                ),
                maxSelectionCount: 5,
                matching: .images
            ) {
                HStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.title3)
                        .foregroundColor(.brightWood)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("사진 추가")
                            .font(.pretendard(.body2, .semiBold))
                            .foregroundColor(.gray90)

                        Text("최대 5장, 각 5MB 이하")
                            .font(.pretendard(.caption1, .regular))
                            .foregroundColor(.gray60)
                    }

                    Spacer()

                    Text("\(intent.state.selectedImages.count)/5")
                        .font(.pretendard(.body2, .medium))
                        .foregroundColor(.gray60)
                }
                .padding(16)
                .background(Color.gray0)
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("카테고리")
                .font(.pretendard(.body2, .semiBold))
                .foregroundColor(.gray90)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(intent.categories, id: \.self) { category in
                        FilterChipButton(
                            title: category,
                            isActive: intent.state.category == category
                        ) {
                            intent.updateCategory(category)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("제목")
                .font(.pretendard(.body2, .semiBold))
                .foregroundColor(.gray90)
                .padding(.horizontal, 16)

            TextField("제목을 입력하세요", text: Binding(
                get: { intent.state.title },
                set: { intent.updateTitle($0) }
            ))
            .font(.pretendard(.body2, .regular))
            .foregroundColor(.gray90)
            .padding(16)
            .background(Color.gray0)
            .cornerRadius(12)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Content Section

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("내용")
                .font(.pretendard(.body2, .semiBold))
                .foregroundColor(.gray90)
                .padding(.horizontal, 16)

            ZStack(alignment: .topLeading) {
                TextEditor(text: Binding(
                    get: { intent.state.content },
                    set: { intent.updateContent($0) }
                ))
                .font(.pretendard(.body2, .regular))
                .foregroundColor(.gray90)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 200)
                .padding(12)
                .background(Color.gray0)
                .cornerRadius(12)

                if intent.state.content.isEmpty {
                    Text("내용을 입력하세요")
                        .font(.pretendard(.body2, .regular))
                        .foregroundColor(.gray60)
                        .padding(.top, 20)
                        .padding(.leading, 16)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Error Section

    private func errorSection(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.caption)

            Text(message)
                .font(.pretendard(.caption1, .regular))
                .foregroundColor(.red)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal, 16)
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .tint(.gray0)
                    .scaleEffect(1.2)

                Text(intent.state.isUploadingFiles ? "이미지 업로드 중..." : "게시글 등록 중...")
                    .font(.pretendard(.body2, .medium))
                    .foregroundColor(.gray0)
            }
            .padding(24)
            .background(Color.gray90.opacity(0.9))
            .cornerRadius(16)
        }
    }
}

#Preview {
    NavigationStack {
        PostCreateView()
    }
}
