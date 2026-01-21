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
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("홈", systemImage: "house")
            }

            NavigationStack {
                EstateMapView()
            }
            .tabItem {
                Label("지도", systemImage: "map")
            }

            NavigationStack {
                EstateListView(mode: .liked)
            }
            .tabItem {
                Label("좋아요", systemImage: "heart")
            }

            NavigationStack {
                CommunityListView()
            }
            .tabItem {
                Label("커뮤니티", systemImage: "bubble.left.and.bubble.right")
            }

            NavigationStack {
                MyPageView()
            }
            .tabItem {
                Label("MY", systemImage: "person")
            }
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let didLogin = Notification.Name("didLogin")
    static let didLogout = Notification.Name("didLogout")
}

#Preview {
    ContentView()
}
