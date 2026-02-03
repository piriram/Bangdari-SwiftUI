import CoreLocation
import Kingfisher
import SwiftUI

// MARK: - Estate List View

struct EstateListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var intent = EstateListIntent()

    let mode: ListMode

    @State private var selectedEstateIdForDetail: String?
    @State private var activeFilter: FilterType?
    @State private var displayEstates: [EstateSummaryResponse] = []

    enum ListMode {
        case map(coordinate: CLLocationCoordinate2D, estates: [EstateSummaryResponse], locationText: String)
        case liked
        case todayEstates(estates: [EstateSummaryResponse])
        case hotEstates(estates: [EstateSummaryResponse])
    }

    enum FilterType {
        case area, deposit, monthlyRent, immediate
    }

    var body: some View {
        ZStack {
            // Z1: Background
            Color.gray15.ignoresSafeArea()

            VStack(spacing: 0) {
                // Z2: Navigation Bar (System UI)
                navigationBar

                // Filter Chip Row (only for map mode)
                if case .map = mode {
                    filterChipRow
                        .padding(.top, 12)
                }

                // Z3: Scrollable Content Flow
                if intent.state.isLoading && displayEstates.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if displayEstates.isEmpty {
                    emptyView
                } else {
                    estateListContent
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(item: $selectedEstateIdForDetail) { estateId in
            EstateDetailView(estateId: estateId)
        }
        .task {
            await loadInitialData()
        }
        .refreshable {
            await refresh()
        }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        CustomNavigationBar(onBack: { dismiss() }) {
            // Center: Location + Text
            HStack(spacing: 6) {
                Image(dsIcon: .location)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(.deepWood)

                Text(locationText)
                    .font(.pretendardBody1Bold)
                    .foregroundColor(.gray90)
            }
        } trailing: {
            // Trailing: Map Icon (liked mode only)
            if case .liked = mode {
                Button {
                    // TODO: Navigate to map
                } label: {
                    Image(dsIcon: .map)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.gray90)
                }
            }
        }
    }

    private var locationText: String {
        switch mode {
        case .map(_, _, let text):
            return text
        case .liked:
            return "좋아요한 매물"
        case .todayEstates:
            return "최근검색 매물"
        case .hotEstates:
            return "HOT 매물"
        }
    }

    // MARK: - Filter Chip Row

    private var filterChipRow: some View {
        HStack(spacing: 0) {
            // Chip Group
            HStack(spacing: 2) { // Chip-Chip Gap: 2px
                filterChip("면적 순", isActive: activeFilter == .area) {
                    toggleFilter(.area)
                }

                filterChip("보증금 순", isActive: activeFilter == .deposit) {
                    toggleFilter(.deposit)
                }

                filterChip("월세 순", isActive: activeFilter == .monthlyRent) {
                    toggleFilter(.monthlyRent)
                }

                filterChip("신축 순", isActive: activeFilter == .immediate) {
                    toggleFilter(.immediate)
                }
            }
            .padding(.leading, 20) // Left Inset

            Spacer()
                .frame(width: 33) // Chip Group → Sort Gap

            // Sort Icon (19×21px visible)
            Button {
                // TODO: Sort action
            } label: {
                Image(dsIcon: .sort)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 19, height: 21)
                    .foregroundColor(.gray75)
            }
            .padding(.trailing, 22) // Right Inset
        }
        .frame(height: 32)
    }

    private func filterChip(_ title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.pretendardCaption1)
                .foregroundColor(isActive ? .gray0 : .gray75)
                .padding(.horizontal, 12)
                .frame(height: 32) // Chip Height: 32px
                .background(isActive ? Color.deepWood : Color.gray0)
                .clipShape(Capsule()) // Radius: height/2 = 16px
        }
    }

    private func toggleFilter(_ filter: FilterType) {
        if activeFilter == filter {
            activeFilter = nil
        } else {
            activeFilter = filter
        }
        // TODO: MapView의 필터 상태와 공유 필요
        // TODO: 실제 필터 로직 구현 (면적순, 보증금순, 월세순, 신축순)
        updateDisplayEstates()
    }

    // MARK: - Estate List Content

    private var estateListContent: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                // First item gap: 40px from chip row bottom (map mode only)
                if case .map = mode {
                    Spacer()
                        .frame(height: 40)
                }

                ForEach(Array(displayEstates.enumerated()), id: \.element.estate_id) { index, estate in
                    Button {
                        selectedEstateIdForDetail = estate.estate_id
                    } label: {
                        EstateListItem(estate: estate)
                    }
                    .buttonStyle(.plain)

                    // Dynamic interval banners (map mode only)
                    // 한 페이지에 배너 2개 정도 보이도록 간격 조정
                    if case .map = mode, index < displayEstates.count - 1 {
                        // 4개마다 배너 표시 (index: 3, 7, 11, 15...)
                        if (index + 1) % 4 == 0 {
                            InlinePromoItem()
                        }
                    }
                }

                // Load more indicator (liked mode only)
                if case .liked = mode, intent.state.isLoadingMore {
                    ProgressView()
                        .padding()
                }
            }
            .padding(.horizontal, horizontalPadding)
        }
    }

    private var horizontalPadding: CGFloat {
        if case .liked = mode {
            return 16
        }
        return 0
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "house")
                .font(.system(size: 48))
                .foregroundColor(.gray60)

            Text(emptyMessage)
                .font(.pretendardBody2)
                .foregroundColor(.gray60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyMessage: String {
        switch mode {
        case .map:
            return "이 지역에 매물이 없습니다"
        case .liked:
            return "좋아요한 매물이 없습니다"
        case .todayEstates:
            return "최근검색 매물이 없습니다"
        case .hotEstates:
            return "HOT 매물이 없습니다"
        }
    }

    // MARK: - Helpers

    private func loadInitialData() async {
        switch mode {
        case .map(_, let estates, _):
            displayEstates = estates
        case .liked:
            await intent.loadMyLikedEstates()
            displayEstates = intent.state.estates
        case .todayEstates(let estates):
            displayEstates = estates
        case .hotEstates(let estates):
            displayEstates = estates
        }
    }

    private func refresh() async {
        switch mode {
        case .map(let coordinate, _, _):
            await intent.loadEstates(at: coordinate)
            displayEstates = intent.state.estates
        case .liked:
            await intent.loadMyLikedEstates()
            displayEstates = intent.state.estates
        case .todayEstates(let estates):
            displayEstates = estates
        case .hotEstates(let estates):
            displayEstates = estates
        }
    }

    private func updateDisplayEstates() {
        switch mode {
        case .map(_, let estates, _):
            displayEstates = estates // TODO: Apply filter
        case .liked:
            displayEstates = intent.state.estates
        case .todayEstates(let estates):
            displayEstates = estates
        case .hotEstates(let estates):
            displayEstates = estates
        }
    }
}

