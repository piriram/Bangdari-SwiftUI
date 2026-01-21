import Foundation

// MARK: - Network Service

actor NetworkService {
    static let shared = NetworkService()

    private let session: URLSession
    private let keychain = KeychainManager.shared
    private var isRefreshing = false
    private var pendingRequests: [CheckedContinuation<Void, Never>] = []

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - Public Methods

    func request<T: Decodable>(
        _ endpoint: APIEndpoint,
        body: Encodable? = nil,
        type: T.Type
    ) async throws -> T {
        let data = try await requestData(endpoint, body: body)

        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            return decoded
        } catch {
            print("❌ Decoding Error: \(error)")
            throw NetworkError.decodingFailed
        }
    }

    func requestWithoutResponse(
        _ endpoint: APIEndpoint,
        body: Encodable? = nil
    ) async throws {
        _ = try await requestData(endpoint, body: body)
    }

    // MARK: - Private Methods

    private func requestData(
        _ endpoint: APIEndpoint,
        body: Encodable? = nil
    ) async throws -> Data {
        let request = try buildRequest(endpoint, body: body)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            // 성공
            if (200...299).contains(httpResponse.statusCode) {
                return data
            }

            // 419: AccessToken 만료 → 갱신 후 재시도
            if httpResponse.statusCode == 419 {
                try await refreshTokenAndRetry()
                return try await requestData(endpoint, body: body)
            }

            // 기타 에러
            let error = NetworkError.from(statusCode: httpResponse.statusCode)
            print("❌ API Error [\(httpResponse.statusCode)]: \(endpoint.path)")
            throw error

        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.networkFailure(error)
        }
    }

    private func buildRequest(_ endpoint: APIEndpoint, body: Encodable?) throws -> URLRequest {
        var components = URLComponents(string: Secrets.baseURL + endpoint.path)
        components?.queryItems = endpoint.queryItems

        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        // Headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Secrets.sesacKey, forHTTPHeaderField: "SeSACKey")

        if endpoint.requiresAuth, let token = keychain.accessToken {
            request.setValue(token, forHTTPHeaderField: "Authorization")
        }

        // Body
        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        return request
    }

    // MARK: - Token Refresh

    private func refreshTokenAndRetry() async throws {
        // 이미 갱신 중이면 대기
        if isRefreshing {
            await withCheckedContinuation { continuation in
                pendingRequests.append(continuation)
            }
            return
        }

        isRefreshing = true
        defer {
            isRefreshing = false
            // 대기 중인 요청들 해제
            pendingRequests.forEach { $0.resume() }
            pendingRequests.removeAll()
        }

        guard let refreshToken = keychain.refreshToken else {
            throw NetworkError.refreshTokenExpired
        }

        // Refresh 요청
        var request = URLRequest(url: URL(string: Secrets.baseURL + "/v1/auth/refresh")!)
        request.httpMethod = "GET"
        request.setValue(Secrets.sesacKey, forHTTPHeaderField: "SeSACKey")
        request.setValue(refreshToken, forHTTPHeaderField: "RefreshToken")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        // 418: RefreshToken도 만료 → 재로그인 필요
        if httpResponse.statusCode == 418 {
            keychain.clearTokens()
            throw NetworkError.refreshTokenExpired
        }

        guard httpResponse.statusCode == 200 else {
            throw NetworkError.from(statusCode: httpResponse.statusCode)
        }

        // 새 토큰 저장
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        keychain.accessToken = tokenResponse.accessToken
        keychain.refreshToken = tokenResponse.refreshToken

        print("✅ Token refreshed successfully")
    }
}

// MARK: - Token Response DTO

private struct TokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
}
