import SwiftUI

// MARK: - Post Create View

struct PostCreateView: View {
    @StateObject private var intent = PostCreateIntent()
    @Environment(\.dismiss) private var dismiss
    var onSuccess: (() -> Void)?

    var body: some View {
        Form {
            // 카테고리 선택
            Section("카테고리") {
                Picker("카테고리 선택", selection: Binding(
                    get: { intent.state.category },
                    set: { intent.updateCategory($0) }
                )) {
                    Text("선택하세요").tag("")
                    ForEach(intent.categories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                .pickerStyle(.menu)
            }

            // 제목
            Section("제목") {
                TextField("제목을 입력하세요", text: Binding(
                    get: { intent.state.title },
                    set: { intent.updateTitle($0) }
                ))
            }

            // 내용
            Section("내용") {
                TextEditor(text: Binding(
                    get: { intent.state.content },
                    set: { intent.updateContent($0) }
                ))
                .frame(minHeight: 200)
            }

            // 에러 메시지
            if let error = intent.state.errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .standardNavigationBar(title: "글 작성")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("취소") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("등록") {
                    Task { await intent.submit() }
                }
                .disabled(!intent.state.canSubmit || intent.state.isLoading)
            }
        }
        .disabled(intent.state.isLoading)
        .overlay {
            if intent.state.isLoading {
                ProgressView()
            }
        }
        .onChange(of: intent.state.isSuccess) { _, success in
            if success {
                onSuccess?()
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationStack {
        PostCreateView()
    }
}
