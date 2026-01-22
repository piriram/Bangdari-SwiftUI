import SwiftUI

// MARK: - Range Icons

enum RangeIcon: String {
    case start = "RangeStart"
    case end = "RangeEnd"
    case message = "RangeMessage"
}

extension Image {
    init(rangeIcon: RangeIcon) {
        self.init(rangeIcon.rawValue)
    }
}
