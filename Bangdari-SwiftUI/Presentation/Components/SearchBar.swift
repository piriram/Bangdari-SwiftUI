import SwiftUI

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "검색어를 입력해주세요."
    var onSubmit: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray60)
                .font(.system(size: 16))

            TextField(placeholder, text: $text)
                .font(.pretendardBody2)
                .foregroundColor(.gray90)
                .onSubmit {
                    onSubmit?()
                }

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray45)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(Color.gray15)
        .clipShape(Capsule())
    }
}

// MARK: - Display Only Search Bar (탭하면 검색 화면으로 이동)

struct SearchBarButton: View {
    var placeholder: String = "검색어를 입력해주세요."
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray60)
                    .font(.system(size: 16))

                Text(placeholder)
                    .font(.pretendardBody2)
                    .foregroundColor(.gray60)

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(Color.gray15)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 20) {
        SearchBar(text: .constant(""))
        SearchBar(text: .constant("강남"))
        SearchBarButton {}
    }
    .padding()
}