// MARK: - Estate List Item

struct EstateListItem: View {
    let estate: EstateSummaryResponse

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Thumbnail (140×124px)
            thumbnail
                .padding(.leading, 20) // Thumbnail Left Inset

            Spacer()
                .frame(width: 20) // Thumbnail → Text Gap

            // Text Stack
            textStack

            Spacer()
        }
        .frame(height: 124) // Match thumbnail height
        .background(Color.gray0)
    }

    private var thumbnail: some View {
        ZStack(alignment: .topLeading) {
            // Image
            KFImage.auth(url: imageURL)
                .placeholder {
                    Color.gray30
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 140, height: 124)
                .clipped()
                .cornerRadius(8) // Thumbnail radius (Figma spec)

            // Overlay Circle Button (18×18px)
            Circle()
                .fill(Color.deepCoast)
                .frame(width: 18, height: 18)
                .overlay {
                    Image(dsIcon: .focus)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 10, height: 10)
                        .foregroundColor(.gray0)
                }
                .offset(x: 9, y: 9) // Top/Left Inset: 9px
        }
    }

    private var textStack: some View {
        VStack(alignment: .leading, spacing: 3) {
            // 1. Tag Badge (36×17px)
            tagBadge

            // 2. Title
            Text(estate.title)
                .font(.pretendardBody1Bold)
                .foregroundColor(.gray90)
                .lineLimit(1)

            // 3. Price
            Text(priceText)
                .font(.pretendardBody2)
                .foregroundColor(.gray75)

            // 4. Meta (면적·층수)
            Text("\(Int(estate.area))㎡ · \(estate.floors)층")
                .font(.pretendardCaption2)
                .foregroundColor(.gray60)

            Spacer()

            // 5. Distance (if available)
            if let distance = estate.distance {
                Text(distanceText(distance))
                    .font(.pretendardCaption2)
                    .foregroundColor(.gray60)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.trailing, 20)
    }

    private var tagBadge: some View {
        Text(estate.category)
            .font(.pretendardCaption3)
            .foregroundColor(.gray75)
            .padding(.horizontal, 8)
            .frame(height: 17) // Tag Height: 17px
            .background(Color.gray15)
            .clipShape(Capsule()) // Radius: 8.5px (17/2)
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

// MARK: - Inline Promo Item

struct InlinePromoItem: View {
    var body: some View {
        HStack(spacing: 0) {
            // Left: Text Block
            VStack(alignment: .leading, spacing: 4) {
                Text("🎉 오늘의 특가 매물")
                    .font(.pretendardBody1Bold)
                    .foregroundColor(.gray90)

                Text("지금 바로 확인하세요")
                    .font(.pretendardCaption1)
                    .foregroundColor(.gray60)
            }
            .padding(.leading, 52)

            Spacer()

            // Right: Illustration (60×44px)
            Image(systemName: "star.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 44)
                .foregroundColor(.brightCream)
                .padding(.trailing, 56) // 390-334 = 56
        }
        .frame(height: 80)
        .background(Color.gray15)
        .cornerRadius(8)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

#Preview("Map Mode") {
    NavigationStack {
        EstateListView(
            mode: .map(
                coordinate: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
                estates: [],
                locationText: "서울시, 중구"
            )
        )
    }
}

#Preview("Liked Mode") {
    NavigationStack {
        EstateListView(mode: .liked)
    }
}
