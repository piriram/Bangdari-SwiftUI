import Foundation

// MARK: - Network Service

final class NetworkService: @unchecked Sendable {
    static let shared = NetworkService()

    private let session: URLSession
    private let keychain = KeychainManager.shared
    private let lock = NSLock()
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

        // 🔍 DEBUG: Raw JSON 출력
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📦 [RAW] \(endpoint.path)")
            print(jsonString)
            print("📦 [RAW END]")
        }

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

    /// Multipart/form-data 파일 업로드
    func uploadFiles<T: Decodable>(
        _ endpoint: APIEndpoint,
        files: [Data],
        fieldName: String = "files",
        type: T.Type
    ) async throws -> T {
        let request = try buildMultipartRequest(endpoint, files: files, fieldName: fieldName)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            // 성공
            if (200...299).contains(httpResponse.statusCode) {
                return try JSONDecoder().decode(T.self, from: data)
            }

            // 419: AccessToken 만료 → 갱신 후 재시도
            if httpResponse.statusCode == 419 {
                try await refreshTokenAndRetry()
                return try await uploadFiles(endpoint, files: files, fieldName: fieldName, type: type)
            }

            // 기타 에러
            let error = NetworkError.from(statusCode: httpResponse.statusCode)
            print("❌ Upload Error [\(httpResponse.statusCode)]: \(endpoint.path)")
            if let body = String(data: data, encoding: .utf8) { print("📝 Server: \(body)") }
            throw error

        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.networkFailure(error)
        }
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

    private func buildMultipartRequest(
        _ endpoint: APIEndpoint,
        files: [Data],
        fieldName: String
    ) throws -> URLRequest {
        var components = URLComponents(string: Secrets.baseURL + endpoint.path)
        components?.queryItems = endpoint.queryItems

        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        // Boundary 생성
        let boundary = "Boundary-\(UUID().uuidString)"

        // Headers
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(Secrets.sesacKey, forHTTPHeaderField: "SeSACKey")

        if endpoint.requiresAuth, let token = keychain.accessToken {
            request.setValue(token, forHTTPHeaderField: "Authorization")
        }

        // Body 구성
        var body = Data()

        for (index, fileData) in files.enumerated() {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"file\(index).jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        return request
    }

    // MARK: - Token Refresh

    private func refreshTokenAndRetry() async throws {
        // 이미 갱신 중이면 대기
        let shouldWait: Bool = lock.withLock {
            if isRefreshing {
                return true
            }
            isRefreshing = true
            return false
        }

        if shouldWait {
            await withCheckedContinuation { continuation in
                lock.withLock {
                    pendingRequests.append(continuation)
                }
            }
            return
        }

        defer {
            lock.withLock {
                isRefreshing = false
                pendingRequests.forEach { $0.resume() }
                pendingRequests.removeAll()
            }
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
            await MainActor.run {
                NotificationCenter.default.post(name: .didLogout, object: nil)
            }
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
