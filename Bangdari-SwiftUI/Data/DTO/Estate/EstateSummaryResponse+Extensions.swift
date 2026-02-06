import Foundation

// MARK: - Estate Summary Response Extensions

extension EstateSummaryResponse {
    /// 가격을 만원 단위로 포맷팅
    /// - Returns: "월세 7000/120" 또는 "전세 7000" 형식
    func formattedPrice() -> String {
        if monthly_rent > 0 {
            // 월세: "월세 7000/120" 형식 (만원 단위)
            let depositInManwon = deposit / 10000
            let rentInManwon = monthly_rent / 10000
            return "월세 \(depositInManwon)/\(rentInManwon)"
        } else {
            // 전세: "전세 7000" 형식 (만원 단위)
            let depositInManwon = deposit / 10000
            return "전세 \(depositInManwon)"
        }
    }

    /// 면적을 포맷팅
    /// - Parameter locationName: 지역명 (선택사항)
    /// - Returns: "문래동 152.4m²" 또는 "152.4m²" 형식
    func formattedArea(locationName: String? = nil) -> String {
        let formattedArea = String(format: "%.1f", area)

        if let location = locationName, !location.isEmpty {
            return "\(location) \(formattedArea)m²"
        } else {
            return "\(formattedArea)m²"
        }
    }
}
