import CoreLocation
import SwiftUI

// MARK: - Main View

struct MainView: View {
    @StateObject private var intent = HomeIntent()
    @State private var selectedCategory: EstateCategory?
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .topLeading) {
                ScrollView {
                    VStack(spacing: 24) {
                        // 히어로 배너
                        if intent.state.heroBannerSkeleton {
                            HeroBannerSkeleton()
                        } else if !intent.state.todayEstates.isEmpty {
                            HeroBannerView(
                                estates: intent.state.todayEstates,
                                onTap: { estate in
                                    navigationPath.append(estate.estate_id)
                                }
                            )
                        }

                        // 카테고리 선택
                        CategorySelector(selectedCategory: $selectedCategory) { category in
                            handleCategorySelection(category)
                        }

                        // 최근 검색 / 오늘의 매물
                        if !intent.state.todayEstateSkeletons.isEmpty || !intent.state.todayEstates.isEmpty {
                            todayEstatesSection
                        }

                        // HOT 매물
                        if !intent.state.hotEstateSkeletons.isEmpty || !intent.state.hotEstates.isEmpty {
                            hotEstatesSection
                        }

                        // 오늘의 토픽
                        if !intent.state.topicSkeletons.isEmpty || !intent.state.topics.isEmpty {
                            topicSection
                        }
                    }
                    .padding(.bottom, 24)
                }
                .scrollContentBackground(.hidden)
                .ignoresSafeArea(edges: .top)
                .background(Color.gray15)

                HomeSearchBar {
                    // TODO: 검색 화면 이동
                }
                .padding(.top, topSafeAreaInset + 1)
                .padding(.leading, 25)
            }
            .refreshable {
                await intent.refresh()
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { estateId in
                EstateDetailView(estateId: estateId)
            }
            .navigationDestination(for: MapNavigationData.self) { navData in
                EstateMapView(
                    initialCategory: navData.category,
                    initialCoordinate: navData.initialCoordinate
                )
            }
        }
        .task {
            await intent.loadHomeData()
        }
    }

    private var topSafeAreaInset: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 0
    }

    // MARK: - Private Methods

    private func handleCategorySelection(_ category: EstateCategory) {
        print("🏠 [MainView] 카테고리 선택: \(category.rawValue)")

        // 1. 현재 위치 가져오기
        let coordinate = intent.getCurrentCoordinate()

        // 2. 위치가 없으면 서울역 기본값 사용
        let finalCoordinate = coordinate ?? CLLocationCoordinate2D(
            latitude: 37.5547125,
            longitude: 126.9707878
        )

        if coordinate == nil {
            print("🏠 [MainView] 위치 없음 → 서울역 기본값 사용")
        }

        // 3. 네비게이션 데이터 생성 및 이동
        let navData = MapNavigationData(
            category: category,
            initialCoordinate: finalCoordinate
        )
        navigationPath.append(navData)

        print("🏠 [MainView] 지도 뷰로 이동")
    }

    // MARK: - Today Estates Section

    private var todayEstatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "최근검색 매물", actionTitle: "더보기") {
                // TODO: 전체보기
            }

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    // 스켈레톤 표시
                    if !intent.state.todayEstateSkeletons.isEmpty {
                        ForEach(intent.state.todayEstateSkeletons) { skeleton in
                            EstateCardSmallSkeleton()
                        }
                    } else {
                        // 실제 데이터
                        ForEach(intent.state.todayEstates, id: \.estate_id) { estate in
                            NavigationLink(destination: EstateDetailView(estateId: estate.estate_id)) {
                                EstateCardSmall(
                                    estate: estate,
                                    isRecommended: intent.state.todayEstates.first?.estate_id == estate.estate_id
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.leading, 21)
                .padding(.trailing, 22)
            }
        }
    }

    // MARK: - Hot Estates Section

    private var hotEstatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "HOT 매물", actionTitle: "더보기") {
                // TODO: 전체보기
            }

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    if !intent.state.hotEstateSkeletons.isEmpty {
                        ForEach(intent.state.hotEstateSkeletons) { skeleton in
                            EstateCardLargeSkeleton()
                        }
                    } else {
                        ForEach(intent.state.hotEstates, id: \.estate_id) { estate in
                            NavigationLink(destination: EstateDetailView(estateId: estate.estate_id)) {
                                EstateCardLarge(
                                    estate: estate,
                                    viewerCount: Int.random(in: 10...50)  // TODO: 실제 데이터
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.leading, 20)
                .padding(.trailing, 22)
            }
        }
    }

    // MARK: - Topic Section

    private var topicSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "오늘의 부동산 토픽")

            VStack(spacing: 0) {
                if !intent.state.topicSkeletons.isEmpty {
                    ForEach(intent.state.topicSkeletons.indices, id: \.self) { index in
                        TopicRowSkeleton()
                            .padding(.horizontal, 21)
                        if index < intent.state.topicSkeletons.count - 1 {
                            Rectangle()
                                .fill(Color.gray30)
                                .frame(height: 1)
                                .padding(.leading, 21)
                                .padding(.trailing, 22)
                        }
                    }
                } else {
                    ForEach(Array(intent.state.topics.enumerated()), id: \.element.title) { index, topic in
                        let row = TopicRow(topic: topic)
                        if let link = topic.link, let url = URL(string: link) {
                            Link(destination: url) {
                                row
                            }
                            .buttonStyle(.plain)
                        } else {
                            row
                        }
                        if index < intent.state.topics.count - 1 {
                            Rectangle()
                                .fill(Color.gray30)
                                .frame(height: 1)
                                .padding(.leading, 21)
                                .padding(.trailing, 22)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Topic Row

struct TopicRow: View {
    let topic: EstateTopic

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(topic.title)
                    .font(.pretendardBody2Bold)
                    .foregroundColor(.gray90)

                Text(topic.content)
                    .font(.pretendardCaption1)
                    .foregroundColor(.gray75)
                    .lineLimit(2)
            }

            Spacer()

            Text(topic.date)
                .font(.pretendardCaption2)
                .foregroundColor(.gray60)
        }
        .padding(.leading, 21)
        .padding(.trailing, 22)
        .frame(height: 76)
    }
}

#Preview {
    MainView()
}

// MARK: - Home Search Bar

private struct HomeSearchBar: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(dsIcon: .search)
                    .renderingMode(.template)
                    .foregroundColor(.gray60)

                Text("검색어를 입력해주세요.")
                    .font(.pretendard(.body3))
                    .foregroundColor(.gray60)

                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(width: 340, height: 38)
            .background(Color.gray0)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.gray30, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
