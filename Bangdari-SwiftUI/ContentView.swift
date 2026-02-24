import SwiftUI

struct ContentView: View {
    private enum AuthState {
        case loading    // accessToken 있고, refresh 검증 중
        case loggedIn
        case loggedOut
    }

    @State private var authState: AuthState = KeychainManager.shared.isLoggedIn ? .loading : .loggedOut
    @Environment(\.scenePhase) private var scenePhase
    @State private var isPaymentFlowActive = false
    @State private var pendingLogoutAfterPayment = false
    @State private var pendingLogoutReason: String?

    var body: some View {
        Group {
            switch authState {
            case .loading:
                Color(.systemBackground)
            case .loggedIn:
                MainTabView()
            case .loggedOut:
                LoginView()
            }
        }
        .onAppear {
            if authState == .loading {
                checkToken()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && authState == .loggedIn && !isPaymentFlowActive {
                refreshTokenSilently()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didLogin)) { _ in
            authState = .loggedIn
        }
        .onReceive(NotificationCenter.default.publisher(for: .didLogout)) { notification in
            let reason = notification.object as? String ?? "원인 정보 없음"
            if isPaymentFlowActive {
                pendingLogoutAfterPayment = true
                pendingLogoutReason = reason
                print("🔒 [AUTH] 결제 진행 중 로그아웃 예약: \(reason)")
            } else {
                transitionToLoggedOut(reason: reason)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .paymentFlowDidStart)) { _ in
            isPaymentFlowActive = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .paymentFlowDidEnd)) { _ in
            isPaymentFlowActive = false
            if pendingLogoutAfterPayment {
                let deferredReason = pendingLogoutReason ?? "결제 플로우 종료 후 로그아웃 처리"
                transitionToLoggedOut(reason: "\(deferredReason) (결제 플로우 종료 후 적용)")
                pendingLogoutAfterPayment = false
                pendingLogoutReason = nil
            }
        }
    }

    /// 앱 시작 시 토큰 검증 (loading 상태에서 호출)
    private func checkToken() {
        Task {
            do {
                try await NetworkService.shared.validateAndRefreshToken()
                authState = .loggedIn
            } catch NetworkError.refreshTokenExpired {
                transitionToLoggedOut(reason: "앱 시작 토큰 검증 실패: refreshTokenExpired")
            } catch {
                // 네트워크 단절 등 기타 에러 → 기존 토큰으로 진행 (API 시점에서 갱신 재시도)
                authState = .loggedIn
            }
        }
    }

    /// foreground 복귀 시 백그라운드 silent refresh
    private func refreshTokenSilently() {
        Task {
            do {
                try await NetworkService.shared.validateAndRefreshToken()
            } catch NetworkError.refreshTokenExpired {
                transitionToLoggedOut(reason: "포그라운드 복귀 토큰 검증 실패: refreshTokenExpired")
            } catch {
                // 기타 에러는 무시 (다음 API 호출 시 자동 갱신 로직이 처리)
            }
        }
    }

    private func transitionToLoggedOut(reason: String) {
        print("🔒 [AUTH] 로그인 화면 전환 원인: \(reason)")
        authState = .loggedOut
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab: MainTab = .home
    private static var didConfigureTabBarAppearance = false

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
                CommunityListView()
            }
            .tabItem {
                Image(systemName: selectedTab == .community ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right")
                    .renderingMode(.template)
                Text("커뮤니티")
            }
            .tag(MainTab.community)

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
        .modifier(TabBarHeightModifier(extraHeight: 8))
        .onAppear {
            MainTabView.configureTabBarAppearanceIfNeeded()
        }
        .onChange(of: selectedTab) { _, _ in
            VideoPlayerManager.shared.pause()
        }
    }

    private static func configureTabBarAppearanceIfNeeded() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                configureTabBarAppearanceIfNeeded()
            }
            return
        }

        guard !didConfigureTabBarAppearance else { return }
        didConfigureTabBarAppearance = true

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.gray0)

        // 비선택 아이템 색상 (gray45)
        let normalItemAppearance = UITabBarItemAppearance()
        normalItemAppearance.normal.iconColor = UIColor(Color.gray45)
        normalItemAppearance.normal.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 5)
        normalItemAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.gray45)
        ]

        // 선택 아이템 색상 (gray90)
        normalItemAppearance.selected.iconColor = UIColor(Color.gray90)
        normalItemAppearance.selected.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 5)
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

// MARK: - Tab Bar Height

private struct TabBarHeightModifier: ViewModifier {
    let extraHeight: CGFloat

    func body(content: Content) -> some View {
        content.background(TabBarHeightAdjuster(extraHeight: extraHeight))
    }
}

private struct TabBarHeightAdjuster: UIViewControllerRepresentable {
    let extraHeight: CGFloat

    func makeUIViewController(context: Context) -> TabBarHeightViewController {
        TabBarHeightViewController(extraHeight: extraHeight)
    }

    func updateUIViewController(_ uiViewController: TabBarHeightViewController, context: Context) {
        uiViewController.extraHeight = extraHeight
        uiViewController.applyHeightAdjustment()
    }

    final class TabBarHeightViewController: UIViewController {
        var extraHeight: CGFloat

        init(extraHeight: CGFloat) {
            self.extraHeight = extraHeight
            super.init(nibName: nil, bundle: nil)
            view.backgroundColor = .clear
            view.isUserInteractionEnabled = false
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            applyHeightAdjustment()
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            applyHeightAdjustment()
        }

        func applyHeightAdjustment() {
            guard Thread.isMainThread else {
                DispatchQueue.main.async { [weak self] in
                    self?.applyHeightAdjustment()
                }
                return
            }

            guard let tabBar = tabBarController?.tabBar,
                  let tabBarSuperview = tabBar.superview else { return }

            applyItemSpacing(on: tabBar)

            let defaultHeight = tabBar.sizeThatFits(CGSize(width: tabBar.frame.width, height: 0)).height
            let targetHeight = defaultHeight + extraHeight

            guard abs(tabBar.frame.height - targetHeight) > 0.5 else { return }

            var frame = tabBar.frame
            frame.size.height = targetHeight
            frame.origin.y = tabBarSuperview.bounds.height - targetHeight
            tabBar.frame = frame

            tabBar.setNeedsLayout()
            tabBar.layoutIfNeeded()
            applyItemSpacing(on: tabBar)

            DispatchQueue.main.async { [weak tabBar] in
                guard let tabBar else { return }
                self.applyItemSpacing(on: tabBar)
            }
        }

        private func applyItemSpacing(on tabBar: UITabBar) {
            let verticalOffset: CGFloat = 8

            tabBar.subviews
                .filter { NSStringFromClass(type(of: $0)).contains("UITabBarButton") }
                .forEach { button in
                    var frame = button.frame
                    guard abs(frame.origin.y - verticalOffset) > 0.5 else { return }
                    frame.origin.y = verticalOffset
                    button.frame = frame
                }
        }
    }
}

private enum MainTab {
    case home
    case community
    case like
    case my
}

// MARK: - Notifications

extension Notification.Name {
    static let didLogin = Notification.Name("didLogin")
    static let didLogout = Notification.Name("didLogout")
    static let paymentFlowDidStart = Notification.Name("paymentFlowDidStart")
    static let paymentFlowDidEnd = Notification.Name("paymentFlowDidEnd")
}

#Preview {
    ContentView()
}
