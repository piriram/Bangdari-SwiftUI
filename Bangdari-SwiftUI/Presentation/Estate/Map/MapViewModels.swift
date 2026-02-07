import MapKit

// MARK: - View State

enum MapViewState: Equatable {
    case idle
    case browsing
    case clusterFocused(MapCluster)
    case estateSelected(Int)
    case filterAdjusting(FilterType)

    enum FilterType: Equatable, CaseIterable {
        case deposit
        case monthlyRent
        case area

        var title: String {
            switch self {
            case .deposit: return "보증금"
            case .monthlyRent: return "월세"
            case .area: return "평수"
            }
        }

        var panelTitle: String {
            switch self {
            case .deposit: return "보증금 범위"
            case .monthlyRent: return "월세 범위"
            case .area: return "평수 범위"
            }
        }
    }

    static func == (lhs: MapViewState, rhs: MapViewState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.browsing, .browsing):
            return true
        case let (.clusterFocused(l), .clusterFocused(r)):
            return l.id == r.id
        case let (.estateSelected(l), .estateSelected(r)):
            return l == r
        case let (.filterAdjusting(l), .filterAdjusting(r)):
            return l == r
        default:
            return false
        }
    }
}

// MARK: - Filter State

struct MapFilterState {
    static let defaultDepositRange: ClosedRange<Double> = 0...100_000_000
    static let defaultMonthlyRentRange: ClosedRange<Double> = 0...3_000_000
    static let defaultAreaRange: ClosedRange<Double> = 0...100

    var depositRange: ClosedRange<Double> = Self.defaultDepositRange
    var monthlyRentRange: ClosedRange<Double> = Self.defaultMonthlyRentRange
    var areaRange: ClosedRange<Double> = Self.defaultAreaRange

    var isDepositActive: Bool = false
    var isMonthlyRentActive: Bool = false
    var isAreaActive: Bool = false

    var hasActiveFilters: Bool {
        isDepositActive || isMonthlyRentActive || isAreaActive
    }

    func isActive(_ type: MapViewState.FilterType) -> Bool {
        switch type {
        case .deposit: return isDepositActive
        case .monthlyRent: return isMonthlyRentActive
        case .area: return isAreaActive
        }
    }

    mutating func activate(_ type: MapViewState.FilterType) {
        switch type {
        case .deposit: isDepositActive = true
        case .monthlyRent: isMonthlyRentActive = true
        case .area: isAreaActive = true
        }
    }

    mutating func reset() {
        isDepositActive = false
        isMonthlyRentActive = false
        isAreaActive = false
        depositRange = Self.defaultDepositRange
        monthlyRentRange = Self.defaultMonthlyRentRange
        areaRange = Self.defaultAreaRange
    }

    func rangeText(_ type: MapViewState.FilterType) -> String {
        switch type {
        case .deposit:
            return "\(PriceFormatter.format(depositRange.lowerBound)) ~ \(PriceFormatter.format(depositRange.upperBound))"
        case .monthlyRent:
            return "\(PriceFormatter.format(monthlyRentRange.lowerBound)) ~ \(PriceFormatter.format(monthlyRentRange.upperBound))"
        case .area:
            return "\(Int(areaRange.lowerBound))평 ~ \(Int(areaRange.upperBound))평"
        }
    }

    static func bounds(_ type: MapViewState.FilterType) -> ClosedRange<Double> {
        switch type {
        case .deposit: return defaultDepositRange
        case .monthlyRent: return defaultMonthlyRentRange
        case .area: return defaultAreaRange
        }
    }
}

// MARK: - Navigation Data

struct MapNavigationData: Hashable {
    let category: EstateCategory?
    let initialCoordinate: CLLocationCoordinate2D?
    let coordinateSpan: MKCoordinateSpan?

    init(category: EstateCategory?, initialCoordinate: CLLocationCoordinate2D?, coordinateSpan: MKCoordinateSpan? = nil) {
        self.category = category
        self.initialCoordinate = initialCoordinate
        self.coordinateSpan = coordinateSpan
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(category?.rawValue)
        hasher.combine(initialCoordinate?.latitude)
        hasher.combine(initialCoordinate?.longitude)
        hasher.combine(coordinateSpan?.latitudeDelta)
    }

    static func == (lhs: MapNavigationData, rhs: MapNavigationData) -> Bool {
        lhs.category == rhs.category &&
        lhs.initialCoordinate?.latitude == rhs.initialCoordinate?.latitude &&
        lhs.initialCoordinate?.longitude == rhs.initialCoordinate?.longitude &&
        lhs.coordinateSpan?.latitudeDelta == rhs.coordinateSpan?.latitudeDelta
    }
}
