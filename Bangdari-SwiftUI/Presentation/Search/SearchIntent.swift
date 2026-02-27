import Foundation
import Combine
import CoreLocation
import MapKit

@MainActor
final class SearchIntent: ObservableObject {
    @Published private(set) var state = SearchState()

    private let recentSearchManager = RecentSearchManager.shared

    func loadRecentSearches() {
        state.recentSearches = recentSearchManager.getRecentSearches()
    }

    func updateQuery(_ query: String) {
        state.searchQuery = query
        state.errorMessage = nil
    }

    func performSearch() async -> (CLLocationCoordinate2D, MKCoordinateSpan)? {
        let trimmed = state.searchQuery.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            state.errorMessage = "검색어를 입력해주세요"
            return nil
        }

        state.isSearching = true
        state.errorMessage = nil

        let geocoder = CLGeocoder()
        let seoulRegion = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
            radius: 30_000,
            identifier: "seoul"
        )

        do {
            let placemarks = try await geocoder.geocodeAddressString(trimmed, in: seoulRegion)

            guard let placemark = placemarks.first, let location = placemark.location else {
                state.isSearching = false
                state.errorMessage = "검색 결과가 없습니다. 다른 지역명을 입력해주세요."
                return nil
            }

            let coordinate = location.coordinate
            let latDelta: Double = placemark.subLocality != nil ? 0.015 : 0.04
            let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: latDelta)

            state.isSearching = false

            // 검색 성공 시 최근 검색어에 추가
            recentSearchManager.addSearch(trimmed)
            loadRecentSearches()

            return (coordinate, span)
        } catch {
            state.isSearching = false
            state.errorMessage = "검색 중 오류가 발생했습니다"
            return nil
        }
    }

    func deleteRecentSearch(id: UUID) {
        recentSearchManager.removeSearch(id)
        loadRecentSearches()
    }

    func clearAllSearches() {
        recentSearchManager.clearAll()
        loadRecentSearches()
    }
}
