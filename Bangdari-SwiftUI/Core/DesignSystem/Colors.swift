import SwiftUI

// MARK: - Design System Colors

extension Color {
    // MARK: - Brand Colors

    static let deepCream = Color(hex: "DAC8B1")
    static let brightCream = Color(hex: "F1DCC1")
    static let deepCoast = Color(hex: "298E9C")
    static let brightCoast = Color(hex: "71C9D6")
    static let deepWood = Color(hex: "402A32")
    static let brightWood = Color(hex: "8C5543")

    // MARK: - GrayScale

    static let gray0 = Color(hex: "FFFFFF")
    static let gray15 = Color(hex: "F5F5F5")
    static let gray30 = Color(hex: "E8E8E8")
    static let gray45 = Color(hex: "D1D1D1")
    static let gray60 = Color(hex: "9E9E9E")
    static let gray75 = Color(hex: "757575")
    static let gray90 = Color(hex: "424242")
    static let gray100 = Color(hex: "000000")
}

// MARK: - Hex Initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
