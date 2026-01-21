import Foundation

// MARK: - Dependency Injection Container

final class DIContainer {
    static let shared = DIContainer()

    private init() {}

    // MARK: - Repositories

    var authRepository: AuthRepository {
        switch AppEnvironment.current {
        case .live:
            return RemoteAuthRepository()
        case .mock:
            return RemoteAuthRepository() // TODO: MockAuthRepository
        }
    }
}
