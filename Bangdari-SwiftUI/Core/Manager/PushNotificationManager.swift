import Foundation
import UIKit
import UserNotifications

// MARK: - Push Notification Manager

final class PushNotificationManager: NSObject {
    @MainActor static let shared = PushNotificationManager()

    private var userRepository: UserRepository?
    private var deviceToken: String?

    private override init() {
        super.init()
    }

    @MainActor
    private func getUserRepository() -> UserRepository {
        if userRepository == nil {
            userRepository = DIContainer.shared.makeUserRepository()
        }
        return userRepository!
    }

    // MARK: - Request Permission

    /// 푸시 알림 권한 요청
    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )

            if granted {
                print("✅ 푸시 알림 권한 승인됨")
                await registerForRemoteNotifications()
            } else {
                print("❌ 푸시 알림 권한 거부됨")
            }
        } catch {
            print("❌ 푸시 알림 권한 요청 실패: \(error)")
        }
    }

    /// 원격 알림 등록 (APNs)
    private func registerForRemoteNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    // MARK: - Device Token

    /// APNs 디바이스 토큰 저장 및 서버 업데이트
    func setDeviceToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = tokenString
        print("📱 APNs Device Token: \(tokenString)")

        // 서버에 토큰 업데이트
        Task { @MainActor in
            await updateDeviceTokenToServer(tokenString)
        }
    }

    /// Firebase FCM 토큰 저장 및 서버 업데이트 (Firebase 설치 시 사용)
    func setFCMToken(_ token: String) {
        self.deviceToken = token
        print("📱 FCM Token: \(token)")

        // 서버에 토큰 업데이트
        Task { @MainActor in
            await updateDeviceTokenToServer(token)
        }
    }

    /// 서버에 디바이스 토큰 업데이트
    @MainActor
    private func updateDeviceTokenToServer(_ token: String) async {
        // 로그인되어 있을 때만 업데이트
        guard KeychainManager.shared.accessToken != nil else {
            print("⚠️ 로그인되지 않아 디바이스 토큰 업데이트를 건너뜁니다.")
            return
        }

        do {
            let repository = getUserRepository()
            try await repository.updateDeviceToken(token: token)
            print("✅ 디바이스 토큰 서버 업데이트 완료")
        } catch {
            print("❌ 디바이스 토큰 서버 업데이트 실패: \(error)")
        }
    }

    // MARK: - Login Event

    /// 로그인 시 저장된 토큰 업데이트
    @MainActor
    func updateTokenAfterLogin() async {
        guard let token = deviceToken else {
            print("⚠️ 저장된 디바이스 토큰이 없습니다.")
            return
        }

        await updateDeviceTokenToServer(token)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationManager: UNUserNotificationCenterDelegate {
    /// 포그라운드 상태에서 알림 표시
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge]
    }

    /// 알림 탭 시 처리
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        print("📬 알림 탭: \(userInfo)")

        // TODO: 딥링크 처리 (채팅방, 매물 상세 등)
    }
}
