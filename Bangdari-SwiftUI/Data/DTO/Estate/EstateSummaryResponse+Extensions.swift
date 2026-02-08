import Foundation

// MARK: - Estate Formattable Protocol

/// 부동산 가격 및 면적 포맷팅을 위한 프로토콜
protocol EstateFormattable {
    var deposit: Int { get }
    var monthly_rent: Int { get }
    var area: Double { get }
}

extension EstateFormattable {
    /// 가격을 만원 단위로 포맷팅
    /// - Returns: "월세 7000/120" 또는 "전세 7000" 형식
    func formattedPrice() -> String {
        if monthly_rent > 0 {
            // 월세: "월세 7000/120" 형식 (만원 단위)
            let depositInManwon = deposit / 10000
            let rentInManwon = monthly_rent / 10000
            return "월세 \(depositInManwon)/\(rentInManwon)만원"
        } else {
            // 전세: "전세 7000" 형식 (만원 단위)
            let depositInManwon = deposit / 10000
            return "전세 \(depositInManwon)만원"
        }
    }

    /// 가격을 억 단위로 포맷팅 (상세 표시용)
    /// - Parameter price: 포맷팅할 가격 (원 단위)
    /// - Returns: "7억", "7억 5000", "7000" 형식
    func formattedPriceInBillion(_ price: Int) -> String {
        let manwon = price / 10000  // 원 → 만원 변환

        if manwon >= 10000 {  // 1억 = 10000만원
            let billion = manwon / 10000
            let remainder = manwon % 10000
            return remainder == 0 ? "\(billion)억" : "\(billion)억 \(remainder)"
        }
        return "\(manwon)"
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

// MARK: - Estate Summary Response Extensions

extension EstateSummaryResponse: EstateFormattable {}

// MARK: - Estate Detail Response Extensions

extension EstateDetailResponse: EstateFormattable {}
