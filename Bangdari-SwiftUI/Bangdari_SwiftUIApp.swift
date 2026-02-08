//

import SwiftUI
import UIKit
import iamport_ios
import KakaoSDKCommon
import KakaoSDKAuth

@main
struct Bangdari_SwiftUIApp: App {
    // AppDelegate 연결
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // KakaoSDK 초기화
        KakaoSDK.initSDK(appKey: Secrets.kakaoAppKey)

        configureNavigationBarAppearance()
//
//        for family in UIFont.familyNames.sorted() {
//            let names = UIFont.fontNames(forFamilyName: family).sorted().joined(separator: ", ")
//            print("[Font] \(family): \(names)")
//        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // 앱 시작 시 푸시 알림 권한 요청
                    Task { @MainActor in
                        await PushNotificationManager.shared.requestAuthorization()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .didLogin)) { _ in
                    // 로그인 시 디바이스 토큰 업데이트
                    Task { @MainActor in
                        await PushNotificationManager.shared.updateTokenAfterLogin()
                    }
                }
                .onOpenURL { url in
                    print("🔗 URL Received: \(url)")

                    // 카카오 로그인 URL 처리
                    if AuthApi.isKakaoTalkLoginUrl(url) {
                        _ = AuthController.handleOpenUrl(url: url)
                    } else {
                        // 포트원 결제 URL 처리
                        Iamport.shared.receivedURL(url)
                    }
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
