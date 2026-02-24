import CoreLocation
import Foundation

extension EstateSummaryResponse {
    var mapCardPriceText: String {
        if monthly_rent > 0 {
            return "\(shortDepositText)/\(monthly_rent)"
        }

        return "전세 \(shortDepositText)"
    }

    var mapMarkerPriceText: String {
        let rentText = monthly_rent >= 100 ? "\(monthly_rent / 100)백" : "\(monthly_rent)"
        if monthly_rent > 0 {
            return "\(shortDepositText)/\(rentText)"
        }

        return shortDepositText
    }

    var mapImageURL: URL? {
        guard let firstFile = files.first else { return nil }
        return MockImageMapper.resolvedImageURL(from: firstFile)
    }

    private var shortDepositText: String {
        if deposit >= 10_000 {
            return "\(deposit / 10_000)억"
        }

        return "\(deposit)"
    }
}

extension EstateSummaryResponse: Identifiable {
    var id: String { estate_id }
}

extension Geolocation {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
