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
}
