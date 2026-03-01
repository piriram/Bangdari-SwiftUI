import SwiftUI
import MapKit

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var intent = SearchIntent()
    @FocusState private var isSearchFocused: Bool
    let onSearchCompleted: ((CLLocationCoordinate2D, MKCoordinateSpan) -> Void)?

    init(onSearchCompleted: ((CLLocationCoordinate2D, MKCoordinateSpan) -> Void)? = nil) {
        self.onSearchCompleted = onSearchCompleted
    }

    var body: some View {
        Group {
            if #available(iOS 26, *) {
                systemNavigationContent
                    .navigationTitle("검색")
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                customNavigationContent
                    .navigationBarHidden(true)
            }
        }
        .tint(.gray90) // 시스템 back button 색상을 앱 테마와 일치
    }

    // MARK: - iOS 26+ (시스템 네비게이션)

    @available(iOS 26, *)
    private var systemNavigationContent: some View {
        List {
            if intent.state.recentSearches.isEmpty {
                emptyStateView
            } else {
                Section(header: Text("최근 검색")) {
                    ForEach(intent.state.recentSearches) { item in
                        recentSearchRow(item)
                    }

                    Button("전체 삭제") {
                        intent.clearAllSearches()
                    }
                    .foregroundColor(.red)
                    .font(.pretendardBody2)
                }
            }
        }
        .searchable(
            text: Binding(
                get: { intent.state.searchQuery },
                set: { intent.updateQuery($0) }
            ),
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "지역명을 입력해주세요 (예: 강남구, 문래동)"
        )
        .onSubmit(of: .search) {
            Task { await handleSearch() }
        }
        .overlay {
            if intent.state.isSearching {
                ProgressView()
                    .scaleEffect(1.2)
            }
        }
        .alert("검색 오류", isPresented: Binding(
            get: { intent.state.errorMessage != nil },
            set: { if !$0 { intent.updateQuery("") } }
        )) {
            Button("확인", role: .cancel) {}
        } message: {
            if let error = intent.state.errorMessage {
                Text(error)
            }
        }
        .onAppear {
            intent.loadRecentSearches()
        }
    }

    // MARK: - iOS 26 이전 (CustomNavigationBar)

    private var customNavigationContent: some View {
        VStack(spacing: 0) {
            CustomNavigationBar(onBack: { dismiss() }, title: "검색")

            // SearchBar 컴포넌트 재사용
            SearchBar(
                text: Binding(
                    get: { intent.state.searchQuery },
                    set: { intent.updateQuery($0) }
                ),
                placeholder: "지역명을 입력해주세요",
                onSubmit: {
                    Task { await handleSearch() }
                }
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .focused($isSearchFocused)

            if intent.state.isSearching {
                ProgressView()
                    .padding()
            } else if let error = intent.state.errorMessage {
                errorView(error)
            } else if intent.state.recentSearches.isEmpty {
                emptyStateView
            } else {
                recentSearchList
            }

            Spacer()
        }
        .background(Color.gray15)
        .onAppear {
            intent.loadRecentSearches()
            isSearchFocused = true
        }
    }

    // MARK: - 최근 검색어 리스트

    private var recentSearchList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("최근 검색")
                        .font(.pretendardBody1Bold)
                        .foregroundColor(.gray90)

                    Spacer()

                    Button("전체 삭제") {
                        intent.clearAllSearches()
                    }
                    .font(.pretendardCaption1)
                    .foregroundColor(.gray60)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                ForEach(intent.state.recentSearches) { item in
                    recentSearchRow(item)
                }
            }
        }
    }

    private func recentSearchRow(_ item: RecentSearchItem) -> some View {
        Button {
            intent.updateQuery(item.query)
            Task { await handleSearch() }
        } label: {
            HStack(spacing: 12) {
                DSIconView(.search, size: 16, renderingMode: .template)
                    .foregroundColor(.gray60)

                Text(item.query)
                    .font(.pretendardBody2)
                    .foregroundColor(.gray90)

                Spacer()

                Button {
                    intent.deleteRecentSearch(id: item.id)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundColor(.gray60)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray0)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            DSIconView(.search, size: 48, renderingMode: .template)
                .foregroundColor(.gray45)

            Text("최근 검색어가 없습니다")
                .font(.pretendardBody2)
                .foregroundColor(.gray60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(.gray60)

            Text(message)
                .font(.pretendardBody2)
                .foregroundColor(.gray75)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Actions

    private func handleSearch() async {
        guard let result = await intent.performSearch() else { return }

        let (coordinate, span) = result

        if let onSearchCompleted {
            onSearchCompleted(coordinate, span)
            return
        }

        dismiss()

        // MapView로 네비게이션 (부모 View에서 처리)
        NotificationCenter.default.post(
            name: Notification.Name("SearchCompleted"),
            object: nil,
            userInfo: ["coordinate": coordinate, "span": span]
        )
    }
}

#Preview {
    NavigationStack {
        SearchView()
    }
}
