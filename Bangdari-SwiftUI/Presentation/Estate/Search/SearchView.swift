import SwiftUI

// MARK: - Search Navigation Tag

struct SearchNavigationTag: Hashable {}

// MARK: - Search View

struct SearchView: View {
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            // 검색 바
            SearchBar(text: $searchText)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

            // TODO: 검색 API 연동 및 결과 표시
            Spacer()
        }
        .background(Color.gray15)
        .navigationTitle("검색")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SearchView()
    }
}
