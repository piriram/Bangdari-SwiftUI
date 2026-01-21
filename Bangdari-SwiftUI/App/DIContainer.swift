import Foundation

// MARK: - Dependency Injection Container

final class DIContainer {
    static let shared = DIContainer()

    private init() {}

    // MARK: - Repositories

    // TODO: Repository 구현 후 추가
    // var estateRepository: EstateRepository {
    //     switch AppEnvironment.current {
    //     case .live:
    //         return RemoteEstateRepository()
    //     case .mock:
    //         return MockEstateRepository()
    //     }
    // }
}
