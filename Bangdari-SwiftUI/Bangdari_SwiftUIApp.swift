//

import SwiftUI
import UIKit
import iamport_ios

@main
struct Bangdari_SwiftUIApp: App {
    init() {
        configureNavigationBarAppearance()

        for family in UIFont.familyNames.sorted() {
            let names = UIFont.fontNames(forFamilyName: family).sorted().joined(separator: ", ")
            print("[Font] \(family): \(names)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    print("🔗 URL Received: \(url)")
                    Iamport.shared.receivedURL(url)
                }
        }
    }

    // MARK: - Navigation Bar Configuration

    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = nil

        // Back 버튼 텍스트 숨기기
        appearance.backButtonAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.clear
        ]
        appearance.backButtonAppearance.highlighted.titleTextAttributes = [
            .foregroundColor: UIColor.clear
        ]

        // 타이틀 스타일
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(named: "gray90") ?? .label,
            .font: UIFont(name: "Pretendard-Semibold", size: 16) ?? .systemFont(ofSize: 16, weight: .semibold)
        ]

        // Global 적용
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}
