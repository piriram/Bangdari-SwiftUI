import SwiftUI
import PhotosUI
import Kingfisher

// MARK: - Profile Edit View

struct ProfileEditView: View {
    @StateObject private var intent = ProfileEditIntent()
    @State private var selectedPhoto: PhotosPickerItem?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // 네비게이션 바
            CustomNavigationBar(showDefaultBackButton: false) {
                Button("취소") { dismiss() }
                    .font(.pretendardBody1)
                    .foregroundColor(.gray75)
            } center: {
                Text("프로필 수정")
                    .font(.pretendardBody1Bold)
                    .foregroundColor(.gray75)
            } trailing: {
                Button("저장") {
                    Task { await intent.saveProfile() }
                }
                .font(.pretendardBody1Bold)
                .foregroundColor(intent.state.isSaveDisabled ? .gray45 : .deepWood)
                .disabled(intent.state.isSaveDisabled)
            }

            Divider()

            ScrollView {
                VStack(spacing: 28) {
                    profileImageSection
                    formSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
            }
        }
        .background(Color.gray0)
        .navigationBarHidden(true)
        .task { await intent.loadProfile() }
        .onChange(of: selectedPhoto) { _, newItem in
            loadSelectedPhoto(newItem)
        }
        .onChange(of: intent.state.isUpdateSuccess) { _, success in
            if success { dismiss() }
        }
        .alert("오류", isPresented: Binding(
            get: { intent.state.errorMessage != nil },
            set: { if !$0 { intent.clearError() } }
        )) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(intent.state.errorMessage ?? "")
        }
    }

    // MARK: - Profile Image

    @ViewBuilder
    private var profileImageSection: some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let image = intent.state.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else if let urlString = intent.state.profileImageURL,
                              let url = URL(string: urlString) {
                        KFImage.auth(url: url)
                            .placeholder { placeholderImage }
                            .resizable()
                            .scaledToFill()
                    } else {
                        placeholderImage
                    }
                }
                .frame(width: 96, height: 96)
                .clipShape(Circle())

                // 카메라 아이콘
                Circle()
                    .fill(Color.gray90)
                    .frame(width: 28, height: 28)
                    .overlay {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
            }
        }
        .buttonStyle(.plain)
    }

    private var placeholderImage: some View {
        Circle()
            .fill(Color.gray30)
            .overlay {
                Image(systemName: "person.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.gray60)
            }
    }

    // MARK: - Form

    @ViewBuilder
    private var formSection: some View {
        // 닉네임
        VStack(alignment: .leading, spacing: 8) {
            Text("닉네임")
                .font(.pretendardBody2Bold)
                .foregroundColor(.gray90)

            TextField("닉네임을 입력해주세요", text: Binding(
                get: { intent.state.nick },
                set: { intent.updateNick($0) }
            ))
            .font(.pretendardBody2)
            .foregroundColor(.gray90)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(height: 48)
            .background(Color.gray15)
            .cornerRadius(8)

            if let error = intent.state.nickValidationError {
                Text(error)
                    .font(.pretendardCaption1)
                    .foregroundColor(.red)
            }
        }

        // 자기소개
        VStack(alignment: .leading, spacing: 8) {
            Text("자기소개")
                .font(.pretendardBody2Bold)
                .foregroundColor(.gray90)

            TextField("자기소개를 입력해주세요", text: Binding(
                get: { intent.state.introduction },
                set: { intent.updateIntroduction($0) }
            ), axis: .vertical)
            .lineLimit(1...4)
            .font(.pretendardBody2)
            .foregroundColor(.gray90)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray15)
            .cornerRadius(8)
        }

        // 전화번호
        VStack(alignment: .leading, spacing: 8) {
            Text("전화번호")
                .font(.pretendardBody2Bold)
                .foregroundColor(.gray90)

            TextField("전화번호를 입력해주세요", text: Binding(
                get: { intent.state.phoneNum },
                set: { intent.updatePhoneNum($0) }
            ))
            .keyboardType(.phonePad)
            .font(.pretendardBody2)
            .foregroundColor(.gray90)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(height: 48)
            .background(Color.gray15)
            .cornerRadius(8)
        }
    }

    // MARK: - Actions

    private func loadSelectedPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else { return }
            intent.setSelectedImage(image)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProfileEditView()
    }
}
