import Foundation
import Security

// MARK: - Keychain Manager

final class KeychainManager: @unchecked Sendable {
    static let shared = KeychainManager()

    private let service = "com.bangdari.swiftui"

    private enum Key: String {
        case accessToken
        case refreshToken
        case userId
    }

    private init() {}

    // MARK: - Token Management

    var accessToken: String? {
        get { read(key: .accessToken) }
        set { save(key: .accessToken, value: newValue) }
    }

    var refreshToken: String? {
        get { read(key: .refreshToken) }
        set { save(key: .refreshToken, value: newValue) }
    }

    var userId: String? {
        get { read(key: .userId) }
        set { save(key: .userId, value: newValue) }
    }

    var isLoggedIn: Bool {
        accessToken != nil
    }

    // MARK: - Save Tokens

    func saveTokens(access: String, refresh: String, userId: String) {
        accessToken = access
        refreshToken = refresh
        self.userId = userId
    }

    func clearTokens() {
        delete(key: .accessToken)
        delete(key: .refreshToken)
        delete(key: .userId)
    }

    // MARK: - Private Methods

    private func save(key: Key, value: String?) {
        guard let value else {
            delete(key: key)
            return
        }

        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]

        // 기존 값 삭제 후 저장
        SecItemDelete(query as CFDictionary)

        var newQuery = query
        newQuery[kSecValueData as String] = data

        SecItemAdd(newQuery as CFDictionary, nil)
    }

    private func read(key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    private func delete(key: Key) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]

        SecItemDelete(query as CFDictionary)
    }
}
