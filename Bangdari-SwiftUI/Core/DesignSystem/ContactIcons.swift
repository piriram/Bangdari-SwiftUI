import SwiftUI

// MARK: - Contact Icons

enum ContactIcon: String {
    case call = "ContactCall"
    case chat = "ContactChat"
}

extension Image {
    init(contactIcon: ContactIcon) {
        self.init(contactIcon.rawValue)
    }

    static func contactIcon(_ icon: ContactIcon) -> Image {
        Image(icon.rawValue)
            .renderingMode(.template)
    }
}
