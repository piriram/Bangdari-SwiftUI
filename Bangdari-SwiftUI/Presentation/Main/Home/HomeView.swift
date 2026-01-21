import Kingfisher
import SwiftUI

// MARK: - Home View

struct HomeView: View {
    @StateObject private var intent = HomeIntent()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 배너
                    if !intent.state.banners.isEmpty {
                        bannerSection
                    }

                    // 오늘의 매물
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
            .navigationTitle("방다리")
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

    // MARK: - Banner Section

    private var bannerSection: some View {
        TabView {
            ForEach(intent.state.banners, id: \.banner_id) { banner in
                KFImage.auth(url: URL(string: APIConfig.baseURL + "/" + banner.image))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .background(Color.gray.opacity(0.2))
            }
        }
        .frame(height: 200)
        .tabViewStyle(.page)
    }

    // MARK: - Today Estates Section

    private var todayEstatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "오늘의 매물")

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(intent.state.todayEstates, id: \.estate_id) { estate in
                        NavigationLink(destination: EstateDetailView(estateId: estate.estate_id)) {
                            EstateCard(estate: estate)
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
            sectionHeader(title: "HOT 매물 🔥")

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(intent.state.hotEstates, id: \.estate_id) { estate in
                        NavigationLink(destination: EstateDetailView(estateId: estate.estate_id)) {
                            EstateCard(estate: estate)
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
            sectionHeader(title: "오늘의 부동산 토픽")

            VStack(spacing: 8) {
                ForEach(intent.state.topics, id: \.title) { topic in
                    TopicRow(topic: topic)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Section Header

    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Estate Card

struct EstateCard: View {
    let estate: EstateSummaryResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 썸네일
            KFImage.auth(url: imageURL)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 150, height: 100)
                .background(Color.gray.opacity(0.2))
                .clipped()
                .cornerRadius(8)

            // 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(estate.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(priceText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 150)
    }

    private var imageURL: URL? {
        guard let first = estate.files.first else { return nil }
        return URL(string: APIConfig.baseURL + "/" + first)
    }

    private var priceText: String {
        if estate.monthly_rent > 0 {
            return "월세 \(estate.deposit)/\(estate.monthly_rent)"
        } else {
            return "전세 \(estate.deposit)"
        }
    }
}

// MARK: - Topic Row

struct TopicRow: View {
    let topic: EstateTopic

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(topic.title)
                .font(.subheadline)
                .fontWeight(.medium)

            Text(topic.content)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            Text(topic.date)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    HomeView()
}
