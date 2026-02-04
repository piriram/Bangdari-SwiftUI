import CoreLocation
import Kingfisher
import SwiftUI

// MARK: - Main View

struct MainView: View {
    @StateObject private var intent = HomeIntent()
    @State private var selectedCategory: EstateCategory?
    @State private var navigationPath = NavigationPath()
    @State private var showBannerWebView = false
    @State private var bannerWebURL: URL? = nil

    var body: some View {
        NavigationStack(path: $navigationPath) {
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    ScrollView {
                        VStack(spacing: 24) {
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

                            // 이벤트 배너
                            if !intent.state.banners.isEmpty {
                                bannerSection
                            }

                            // 카테고리 선택
                            CategorySelector(selectedCategory: $selectedCategory)

                            // 최근 검색 / 오늘의 매물
                            if !intent.state.todayEstateSkeletons.isEmpty || !filteredTodayEstates.isEmpty {
                                todayEstatesSection
                            }

                            // HOT 매물
                            if !intent.state.hotEstateSkeletons.isEmpty || !filteredHotEstates.isEmpty {
                                hotEstatesSection
                            }

                            // 카테고리별 매물 없음
                            if selectedCategory != nil
                                && intent.state.todayEstateSkeletons.isEmpty
                                && filteredTodayEstates.isEmpty
                                && filteredHotEstates.isEmpty {
                                Text("해당 카테고리 매물이 없습니다.")
                                    .font(.pretendard(.body2))
                                    .foregroundColor(.gray60)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 24)
                            }

                            // 오늘의 토픽
                            if !intent.state.topicSkeletons.isEmpty || !intent.state.topics.isEmpty {
                                topicSection
                            }
                        }
                        .frame(maxWidth: geo.size.width)
                        .padding(.bottom, 24)
                    }
                    .contentMargins(.top, -geo.safeAreaInsets.top, for: .scrollContent)
                    .scrollContentBackground(.hidden)
                    .ignoresSafeArea(edges: .top)
                    .background(Color.gray15)

                    HomeSearchBar {
                        navigationPath.append(SearchNavigationTag())
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
                    EstateListView(mode: .todayEstates(estates: filteredTodayEstates))
                case .hotEstates:
                    EstateListView(mode: .hotEstates(estates: filteredHotEstates))
                }
            }
            .navigationDestination(for: SearchNavigationTag.self) { _ in
                SearchView()
            }
        }
        .task {
            await intent.loadHomeData()
        }
        .sheet(isPresented: $showBannerWebView) {
            if let url = bannerWebURL {
                BannerWebViewScreen(url: url)
            }
        }
    }

    // MARK: - Filtered Estates

    private var filteredTodayEstates: [EstateSummaryResponse] {
        guard let category = selectedCategory else { return intent.state.todayEstates }
        return intent.state.todayEstates.filter { $0.category == category.rawValue }
    }

    private var filteredHotEstates: [EstateSummaryResponse] {
        guard let category = selectedCategory else { return intent.state.hotEstates }
        return intent.state.hotEstates.filter { $0.category == category.rawValue }
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
                        ForEach(filteredTodayEstates, id: \.estate_id) { estate in
                            NavigationLink(destination: EstateDetailView(estateId: estate.estate_id)) {
                                EstateCardSmall(
                                    estate: estate,
                                    isRecommended: filteredTodayEstates.first?.estate_id == estate.estate_id
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
                        ForEach(filteredHotEstates, id: \.estate_id) { estate in
                            NavigationLink(destination: EstateDetailView(estateId: estate.estate_id)) {
                                EstateCardLarge(
                                    estate: estate,
                                    viewerCount: estate.like_count
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

    // MARK: - Banner Section

    private var bannerSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(intent.state.banners, id: \.banner_id) { banner in
                    Button {
                        guard banner.payload?.type == "WEBVIEW",
                              let actionUrl = banner.actionUrl,
                              let url = URL(string: actionUrl) else { return }
                        bannerWebURL = url
                        showBannerWebView = true
                    } label: {
                        KFImage.auth(url: bannerImageURL(banner))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 300, height: 150)
                            .clipped()
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .contentMargins(.horizontal, 20, for: .scrollContent)
    }

    private func bannerImageURL(_ banner: Banner) -> URL? {
        if banner.image.hasPrefix("http") {
            return URL(string: banner.image)
        }
        return URL(string: APIConfig.baseURL + "/" + banner.image)
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
            .background(Color.gray0)
            .proportionalCornerRadius(
                baseWidth: 350,
                baseRadius: 20,
                strokeColor: .gray30,
                lineWidth: 1
            )
        }
        .buttonStyle(.plain)
        .frame(height: 40)
    }
}
