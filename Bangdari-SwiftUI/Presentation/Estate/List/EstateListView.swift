import CoreLocation
import SwiftUI

// MARK: - Estate List View

struct EstateListView: View {
    @StateObject private var intent = EstateListIntent()
    let mode: ListMode

    enum ListMode {
        case location(CLLocationCoordinate2D)
        case liked
    }

    var body: some View {
        Group {
            if intent.state.isLoading && intent.state.estates.isEmpty {
                ProgressView()
            } else if intent.state.estates.isEmpty {
                emptyView
            } else {
                estateList
            }
        }
        .navigationTitle(navigationTitle)
        .refreshable {
            await refresh()
        }
        .task {
            await loadInitialData()
        }
    }

    // MARK: - Estate List

    private var estateList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(intent.state.estates, id: \.estate_id) { estate in
                    NavigationLink(destination: EstateDetailView(estateId: estate.estate_id)) {
                        EstateRowView(estate: estate)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        // 무한 스크롤: 마지막 아이템 근처에서 추가 로딩
                        if case .liked = mode,
                           estate.estate_id == intent.state.estates.last?.estate_id {
                            Task {
                                await intent.loadMoreLikedEstates()
                            }
                        }
                    }
                }

                // 추가 로딩 인디케이터
                if intent.state.isLoadingMore {
                    ProgressView()
                        .padding()
                }
            }
            .padding(16)
        }
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "house")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text(emptyMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Helpers

    private var navigationTitle: String {
        switch mode {
        case .location: return "주변 매물"
        case .liked: return "좋아요 매물"
        }
    }

    private var emptyMessage: String {
        switch mode {
        case .location: return "주변에 매물이 없습니다."
        case .liked: return "좋아요한 매물이 없습니다."
        }
    }

    private func loadInitialData() async {
        switch mode {
        case .location(let coordinate):
            await intent.loadEstates(at: coordinate)
        case .liked:
            await intent.loadMyLikedEstates()
        }
    }

    private func refresh() async {
        switch mode {
        case .location(let coordinate):
            await intent.loadEstates(at: coordinate)
        case .liked:
            await intent.loadMyLikedEstates()
        }
    }
}

// MARK: - Estate Row View

struct EstateRowView: View {
    let estate: EstateSummaryResponse

    var body: some View {
        HStack(spacing: 12) {
            // 썸네일
            AsyncImage(url: imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
            }
            .frame(width: 100, height: 80)
            .clipped()
            .cornerRadius(8)

            // 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(estate.category)
                    .font(.caption)
                    .foregroundColor(.brown)

                Text(estate.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)

                Text(priceText)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let distance = estate.distance {
                    Text(distanceText(distance))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var imageURL: URL? {
        guard let first = estate.files.first else { return nil }
        return URL(string: Secrets.baseURL + "/" + first)
    }

    private var priceText: String {
        if estate.monthly_rent > 0 {
            return "월세 \(formatPrice(estate.deposit))/\(formatPrice(estate.monthly_rent))"
        } else {
            return "전세 \(formatPrice(estate.deposit))"
        }
    }

    private func formatPrice(_ price: Int) -> String {
        if price >= 10000 {
            let billion = price / 10000
            let remainder = price % 10000
            if remainder == 0 {
                return "\(billion)억"
            } else {
                return "\(billion)억 \(remainder)"
            }
        }
        return "\(price)"
    }

    private func distanceText(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1fkm", meters / 1000)
        } else {
            return "\(Int(meters))m"
        }
    }
}

#Preview {
    NavigationStack {
        EstateListView(mode: .liked)
    }
}
