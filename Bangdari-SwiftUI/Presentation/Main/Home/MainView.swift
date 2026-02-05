import CoreLocation
import SwiftUI

// MARK: - Main View

struct MainView: View {
    @StateObject private var intent = HomeIntent()
    @State private var selectedCategory: EstateCategory?
    @State private var navigationPath = NavigationPath()
    @State private var scrollOffset: CGFloat = 0

    private var blurProgress: CGFloat {
        let threshold: CGFloat = 100
        return min(max(-scrollOffset / threshold, 0), 1)
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    ScrollView {
                        VStack(spacing: 24) {
                            // 오프셋 측정용 anchor (invisible)
                            Color.clear
                                .frame(height: 0)
                                .measureScrollOffset { offset in
                                    withAnimation(.easeOut(duration: 0.25)) {
                                        scrollOffset = offset
                                    }
                                }

                            // 히어로 배너
                            if intent.state.heroBannerSkeleton {
                                HeroBannerSkeleton(height: DesignSystem.Layout.heroBannerHeight)
                            } else if !intent.state.todayEstates.isEmpty {
                                HeroBannerView(
                                    estates: intent.state.todayEstates,
                                    height: DesignSystem.Layout.heroBannerHeight,
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
                        .frame(maxWidth: geo.size.width)
                        .padding(.bottom, 24)
                    }
                    .coordinateSpace(name: "scroll")
                    .contentMargins(.top, -geo.safeAreaInsets.top, for: .scrollContent)
                    .scrollContentBackground(.hidden)
                    .ignoresSafeArea(edges: .top)
                    .background(Color.gray15)

                    HomeSearchBar(blurProgress: blurProgress) {
                        // TODO: 검색 화면 이동
                    }
                    .padding(.top, 3)
                    .padding(.horizontal, 20)
                }
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
            .navigationDestination(for: EstateListNavigationData.self) { navData in
                switch navData {
                case .todayEstates:
                    EstateListView(mode: .todayEstates(estates: intent.state.todayEstates))
                case .hotEstates:
                    EstateListView(mode: .hotEstates(estates: intent.state.hotEstates))
                }
            }
        }
        .task {
            await intent.loadHomeData()
        }
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
                navigationPath.append(EstateListNavigationData.todayEstates)
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
            }
            .contentMargins(.horizontal, 20, for: .scrollContent)
        }
    }

    // MARK: - Hot Estates Section

    private var hotEstatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "HOT 매물", actionTitle: "더보기") {
                navigationPath.append(EstateListNavigationData.hotEstates)
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
            }
            .contentMargins(.horizontal, 20, for: .scrollContent)
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
                            .padding(.horizontal, 20)
                        if index < intent.state.topicSkeletons.count - 1 {
                            Rectangle()
                                .fill(Color.gray30)
                                .frame(height: 1)
                                .padding(.horizontal, 20)
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
                                .padding(.horizontal, 20)
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
        .padding(.horizontal, 20)
        .frame(height: 76)
    }
}

#Preview {
    MainView()
}

// MARK: - Navigation Data

enum EstateListNavigationData: Hashable {
    case todayEstates
    case hotEstates
}

// MARK: - Home Search Bar

private struct HomeSearchBar: View {
    var blurProgress: CGFloat
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(dsIcon: .search)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.gray60)

                Text("검색어를 입력해주세요.")
                    .font(.pretendard(.body2))
                    .foregroundColor(.gray60)

                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(height: 40)
            .background(
                ZStack {
                    // Base: 원래 배경 (점점 투명해짐)
                    Color.gray0
                        .opacity(1.0 - blurProgress * 0.2)

                    // Blur: Material 레이어 (점점 진해짐)
                    Color.clear
                        .background(.ultraThinMaterial)
                        .opacity(blurProgress)
                }
            )
            .proportionalCornerRadius(
                baseWidth: 350,
                baseRadius: 20,
                strokeColor: Color.gray30.opacity(1.0 - blurProgress * 0.5),
                lineWidth: 1
            )
        }
        .buttonStyle(.plain)
        .frame(height: 40)
    }
}
