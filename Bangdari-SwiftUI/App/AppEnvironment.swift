import Foundation

// MARK: - App Environment

enum AppEnvironment {
    case live   // 실제 서버
    case mock   // 목업 데이터

    static var current: AppEnvironment {
        #if DEBUG
        return .live  // 개발 중에는 live, 서버 종료 후 .mock으로 변경
        #else
        return .live
        #endif
    }
}

// MARK: - API Configuration

enum APIConfig {
    static var baseURL: String {
        Secrets.baseURL
    }

    static var sesacKey: String {
        Secrets.sesacKey
    }
}
