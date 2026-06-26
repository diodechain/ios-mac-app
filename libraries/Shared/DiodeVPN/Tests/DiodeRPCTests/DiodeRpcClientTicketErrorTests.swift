import XCTest
@testable import DiodeRPC

final class DiodeRpcClientTicketErrorTests: XCTestCase {
    func testParseResponseTooLowIncludesData() throws {
        let json = """
        {
          "jsonrpc": "2.0",
          "id": 1,
          "error": {
            "code": -32001,
            "message": "too_low",
            "data": {
              "usage": "f4240",
              "summary": {
                "total_connections": "64",
                "total_bytes": "186a0"
              }
            }
          }
        }
        """
        let response = try JsonRpc.parseResponse(json)
        XCTAssertTrue(response.isError())
        XCTAssertEqual(response.error?.message, "too_low")
        XCTAssertNotNil(response.error?.data)
    }

    func testParseTooLowDataDecodesHexUsageAndSummary() {
        let data: [String: Any] = [
            "usage": "f4240",
            "summary": [
                "total_connections": "64",
                "total_bytes": "186a0",
            ],
        ]
        let parsed = DiodeRpcClient.parseTooLowData(data)
        XCTAssertEqual(parsed.usage, 1_000_000)
        XCTAssertEqual(parsed.summary?.totalConnections, 100)
        XCTAssertEqual(parsed.summary?.totalBytes, 100_000)
    }

    func testTicketRpcExceptionTooLowBecomesTicketTooLow() throws {
        let json = """
        {
          "jsonrpc": "2.0",
          "id": 2,
          "error": {
            "code": -32001,
            "message": "too_low",
            "data": {
              "usage": "1000",
              "summary": { "total_connections": "0", "total_bytes": "2000" }
            }
          }
        }
        """
        let response = try JsonRpc.parseResponse(json)
        let client = DiodeRpcClient(wsURL: "wss://example.test/ws")
        let exception = client.ticketRpcException(response, rawResponse: json)

        guard case let .ticketTooLow(message, usage, summary, rawResponse, rpcCode) = exception else {
            return XCTFail("expected ticketTooLow")
        }
        XCTAssertEqual(message, "too_low")
        XCTAssertEqual(rawResponse, json)
        XCTAssertEqual(usage, 4096)
        XCTAssertEqual(summary?.totalConnections, 0)
        XCTAssertEqual(summary?.totalBytes, 8192)
        XCTAssertEqual(rpcCode, -32_001)
    }

    func testTicketRpcExceptionFlatTooLowWithTopLevelData() throws {
        let json = """
        {
          "message": "too_low",
          "jsonrpc": "2.0",
          "id": 1,
          "data": {
            "usage": "0x021000",
            "summary": {
              "total_connections": "0x00",
              "total_bytes": "0x021000"
            }
          },
          "code": -32001
        }
        """
        let response = try JsonRpc.parseResponse(json)
        XCTAssertNotNil(response.error?.data)

        let client = DiodeRpcClient(wsURL: "wss://example.test/ws")
        let exception = client.ticketRpcException(response, rawResponse: json)

        guard case let .ticketTooLow(_, usage, summary, _, _) = exception else {
            return XCTFail("expected ticketTooLow")
        }
        XCTAssertEqual(usage, 135_168)
        XCTAssertEqual(summary?.totalConnections, 0)
        XCTAssertEqual(summary?.totalBytes, 135_168)
    }

    func testTicketRpcExceptionOther32001StaysInvalidTicket() throws {
        let json = #"{"jsonrpc":"2.0","id":3,"error":{"code":-32001,"message":"epoch number too low"}}"#
        let response = try JsonRpc.parseResponse(json)
        let client = DiodeRpcClient(wsURL: "wss://example.test/ws")
        let exception = client.ticketRpcException(response)

        guard case .invalidTicket = exception else {
            return XCTFail("expected invalidTicket")
        }
    }
}
