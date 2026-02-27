import CoreLocation
import Foundation

// MARK: - Geolocation Manager

/// 역지오코딩(좌표 → 주소 변환)을 관리하고 결과를 캐싱하는 싱글톤 매니저
final class GeolocationManager {
    static let shared = GeolocationManager()

    private let geocoder = CLGeocoder()
    private var cache: [String: String] = [:]
    private let cacheQueue = DispatchQueue(label: "com.bangdari.geolocation.cache")

    private init() {}

    /// 좌표를 지역명(동 이름)으로 변환
    /// - Parameters:
    ///   - latitude: 위도
    ///   - longitude: 경도
    ///   - completion: 지역명 또는 nil 반환
    func fetchLocationName(
        latitude: Double,
        longitude: Double,
        completion: @escaping (String?) -> Void
    ) {
        let cacheKey = "\(latitude),\(longitude)"

        // 캐시 확인
        cacheQueue.sync {
            if let cachedName = cache[cacheKey] {
                DispatchQueue.main.async {
                    completion(cachedName)
                }
                return
            }
        }

        // 역지오코딩 수행
        let location = CLLocation(latitude: latitude, longitude: longitude)

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self,
                  error == nil,
                  let placemark = placemarks?.first
            else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            // "동" 이름 추출 (예: "문래동")
            let locationName = placemark.subLocality ?? placemark.locality

            // 캐시 저장
            if let name = locationName {
                self.cacheQueue.async {
                    self.cache[cacheKey] = name
                }
            }

            DispatchQueue.main.async {
                completion(locationName)
            }
        }
    }

    /// 좌표를 전체 주소로 변환
    /// - Parameters:
    ///   - latitude: 위도
    ///   - longitude: 경도
    ///   - completion: 전체 주소 또는 nil 반환 (예: "서울 영등포구 선유로9길 30")
    func fetchFullAddress(
        latitude: Double,
        longitude: Double,
        completion: @escaping (String?) -> Void
    ) {
        let cacheKey = "full_\(latitude),\(longitude)"

        // 캐시 확인
        cacheQueue.sync {
            if let cachedAddress = cache[cacheKey] {
                DispatchQueue.main.async {
                    completion(cachedAddress)
                }
                return
            }
        }

        // 역지오코딩 수행
        let location = CLLocation(latitude: latitude, longitude: longitude)

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self,
                  error == nil,
                  let placemark = placemarks?.first
            else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            // 전체 주소 조합: "시 구 동 도로명"
            var components: [String] = []

            if let city = placemark.administrativeArea {
                components.append(city)  // 서울특별시
            }

            if let district = placemark.locality {
                components.append(district)  // 영등포구
            }

            if let street = placemark.thoroughfare {
                components.append(street)  // 선유로9길
            }

            if let number = placemark.subThoroughfare {
                components.append(number)  // 30
            }

            let fullAddress = components.isEmpty ? nil : components.joined(separator: " ")

            // 캐시 저장
            if let address = fullAddress {
                self.cacheQueue.async {
                    self.cache[cacheKey] = address
                }
            }

            DispatchQueue.main.async {
                completion(fullAddress)
            }
        }
    }

    /// 캐시 초기화
    func clearCache() {
        cacheQueue.async {
            self.cache.removeAll()
        }
    }
}
