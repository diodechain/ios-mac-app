import Foundation

public struct JsonRpcRequest: Encodable {
    public let jsonrpc: String
    public let id: Int
    public let method: String
    public let params: [AnyEncodable]

    public init(id: Int, method: String, params: [AnyEncodable]) {
        self.jsonrpc = "2.0"
        self.id = id
        self.method = method
        self.params = params
    }
}

public struct JsonRpcResponse {
    public let jsonrpc: String?
    public let id: Int?
    public let result: Any?
    public let error: JsonRpcError?
}

public struct JsonRpcError {
    public let code: Int
    public let message: String
    public let data: [String: Any]?
}

public enum JsonRpc {
    public static func toJSON(_ request: JsonRpcRequest) throws -> String {
        let data = try JSONEncoder().encode(request)
        guard let json = String(data: data, encoding: .utf8) else {
            throw JsonRpcErrorCode.encodingFailed
        }
        return json
    }

    public static func parseResponse(_ json: String) throws -> JsonRpcResponse {
        guard let data = json.data(using: .utf8),
              let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            throw JsonRpcErrorCode.invalidJSON
        }

        let id = parseID(object["id"])
        let nestedError = parseErrorObject(object["error"] as? [String: Any])
        let flatError: JsonRpcError?
        if nestedError == nil,
           object["code"] != nil,
           object["message"] != nil,
           object["result"] == nil
        {
            flatError = parseErrorObject(object)
        } else {
            flatError = nil
        }

        return JsonRpcResponse(
            jsonrpc: object["jsonrpc"] as? String,
            id: id,
            result: object["result"],
            error: nestedError ?? flatError
        )
    }

    private static func parseErrorObject(_ object: [String: Any]?) -> JsonRpcError? {
        guard let object else { return nil }
        let code = parseCode(object["code"]) ?? -1
        let message = object["message"] as? String ?? "error"
        let data = object["data"] as? [String: Any]
        return JsonRpcError(code: code, message: message, data: data)
    }

    private static func parseID(_ value: Any?) -> Int? {
        switch value {
        case let number as Int: return number
        case let number as Double: return Int(number)
        case let string as String: return Int(string)
        default: return nil
        }
    }

    private static func parseCode(_ value: Any?) -> Int? {
        switch value {
        case let number as Int: return number
        case let number as Double: return Int(number)
        case let string as String: return Int(string)
        default: return nil
        }
    }
}

public enum JsonRpcErrorCode: Error {
    case encodingFailed
    case invalidJSON
}

public struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    public init(_ value: some Encodable) {
        encode = value.encode
    }

    public init(_ value: String) {
        encode = { encoder in
            var container = encoder.singleValueContainer()
            try container.encode(value)
        }
    }

    public func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}

public extension JsonRpcResponse {
    func isError() -> Bool { error != nil }
    func errorMessage() -> String? { error?.message }
}
