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

    /// 캐시 초기화
    func clearCache() {
        cacheQueue.async {
            self.cache.removeAll()
        }
    }
}
