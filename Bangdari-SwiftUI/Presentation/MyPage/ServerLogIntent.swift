import Combine
import Foundation

// MARK: - Server Log State

struct ServerLogState {
    var logs: [ServerLogEntry] = []
    var isLoading: Bool = false
    var errorMessage: String?
}

// MARK: - Server Log Intent

@MainActor
final class ServerLogIntent: ObservableObject {
    @Published private(set) var state = ServerLogState()
    private let network = NetworkService.shared

    func loadLogs() async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            let response = try await network.request(.serverLogs, type: ServerLogResponse.self)
            state.logs = response.logs
        } catch {
            state.errorMessage = "서버 요청 로그를 불러오지 못했습니다."
        }

        state.isLoading = false
    }

    func refresh() async {
        await loadLogs()
    }
}
