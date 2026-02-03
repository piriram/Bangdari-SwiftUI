import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn = KeychainManager.shared.isLoggedIn

    var body: some View {
        Group {
            if isLoggedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didLogin)) { _ in
            isLoggedIn = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .didLogout)) { _ in
            isLoggedIn = false
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab: MainTab = .home

    init() {
        configureTabBarAppearance()
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                MainView()
            }
            .tabItem {
                Image(selectedTab == .home ? "TabHomeFill" : "TabHomeEmpty")
                    .renderingMode(.template)
                Text("홈")
            }
            .tag(MainTab.home)

            NavigationStack {
                EstateListView(mode: .liked)
            }
            .tabItem {
                Image(selectedTab == .like ? "TabLikeFill" : "TabLikeEmpty")
                    .renderingMode(.template)
                Text("관심매물")
            }
            .tag(MainTab.like)

            NavigationStack {
                MyPageView()
            }
            .tabItem {
                Image(selectedTab == .my ? "TabMyFill" : "TabMyEmpty")
                    .renderingMode(.template)
                Text("설정")
            }
            .tag(MainTab.my)
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.gray0)

        // 비선택 아이템 색상 (gray45)
        let normalItemAppearance = UITabBarItemAppearance()
        normalItemAppearance.normal.iconColor = UIColor(Color.gray45)
        normalItemAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.gray45)
        ]

        // 선택 아이템 색상 (gray90)
        normalItemAppearance.selected.iconColor = UIColor(Color.gray90)
        normalItemAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.gray90)
        ]

        appearance.stackedLayoutAppearance = normalItemAppearance
        appearance.inlineLayoutAppearance = normalItemAppearance
        appearance.compactInlineLayoutAppearance = normalItemAppearance

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

private enum MainTab {
    case home
    case like
    case my
}

// MARK: - Notifications

extension Notification.Name {
    static let didLogin = Notification.Name("didLogin")
    static let didLogout = Notification.Name("didLogout")
}

#Preview {
    ContentView()
}
