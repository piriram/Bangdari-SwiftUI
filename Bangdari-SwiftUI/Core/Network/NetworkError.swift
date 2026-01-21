import Foundation

// MARK: - Network Error

enum NetworkError: Error {
    // HTTP 에러
    case badRequest             // 400
    case unauthorized           // 401 - 유효하지 않은 토큰
    case forbidden              // 403
    case notFound               // 404
    case conflict               // 409
    case tokenExpired           // 419 - AccessToken 만료
    case invalidSesacKey        // 420
    case notParticipant         // 445 - 채팅방 참여자 아님
    case refreshTokenExpired    // 418 - RefreshToken 만료
    case tooManyRequests        // 429 - 과호출
    case invalidURL             // 444
    case serverError            // 500

    // 클라이언트 에러
    case invalidResponse
    case decodingFailed
    case networkFailure(Error)
    case unknown

    var message: String {
        switch self {
        case .badRequest: return "잘못된 요청입니다."
        case .unauthorized: return "인증할 수 없는 액세스 토큰입니다."
        case .forbidden: return "접근 권한이 없습니다."
        case .notFound: return "요청한 리소스를 찾을 수 없습니다."
        case .conflict: return "이미 존재하는 데이터입니다."
        case .tokenExpired: return "액세스 토큰이 만료되었습니다."
        case .invalidSesacKey: return "유효하지 않은 SeSAC Key입니다."
        case .notParticipant: return "채팅방 참여자가 아닙니다."
        case .refreshTokenExpired: return "리프레시 토큰이 만료되었습니다. 다시 로그인 해주세요."
        case .tooManyRequests: return "과호출입니다. 잠시 후 다시 시도해주세요."
        case .invalidURL: return "잘못된 URL입니다."
        case .serverError: return "서버 오류가 발생했습니다."
        case .invalidResponse: return "잘못된 응답입니다."
        case .decodingFailed: return "데이터 파싱에 실패했습니다."
        case .networkFailure: return "네트워크 연결을 확인해주세요."
        case .unknown: return "알 수 없는 오류가 발생했습니다."
        }
    }

    // 재로그인 필요 여부
    var requiresRelogin: Bool {
        switch self {
        case .unauthorized, .refreshTokenExpired:
            return true
        default:
            return false
        }
    }

    // 토큰 갱신 필요 여부
    var requiresTokenRefresh: Bool {
        if case .tokenExpired = self { return true }
        return false
    }

    static func from(statusCode: Int) -> NetworkError {
        switch statusCode {
        case 400: return .badRequest
        case 401: return .unauthorized
        case 403: return .forbidden
        case 404: return .notFound
        case 409: return .conflict
        case 418: return .refreshTokenExpired
        case 419: return .tokenExpired
        case 420: return .invalidSesacKey
        case 429: return .tooManyRequests
        case 444: return .invalidURL
        case 445: return .notParticipant
        case 500...599: return .serverError
        default: return .unknown
        }
    }
}
