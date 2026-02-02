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

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                MainView()
            }
            .tabItem {
                VStack {
                    Image(selectedTab == .home ? "TabHomeFill" : "TabHomeEmpty")
                        .renderingMode(.original)
                    Text("홈")
                }
            }
            .tag(MainTab.home)

            NavigationStack {
                EstateMapView()
            }
            .tabItem {
                Label("지도", systemImage: "map")
            }
            .tag(MainTab.map)

            NavigationStack {
                EstateListView(mode: .liked)
            }
            .tabItem {
                VStack {
                    Image(selectedTab == .like ? "TabLikeFill" : "TabLikeEmpty")
                        .renderingMode(.original)
                    Text("좋아요")
                }
            }
            .tag(MainTab.like)

            NavigationStack {
                CommunityListView()
            }
            .tabItem {
                Label("커뮤니티", systemImage: "bubble.left.and.bubble.right")
            }
            .tag(MainTab.community)

            NavigationStack {
                MyPageView()
            }
            .tabItem {
                VStack {
                    Image(selectedTab == .my ? "TabMyFill" : "TabMyEmpty")
                        .renderingMode(.original)
                    Text("MY")
                }
            }
            .tag(MainTab.my)
        }
    }
}

private enum MainTab {
    case home
    case map
    case like
    case community
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
