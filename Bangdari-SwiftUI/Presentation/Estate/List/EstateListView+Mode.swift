import CoreLocation

extension EstateListView {
    enum ListMode {
        case map(coordinate: CLLocationCoordinate2D, estates: [EstateSummaryResponse], locationText: String)
        case liked
        case todayEstates(estates: [EstateSummaryResponse])
        case hotEstates(estates: [EstateSummaryResponse])
    }

    enum FilterType: CaseIterable {
        case area
        case deposit
        case monthlyRent
        case immediate
    }
}

extension EstateListView.ListMode {
    var navigationTitle: String {
        switch self {
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

    var emptyMessage: String {
        switch self {
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

    var coordinate: CLLocationCoordinate2D? {
        if case .map(let coordinate, _, _) = self {
            return coordinate
        }

        return nil
    }

    var baseEstates: [EstateSummaryResponse]? {
        switch self {
        case .map(_, let estates, _), .todayEstates(let estates), .hotEstates(let estates):
            return estates
        case .liked:
            return nil
        }
    }
}

extension EstateListView.FilterType {
    var title: String {
        switch self {
        case .area:
            return "면적 순"
        case .deposit:
            return "보증금 순"
        case .monthlyRent:
            return "월세 순"
        case .immediate:
            return "신축 순"
        }
    }
}

extension CLLocationCoordinate2D {
    static let seoulCenter = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
}
