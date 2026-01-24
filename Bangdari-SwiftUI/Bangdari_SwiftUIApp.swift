//

import SwiftUI
import UIKit

@main
struct Bangdari_SwiftUIApp: App {
    init() {
        for family in UIFont.familyNames.sorted() {
            let names = UIFont.fontNames(forFamilyName: family).sorted().joined(separator: ", ")
            print("[Font] \(family): \(names)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
