import Foundation

// MARK: - Dependency Injection Container

final class DIContainer: @unchecked Sendable {
    static let shared = DIContainer()

    private init() {}

    // MARK: - Repositories

    nonisolated func makeAuthRepository() -> AuthRepository {
        switch AppEnvironment.current {
        case .live:
            return RemoteAuthRepository()
        case .mock:
            return RemoteAuthRepository() // TODO: MockAuthRepository
        }
    }

    nonisolated func makeEstateRepository() -> EstateRepository {
        switch AppEnvironment.current {
        case .live:
            return RemoteEstateRepository()
        case .mock:
            return RemoteEstateRepository() // TODO: MockEstateRepository
        }
    }
}
