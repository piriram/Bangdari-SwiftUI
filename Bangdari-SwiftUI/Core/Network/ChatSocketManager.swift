import Foundation
import SocketIO

// MARK: - Chat Socket Manager

final class ChatSocketManager {
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private let roomId: String

    // Callbacks
    var onMessage: ((ChatResponse) -> Void)?
    var onConnectionChanged: ((Bool) -> Void)?

    init(roomId: String) {
        self.roomId = roomId
        setupSocket()
    }

    // MARK: - Setup

    private func setupSocket() {
        guard let url = URL(string: Secrets.baseURL) else { return }

        let config: SocketIOClientConfiguration = [
            .log(false),
            .compress,
            .forceWebsockets(true),
            .extraHeaders([
                "SeSACKey": Secrets.sesacKey,
                "Authorization": KeychainManager.shared.accessToken ?? ""
            ]),
            // TODO(human): 재연결 전략 설정
            // 채팅 앱답게 백그라운드 복귀 시 빠르게 재연결되어야 하는데,
            // 동시에 배터리·네트워크 낭비도 피해야 합니다.
            // .reconnects, .reconnectWait, .reconnectWaitMax 등을 조합하여
            // 적절한 재연결 정책을 설정해주세요.
        ]

        manager = SocketManager(socketURL: url, config: config)
        socket = manager?.socket(forNamespace: "/chats-\(roomId)")

        setupEventHandlers()
    }

    private func setupEventHandlers() {
        socket?.on(clientEvent: .connect) { [weak self] _, _ in
            print("✅ [ChatSocket] Connected to room: \(self?.roomId ?? "")")
            self?.onConnectionChanged?(true)
        }

        socket?.on(clientEvent: .disconnect) { [weak self] _, _ in
            print("❌ [ChatSocket] Disconnected from room: \(self?.roomId ?? "")")
            self?.onConnectionChanged?(false)
        }

        socket?.on("chat") { [weak self] data, _ in
            guard let jsonData = data.first else { return }
            self?.handleIncomingMessage(jsonData)
        }
    }

    // MARK: - Connection

    func connect() {
        print("🔌 [ChatSocket] Connecting to room: \(roomId)")
        socket?.connect()
    }

    func disconnect() {
        print("🔌 [ChatSocket] Disconnecting from room: \(roomId)")
        socket?.disconnect()
    }

    var isConnected: Bool {
        socket?.status == .connected
    }

    // MARK: - Message Handling

    private func handleIncomingMessage(_ data: Any) {
        do {
            let jsonData: Data
            if let dict = data as? [String: Any] {
                jsonData = try JSONSerialization.data(withJSONObject: dict)
            } else if let string = data as? String, let stringData = string.data(using: .utf8) {
                jsonData = stringData
            } else {
                return
            }

            let message = try JSONDecoder().decode(ChatResponse.self, from: jsonData)
            onMessage?(message)
        } catch {
            print("❌ [ChatSocket] Failed to decode message: \(error)")
        }
    }

    deinit {
        disconnect()
    }
}
