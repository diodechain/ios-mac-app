import DiodeCrypto
import DiodeNetwork
import Foundation

/// WebSocket JSON-RPC client for Diode: `dio_ticket`, `dio_wireguard_open`, `dio_wireguard_close`.
public final class DiodeRpcClient: @unchecked Sendable {
    public protocol RpcLifecycleListener: AnyObject {
        func onTicketRequest(usage: UInt64, fleetHex: String?)
        func onRpcClosed(reason: String)
    }

    public enum RpcException: Error, Equatable {
        case notAuthenticated(message: String, rpcCode: Int?)
        case wireGuardError(message: String, rpcCode: Int?)
        case wireGuardNotEnabled(message: String, rpcCode: Int?)
        case invalidTicket(message: String, rpcCode: Int?)
        case ticketTooLow(message: String, usage: UInt64, summary: DioTicketSummary?, rawResponse: String?, rpcCode: Int?)
        case other(message: String, rpcCode: Int?)

        public var rpcCode: Int? {
            switch self {
            case let .notAuthenticated(_, code),
                 let .wireGuardError(_, code),
                 let .wireGuardNotEnabled(_, code),
                 let .invalidTicket(_, code),
                 let .ticketTooLow(_, _, _, _, code),
                 let .other(_, code):
                return code
            }
        }

        public var message: String {
            switch self {
            case let .notAuthenticated(message, _),
                 let .wireGuardError(message, _),
                 let .wireGuardNotEnabled(message, _),
                 let .invalidTicket(message, _),
                 let .ticketTooLow(message, _, _, _, _),
                 let .other(message, _):
                return message
            }
        }
    }

    public static let maxTooLowAttempts = 3

    private let wsURL: URL
    private weak var lifecycleListener: RpcLifecycleListener?
    private let session: URLSession
    private let delegateBox: WebSocketDelegateBox

    private let state = RpcClientState()

