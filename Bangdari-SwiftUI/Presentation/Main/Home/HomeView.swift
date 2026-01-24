import Kingfisher
import SwiftUI

// MARK: - Home View

struct HomeView: View {
    @StateObject private var intent = HomeIntent()
    @State private var selectedCategory: EstateCategory?
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 검색바
                    SearchBarButton(placeholder: "지역, 단지명으로 검색") {
                        // TODO: 검색 화면 이동
                    }
                    .padding(.horizontal, 16)

                    // 히어로 배너
                    if !intent.state.banners.isEmpty {
                        HeroBannerView(banners: intent.state.banners) { banner in
                            if let link = banner.link, let url = URL(string: link) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }

                    // 카테고리 선택
                    CategorySelector(selectedCategory: $selectedCategory) { category in
                        // TODO: 카테고리 필터링
                    }

                    // 최근 검색 / 오늘의 매물
                    if !intent.state.todayEstates.isEmpty {
                        todayEstatesSection
                    }

                    // HOT 매물
                    if !intent.state.hotEstates.isEmpty {
                        hotEstatesSection
                    }

                    // 오늘의 토픽
                    if !intent.state.topics.isEmpty {
                        topicSection
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color.gray0)
            .refreshable {
                await intent.refresh()
            }
            .overlay {
                if intent.state.isLoading && intent.state.todayEstates.isEmpty {
                    ProgressView()
                }
            }
        }
        .task {
            await intent.loadHomeData()
        }
    }

    // MARK: - Today Estates Section

    private var todayEstatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "최근검색 매물", actionTitle: "View All") {
                // TODO: 전체보기
            }

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
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
                .padding(.horizontal, 16)
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
                LazyHStack(spacing: 16) {
                    ForEach(intent.state.hotEstates, id: \.estate_id) { estate in
                        NavigationLink(destination: EstateDetailView(estateId: estate.estate_id)) {
                            EstateCardLarge(
                                estate: estate,
                                viewerCount: Int.random(in: 10...50)  // TODO: 실제 데이터
                            )
                            .frame(width: UIScreen.main.bounds.width * 0.85)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Topic Section

    private var topicSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "오늘의 부동산 토픽")

            VStack(spacing: 8) {
                ForEach(intent.state.topics, id: \.title) { topic in
                    if let url = URL(string: topic.link) {
                        Link(destination: url) {
                            TopicRow(topic: topic)
                        }
                        .buttonStyle(.plain)
                    } else {
                        TopicRow(topic: topic)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Topic Row

struct TopicRow: View {
    let topic: EstateTopic

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(topic.title)
                .font(.pretendardBody2Bold)
                .foregroundColor(.gray90)

            Text(topic.content)
                .font(.pretendardCaption1)
                .foregroundColor(.gray75)
                .lineLimit(2)

            Text(topic.date)
                .font(.pretendardCaption2)
                .foregroundColor(.gray60)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray15)
        .cornerRadius(8)
    }
}

#Preview {
    HomeView()
}
