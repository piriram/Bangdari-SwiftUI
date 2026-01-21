import Foundation

// MARK: - HTTP Method

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

// MARK: - API Endpoint

enum APIEndpoint {
    // Auth
    case refresh

    // User
    case validateEmail
    case join
    case login
    case loginKakao
    case loginApple
    case logout
    case updateDeviceToken
    case myProfile
    case updateMyProfile
    case uploadProfileImage
    case userProfile(userId: String)
    case searchUsers(nick: String)

    // Estate
    case estateDetail(estateId: String)
    case estateLike(estateId: String)
    case myLikedEstates(next: String?, limit: Int?, category: String?)
    case estatesGeolocation(lat: Double, lng: Double, maxDistance: Int, category: String?)
    case todayEstates
    case hotEstates
    case similarEstates
    case todayTopic

    // Chat
    case createChatRoom
    case chatRooms
    case sendMessage(roomId: String)
    case chatMessages(roomId: String, next: String?)
    case uploadChatFiles(roomId: String)

    // Payment
    case createOrder
    case orders
    case validatePayment
    case paymentReceipt(orderCode: String)

    // Banner
    case mainBanners

    // Video
    case videos
    case videoStream(videoId: String)
    case videoLike(videoId: String)

    // Post (Community)
    case uploadPostFiles
    case createPost
    case postsGeolocation(lat: Double, lng: Double, maxDistance: Int, category: String?)
    case searchPosts(title: String?, next: String?, limit: Int?)
    case postDetail(postId: String)
    case updatePost(postId: String)
    case deletePost(postId: String)
    case postLike(postId: String)
    case userPosts(userId: String, next: String?, limit: Int?)
    case myLikedPosts(next: String?, limit: Int?)
    case createPostComment(postId: String)
    case updatePostComment(postId: String, commentId: String)
    case deletePostComment(postId: String, commentId: String)
}

// MARK: - Endpoint Properties