    public init(
        wsURL: String = NetworkConfig.prenetWsURL,
        lifecycleListener: RpcLifecycleListener? = nil,
        session: URLSession? = nil
    ) {
        let url = URL(string: wsURL)!
        self.wsURL = url
        self.lifecycleListener = lifecycleListener
        let delegateBox = WebSocketDelegateBox(wsURLString: wsURL)
        self.delegateBox = delegateBox
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 15
            config.timeoutIntervalForResource = 30
            self.session = URLSession(configuration: config, delegate: delegateBox, delegateQueue: nil)
        }
        delegateBox.owner = self
    }

    public func connectAwait(timeoutNanoseconds: UInt64 = 25_000_000_000) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await Task.sleep(nanoseconds: timeoutNanoseconds)
                throw RpcClientError.connectTimeout
            }
            group.addTask {
                try await self.connectInternal()
            }
            try await group.next()
            group.cancelAll()
        }
    }

    private func connectInternal() async throws {
        if await state.isConnected() {
            return
        }

        let task = session.webSocketTask(with: wsURL)
        await state.setWebSocketTask(task)
        await state.resetLifecycleNotified()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            delegateBox.onOpen = { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
            task.resume()
        }

        await state.startReceiveLoop { [weak self] text in
            self?.handleMessage(text)
        }
    }

    public func disconnect() {
        Task {
            await state.disconnect(notify: "Disconnected")
        }
    }

    public func isConnected() async -> Bool {
        await state.isConnected()
    }

    func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            resumeResponseIfPossible(text)
            return
        }

        if object["method"] != nil, object["id"] == nil {
            dispatchNotification(object)
            return
        }

        resumeResponseIfPossible(text)
    }

    private func resumeResponseIfPossible(_ text: String) {
        Task {
            do {
                let response = try JsonRpc.parseResponse(text)
                guard let id = response.id else { return }
                await state.resumePending(id: id, response: text)
            } catch {
                // Ignore malformed frames.
            }
        }
    }

    func dispatchNotification(_ object: [String: Any]) {
        guard let method = object["method"] as? String else { return }
        switch method {
        case "dio_ticket_request":
            guard let notification = Self.parseTicketRequestNotification(object) else { return }
            lifecycleListener?.onTicketRequest(usage: notification.usage, fleetHex: notification.fleetHex)
        default:
            break
        }
    }

  /// Parses a `dio_ticket_request` JSON-RPC notification object.
    static func parseTicketRequestNotification(_ object: [String: Any]) -> (usage: UInt64, fleetHex: String?)? {
        guard object["method"] as? String == "dio_ticket_request",
              let params = object["params"] as? [String: Any],
              let usage = parseUsageValue(params["usage"])
        else {
            return nil
        }
        let fleet = params["fleet"] as? String
        return (usage: usage, fleetHex: fleet)
    }

    func sendRequestRaw(method: String, params: [AnyEncodable]) async throws -> String {
        let id = await state.nextID()
        let request = JsonRpcRequest(id: id, method: method, params: params)
        let payload = try JsonRpc.toJSON(request)

        return try await withCheckedThrowingContinuation { continuation in
            Task {
                guard let task = await state.currentWebSocketTask() else {
                    continuation.resume(throwing: RpcClientError.notConnected)
                    return
                }
                await state.storePending(id: id, continuation: continuation)
                task.send(.string(payload)) { error in
                    if let error {
                        Task {
                            await self.state.removePending(id: id)
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        }
    }

    private func send(method: String, params: [AnyEncodable]) async throws -> JsonRpcResponse {
        let raw = try await sendRequestRaw(method: method, params: params)
        return try JsonRpc.parseResponse(raw)
    }

    public func dioTicket(ticketHex: String) async throws {
        let raw = try await sendRequestRaw(
            method: "dio_ticket",
            params: [AnyEncodable(DiodeHex.ensureHex0xPrefix(ticketHex))]
        )
        let response = try JsonRpc.parseResponse(raw)
        if response.isError() {
            throw ticketRpcException(response, rawResponse: raw)
        }
    }

    func ticketRpcException(_ response: JsonRpcResponse, rawResponse: String? = nil) -> RpcException {
        let message = response.errorMessage() ?? "Unknown error"
        let code = response.error?.code
        switch code {
        case -32_000:
            return .notAuthenticated(message: message, rpcCode: code)
        case -32_001, -32_002:
            if message.lowercased() == "too_low" {
                let parsed = Self.parseTooLowData(response.error?.data)
                return .ticketTooLow(
                    message: message,
                    usage: parsed.usage,
                    summary: parsed.summary,
                    rawResponse: rawResponse,
                    rpcCode: code
                )
            }
            return .invalidTicket(message: message, rpcCode: code)
        default:
            return .other(message: message, rpcCode: code)
        }
    }

    static func parseTooLowData(_ data: [String: Any]?) -> ParsedTooLow {
        guard let data else {
            return ParsedTooLow(usage: 0, summary: nil)
        }
        let usage = parseUsageValue(data["usage"]) ?? 0
        if let summaryObject = data["summary"] as? [String: Any] {
            let summary = DioTicketSummary(
                totalConnections: parseUsageValue(summaryObject["total_connections"]) ?? 0,
                totalBytes: parseUsageValue(summaryObject["total_bytes"]) ?? 0
            )
            return ParsedTooLow(usage: usage, summary: summary)
        }
        return ParsedTooLow(usage: usage, summary: nil)
    }

    static func parseUsageValue(_ value: Any?) -> UInt64? {
        switch value {
        case let number as Int:
            return UInt64(number)
        case let number as Double:
            return UInt64(number)
        case let string as String:
            return try? DiodeHex.decodeBigInt(string)
        default:
            return nil
        }
    }

    public func dioWireguardOpenSession(publicKeyHex: String) async throws -> WireGuardSessionInfo {
        let response = try await send(
            method: "dio_wireguard_open",
            params: [AnyEncodable(DiodeHex.ensureHex0xPrefix(publicKeyHex))]
        )
        if response.isError() {
            throw wireguardRpcException(response)
        }
        return try WireGuardSessionInfo.fromRpcResult(response.result)
    }

    public func dioWireguardOpen(publicKeyHex: String) async throws {
        _ = try await dioWireguardOpenSession(publicKeyHex: publicKeyHex)
    }

    public func dioWireguardClose() async throws {
        let response = try await send(method: "dio_wireguard_close", params: [])
        if response.isError() {
            throw RpcException.other(
                message: response.errorMessage() ?? "dio_wireguard_close failed",
                rpcCode: response.error?.code
            )
        }
    }

    private func wireguardRpcException(_ response: JsonRpcResponse) -> RpcException {
        let message = response.errorMessage() ?? "Unknown error"
        let code = response.error?.code
        if message.localizedCaseInsensitiveContains("not authenticated") {
            return .notAuthenticated(message: message, rpcCode: code ?? -32_000)
        }
        if message.localizedCaseInsensitiveContains("not enabled") {
            return .wireGuardNotEnabled(message: message, rpcCode: code)
        }
        if message.localizedCaseInsensitiveContains("wireguard error") {
            return .wireGuardError(message: message, rpcCode: code)
        }
        if code == -32_602 {
            return .other(message: message, rpcCode: code)
        }
        return .wireGuardError(message: message, rpcCode: code)
    }

    fileprivate func handleTerminalClose(reason: String) {
        Task {
            await state.handleTerminalClose(reason: reason)
            notifyRpcClosedOnce(reason)
        }
    }

    fileprivate func notifyRpcClosedOnce(_ reason: String) {
        Task {
            let shouldNotify = await state.markLifecycleTerminal()
            if shouldNotify {
                lifecycleListener?.onRpcClosed(reason: reason)
            }
        }
    }
}

enum RpcClientError: Error {
    case notConnected
    case connectTimeout
    case sendFailed
    case disconnected
}

private actor RpcClientState {
    private var webSocketTask: URLSessionWebSocketTask?
    private var receiveTask: Task<Void, Never>?
    private var pending: [Int: CheckedContinuation<String, Error>] = [:]
    private var nextRequestID = 1
    private var lifecycleTerminalNotified = false

    func currentWebSocketTask() -> URLSessionWebSocketTask? {
        webSocketTask
    }

    func isConnected() -> Bool {
        webSocketTask != nil
    }

    func setWebSocketTask(_ task: URLSessionWebSocketTask) {
        webSocketTask = task
    }

    func resetLifecycleNotified() {
        lifecycleTerminalNotified = false
    }

    func markLifecycleTerminal() -> Bool {
        if lifecycleTerminalNotified {
            return false
        }
        lifecycleTerminalNotified = true
        return true
    }

    func nextID() -> Int {
        defer { nextRequestID += 1 }
        return nextRequestID
    }

    func storePending(id: Int, continuation: CheckedContinuation<String, Error>) {
        pending[id] = continuation
    }

    func resumePending(id: Int, response: String) {
        pending.removeValue(forKey: id)?.resume(returning: response)
    }

    func removePending(id: Int) {
        pending.removeValue(forKey: id)
    }

    func startReceiveLoop(handler: @escaping @Sendable (String) -> Void) {
        receiveTask?.cancel()
        guard let task = webSocketTask else { return }
        receiveTask = Task {
            while !Task.isCancelled {
                do {
                    let message = try await task.receive()
                    switch message {
                    case let .string(text):
                        handler(text)
                    case let .data(data):
                        if let text = String(data: data, encoding: .utf8) {
                            handler(text)
                        }
                    @unknown default:
                        break
                    }
                } catch {
                    break
                }
            }
        }
    }

    func disconnect(notify: String) {
        receiveTask?.cancel()
        receiveTask = nil
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        let error = RpcClientError.disconnected
        for continuation in pending.values {
            continuation.resume(throwing: error)
        }
        pending.removeAll()
    }

    func handleTerminalClose(reason: String) {
        receiveTask?.cancel()
        receiveTask = nil
        webSocketTask = nil
        let error = RpcClientError.disconnected
        for continuation in pending.values {
            continuation.resume(throwing: error)
        }
        pending.removeAll()
    }
}

private final class WebSocketDelegateBox: NSObject, URLSessionWebSocketDelegate, @unchecked Sendable {
    weak var owner: DiodeRpcClient?
    var onOpen: ((Error?) -> Void)?
    private let wsURLString: String

    init(wsURLString: String) {
        self.wsURLString = wsURLString
        super.init()
    }

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        onOpen?(nil)
        onOpen = nil
    }

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        let reasonText = reason.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        let message = "WebSocket closed: \(closeCode.rawValue) \(reasonText)"
        owner?.handleTerminalClose(reason: message)
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust
        else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        if DiodeTlsPolicy.shouldTrustAllCertificatesForWebSocketURL(wsURLString) {
            completionHandler(.useCredential, URLCredential(trust: trust))
            return
        }
        completionHandler(.performDefaultHandling, nil)
    }
}
