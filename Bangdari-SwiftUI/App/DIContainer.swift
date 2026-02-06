import Foundation

// MARK: - Dependency Injection Container

@MainActor
final class DIContainer: @unchecked Sendable {
    static let shared = DIContainer()

    private init() {}

    // MARK: - Repositories

    func makeAuthRepository() -> AuthRepository {
        switch AppEnvironment.current {
        case .live:
            return RemoteAuthRepository()
        case .mock:
            return RemoteAuthRepository() // TODO: MockAuthRepository
        }
    }

    func makeUserRepository() -> UserRepository {
        switch AppEnvironment.current {
        case .live:
            return RemoteUserRepository()
        case .mock:
            return RemoteUserRepository() // TODO: MockUserRepository
        }
    }

    func makeEstateRepository() -> EstateRepository {
        switch AppEnvironment.current {
        case .live:
            return RemoteEstateRepository()
        case .mock:
            return RemoteEstateRepository() // TODO: MockEstateRepository
        }
    }

    func makePostRepository() -> PostRepository {
        switch AppEnvironment.current {
        case .live:
            return RemotePostRepository()
        case .mock:
            return RemotePostRepository() // TODO: MockPostRepository
        }
    }

    func makeChatRepository() -> ChatRepository {
        switch AppEnvironment.current {
        case .live:
            return RemoteChatRepository()
        case .mock:
            return RemoteChatRepository() // TODO: MockChatRepository
        }
    }

    func makeOrderRepository() -> OrderRepository {
        switch AppEnvironment.current {
        case .live:
            return RemoteOrderRepository()
        case .mock:
            return RemoteOrderRepository()
        }
    }

    func makePaymentRepository() -> PaymentRepository {
        switch AppEnvironment.current {
        case .live:
            return RemotePaymentRepository()
        case .mock:
            return RemotePaymentRepository()
        }
    }

    func makeVideoRepository() -> VideoRepository {
        switch AppEnvironment.current {
        case .live:
            return RemoteVideoRepository()
        case .mock:
            return RemoteVideoRepository() // TODO: MockVideoRepository
        }
    }
}