extension APIEndpoint {
    var path: String {
        switch self {
        // Auth
        case .refresh: return "/v1/auth/refresh"

        // User
        case .validateEmail: return "/v1/users/validation/email"
        case .join: return "/v1/users/join"
        case .login: return "/v1/users/login"
        case .loginKakao: return "/v1/users/login/kakao"
        case .loginApple: return "/v1/users/login/apple"
        case .logout: return "/v1/users/logout"
        case .updateDeviceToken: return "/v1/users/deviceToken"
        case .myProfile: return "/v1/users/me/profile"
        case .updateMyProfile: return "/v1/users/me/profile"
        case .uploadProfileImage: return "/v1/users/profile/image"
        case .userProfile(let userId): return "/v1/users/\(userId)/profile"
        case .searchUsers: return "/v1/users/search"

        // Estate
        case .estateDetail(let estateId): return "/v1/estates/\(estateId)"
        case .estateLike(let estateId): return "/v1/estates/\(estateId)/like"
        case .myLikedEstates: return "/v1/estates/likes/me"
        case .estatesGeolocation: return "/v1/estates/geolocation"
        case .todayEstates: return "/v1/estates/today-estates"
        case .hotEstates: return "/v1/estates/hot-estates"
        case .similarEstates: return "/v1/estates/similar-estates"
        case .todayTopic: return "/v1/estates/today-topic"

        // Chat
        case .createChatRoom: return "/v1/chats"
        case .chatRooms: return "/v1/chats"
        case .sendMessage(let roomId): return "/v1/chats/\(roomId)"
        case .chatMessages(let roomId, _): return "/v1/chats/\(roomId)"
        case .uploadChatFiles(let roomId): return "/v1/chats/\(roomId)/files"

        // Payment
        case .createOrder: return "/v1/orders"
        case .orders: return "/v1/orders"
        case .validatePayment: return "/v1/payments/validation"
        case .paymentReceipt(let orderCode): return "/v1/payments/\(orderCode)"

        // Banner
        case .mainBanners: return "/v1/banners/main"

        // Video
        case .videos: return "/v1/videos"
        case .videoStream(let videoId): return "/v1/videos/\(videoId)/stream"
        case .videoLike(let videoId): return "/v1/videos/\(videoId)/like"

        // Post (Community)
        case .uploadPostFiles: return "/v1/posts/files"
        case .createPost: return "/v1/posts"
        case .postsGeolocation: return "/v1/posts/geolocation"
        case .searchPosts: return "/v1/posts/search"
        case .postDetail(let postId): return "/v1/posts/\(postId)"
        case .updatePost(let postId): return "/v1/posts/\(postId)"
        case .deletePost(let postId): return "/v1/posts/\(postId)"
        case .postLike(let postId): return "/v1/posts/\(postId)/like"
        case .userPosts(let userId, _, _): return "/v1/posts/users/\(userId)"
        case .myLikedPosts: return "/v1/posts/likes/me"
        case .createPostComment(let postId): return "/v1/posts/\(postId)/comments"
        case .updatePostComment(let postId, let commentId): return "/v1/posts/\(postId)/comments/\(commentId)"
        case .deletePostComment(let postId, let commentId): return "/v1/posts/\(postId)/comments/\(commentId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .refresh, .myProfile, .userProfile, .searchUsers,
             .estateDetail, .myLikedEstates, .estatesGeolocation,
             .todayEstates, .hotEstates, .similarEstates, .todayTopic,
             .chatRooms, .chatMessages, .orders, .paymentReceipt,
             .mainBanners, .videos, .videoStream,
             .postsGeolocation, .searchPosts, .postDetail, .userPosts, .myLikedPosts:
            return .get

        case .validateEmail, .join, .login, .loginKakao, .loginApple, .logout,
             .uploadProfileImage, .estateLike, .createChatRoom, .sendMessage,
             .uploadChatFiles, .createOrder, .validatePayment, .videoLike,
             .uploadPostFiles, .createPost, .postLike, .createPostComment:
            return .post

        case .updateDeviceToken, .updateMyProfile, .updatePost, .updatePostComment:
            return .put

        case .deletePost, .deletePostComment:
            return .delete
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .validateEmail, .join, .login, .loginKakao, .loginApple:
            return false
        default:
            return true
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .searchUsers(let nick):
            return [URLQueryItem(name: "nick", value: nick)]

        case .myLikedEstates(let next, let limit, let category):
            var items: [URLQueryItem] = []
            if let next { items.append(URLQueryItem(name: "next", value: next)) }
            if let limit { items.append(URLQueryItem(name: "limit", value: String(limit))) }
            if let category { items.append(URLQueryItem(name: "category", value: category)) }
            return items.isEmpty ? nil : items

        case .estatesGeolocation(let lat, let lng, let maxDistance, let category):
            var items: [URLQueryItem] = [
                URLQueryItem(name: "latitude", value: String(lat)),
                URLQueryItem(name: "longitude", value: String(lng)),
                URLQueryItem(name: "maxDistance", value: String(maxDistance))
            ]
            if let category { items.append(URLQueryItem(name: "category", value: category)) }
            return items

        case .chatMessages(_, let next):
            guard let next else { return nil }
            return [URLQueryItem(name: "next", value: next)]

        case .postsGeolocation(let lat, let lng, let maxDistance, let category):
            var items: [URLQueryItem] = [
                URLQueryItem(name: "latitude", value: String(lat)),
                URLQueryItem(name: "longitude", value: String(lng)),
                URLQueryItem(name: "maxDistance", value: String(maxDistance))
            ]
            if let category { items.append(URLQueryItem(name: "category", value: category)) }
            return items

        case .searchPosts(let title, let next, let limit):
            var items: [URLQueryItem] = []
            if let title { items.append(URLQueryItem(name: "title", value: title)) }
            if let next { items.append(URLQueryItem(name: "next", value: next)) }
            if let limit { items.append(URLQueryItem(name: "limit", value: String(limit))) }
            return items.isEmpty ? nil : items

        case .userPosts(_, let next, let limit):
            var items: [URLQueryItem] = []
            if let next { items.append(URLQueryItem(name: "next", value: next)) }
            if let limit { items.append(URLQueryItem(name: "limit", value: String(limit))) }
            return items.isEmpty ? nil : items

        case .myLikedPosts(let next, let limit):
            var items: [URLQueryItem] = []
            if let next { items.append(URLQueryItem(name: "next", value: next)) }
            if let limit { items.append(URLQueryItem(name: "limit", value: String(limit))) }
            return items.isEmpty ? nil : items

        default:
            return nil
        }
    }
}
