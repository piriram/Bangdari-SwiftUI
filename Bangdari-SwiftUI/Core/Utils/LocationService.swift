import CoreLocation
import Foundation

// MARK: - Location Service

final class LocationService {
    static let shared = LocationService()

    private init() {}

    /// 좌표를 주소 문자열로 변환 (역지오코딩)
    /// - Parameters:
    ///   - latitude: 위도
    ///   - longitude: 경도
    ///   - format: 주소 형식
    /// - Returns: 변환된 주소 문자열
    func reverseGeocode(
        latitude: Double,
        longitude: Double,
        format: AddressFormat = .short
    ) async -> String? {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: latitude, longitude: longitude)

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else { return nil }

            return formatAddress(from: placemark, format: format)
        } catch {
            print("❌ Reverse geocoding failed: \(error)")
            return nil
        }
    }

    /// Placemark를 지정된 형식의 주소로 변환
    private func formatAddress(from placemark: CLPlacemark, format: AddressFormat) -> String {
        switch format {
        case .short:
            // "서울 반포동"
            let city = placemark.administrativeArea ?? ""      // 시/도 (서울)
            let district = placemark.subLocality ?? ""         // 동 (반포동)

            if !city.isEmpty && !district.isEmpty {
                return "\(city) \(district)"
            } else if !district.isEmpty {
                return district
            } else if !city.isEmpty {
                return city
            }
            return "위치 정보 없음"

        case .medium:
            // "반포동, 서초구"
            let district = placemark.subLocality ?? ""         // 동
            let locality = placemark.locality ?? ""            // 구

            if !district.isEmpty && !locality.isEmpty {
                return "\(district), \(locality)"
            } else if !locality.isEmpty {
                return locality
            } else if !district.isEmpty {
                return district
            }
            return "위치 정보 없음"

        case .full:
            // "서울특별시 서초구 반포동"
            let city = placemark.administrativeArea ?? ""      // 서울특별시
            let locality = placemark.locality ?? ""            // 서초구
            let district = placemark.subLocality ?? ""         // 반포동

            var components: [String] = []
            if !city.isEmpty { components.append(city) }
            if !locality.isEmpty { components.append(locality) }
            if !district.isEmpty { components.append(district) }

            return components.isEmpty ? "위치 정보 없음" : components.joined(separator: " ")
        }
    }
}

// MARK: - Address Format

extension LocationService {
    enum AddressFormat {
        case short   // "서울 반포동"
        case medium  // "반포동, 서초구"
        case full    // "서울특별시 서초구 반포동"
    }
}
