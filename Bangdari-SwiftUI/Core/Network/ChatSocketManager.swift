import Foundation

// MARK: - Chat Socket Manager
// Socket.IO 라이브러리 추가 후 활성화
// SPM: https://github.com/socketio/socket.io-client-swift

final class ChatSocketManager {
    private let roomId: String
    private var isConnectedFlag: Bool = false

    // Callbacks
    var onMessage: ((ChatResponse) -> Void)?
    var onConnectionChanged: ((Bool) -> Void)?

    init(roomId: String) {
        self.roomId = roomId
    }

    // MARK: - Connection

    func connect() {
        // TODO: Socket.IO 연결 구현
        // Socket.IO URL: {baseURL}/chats-{room_id} namespace
        //
        // 라이브러리 추가 후:
        // 1. SocketManager 생성 (socketURL, config with headers)
        // 2. socket(forNamespace: "/chats-\(roomId)") 획득
        // 3. on("chat") 이벤트 리스너 등록
        // 4. connect() 호출

        print("🔌 [ChatSocket] Connecting to room: \(roomId)")

        // 임시: 연결 성공 알림
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isConnectedFlag = true
            self?.onConnectionChanged?(true)
        }
    }

    func disconnect() {
        print("🔌 [ChatSocket] Disconnecting from room: \(roomId)")
        isConnectedFlag = false
        onConnectionChanged?(false)
    }

    var isConnected: Bool {
        isConnectedFlag
    }

    // MARK: - Message Handling (Socket.IO 라이브러리 추가 후 구현)

    /*
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
    */

    deinit {
        disconnect()
    }
}

// MARK: - Socket.IO 설정 예시 (라이브러리 추가 후)
/*
import SocketIO

final class ChatSocketManager {
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private let roomId: String

    var onMessage: ((ChatResponse) -> Void)?
    var onConnectionChanged: ((Bool) -> Void)?

    init(roomId: String) {
        self.roomId = roomId
        setupSocket()
    }

    private func setupSocket() {
        guard let url = URL(string: Secrets.baseURL) else { return }

        let config: SocketIOClientConfiguration = [
            .log(false),
            .compress,
            .forceWebsockets(true),
            .extraHeaders([
                "SeSACKey": Secrets.sesacKey,
                "Authorization": KeychainManager.shared.accessToken ?? ""
            ])
        ]

        manager = SocketManager(socketURL: url, config: config)
        socket = manager?.socket(forNamespace: "/chats-\(roomId)")

        setupEventHandlers()
    }

    private func setupEventHandlers() {
        socket?.on(clientEvent: .connect) { [weak self] _, _ in
            print("✅ Socket connected to room: \(self?.roomId ?? "")")
            self?.onConnectionChanged?(true)
        }

        socket?.on(clientEvent: .disconnect) { [weak self] _, _ in
            print("❌ Socket disconnected from room: \(self?.roomId ?? "")")
            self?.onConnectionChanged?(false)
        }

        socket?.on("chat") { [weak self] data, _ in
            guard let jsonData = data.first else { return }
            self?.handleIncomingMessage(jsonData)
        }
    }

    func connect() {
        socket?.connect()
    }

    func disconnect() {
        socket?.disconnect()
    }

    private func handleIncomingMessage(_ data: Any) {
        // ... decode and call onMessage
    }
}
*/
