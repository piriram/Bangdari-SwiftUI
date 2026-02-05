//
//  PriceFormatter.swift
//  Bangdari-SwiftUI
//
//  Created on 2026-02-06.
//

import Foundation

/// 가격 포맷팅 유틸리티
enum PriceFormatter {
    /// 원화 포맷 (만/억 단위, 천 단위 구분자)
    /// - Parameters:
    ///   - value: 포맷팅할 가격 (Double)
    ///   - includeUnit: "원" 단위 포함 여부 (기본값: true)
    /// - Returns: 포맷팅된 문자열
    /// - Examples:
    ///   - 95_432 → "9만원"
    ///   - 100_000_000 → "1억원"
    ///   - 150_000_000 → "1억 5천만원"
    ///   - 5_432 → "5,432원"
    static func format(_ value: Double, includeUnit: Bool = true) -> String {
        let intValue = Int(value)
        let unit = includeUnit ? "원" : ""

        // 억 단위 (100,000,000원 이상)
        if intValue >= 100_000_000 {
            let eok = intValue / 100_000_000
            let remainder = intValue % 100_000_000

            if remainder >= 10_000_000 {
                let cheonman = remainder / 10_000_000
                return "\(eok)억 \(cheonman)천만\(unit)"
            } else if remainder > 0 {
                return "\(eok)억\(unit)"
            } else {
                return "\(eok)억\(unit)"
            }
        }

        // 천만 단위 (10,000,000 ~ 99,999,999)
        if intValue >= 10_000_000 {
            let cheonman = intValue / 10_000_000
            return "\(cheonman)천만\(unit)"
        }

        // 백만 단위 (1,000,000 ~ 9,999,999)
        if intValue >= 1_000_000 {
            let baekman = intValue / 1_000_000
            return "\(baekman)백만\(unit)"
        }

        // 만 단위 (10,000 ~ 999,999) ← 핵심 개선!
        if intValue >= 10_000 {
            let man = intValue / 10_000
            let remainder = intValue % 10_000

            if remainder >= 1_000 {
                let cheon = remainder / 1_000
                return "\(man)만 \(cheon)천\(unit)"
            } else {
                return "\(man)만\(unit)"
            }
        }

        // 만원 미만 (천 단위 구분자)
        if intValue >= 1_000 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            let formatted = formatter.string(from: NSNumber(value: intValue)) ?? "\(intValue)"
            return formatted + unit
        }

        return "\(intValue)\(unit)"
    }
}
