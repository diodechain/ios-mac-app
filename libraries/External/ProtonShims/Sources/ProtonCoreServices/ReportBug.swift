import Foundation

public enum APIErrorCode {
    public static let potentiallyBlocked = 4510
    public static let switchToSSOError = 202_000
}

public struct ReportBug: Sendable {
    public let os: String
    public let osVersion: String
    public let client: String
    public let clientVersion: String
    public let clientType: Int
    public let title: String
    public let description: String
    public let username: String
    public let email: String
    public let country: String
    public let ISP: String
    public let plan: String
    public var files: [URL]

    public init(
        os: String,
        osVersion: String,
        client: String,
        clientVersion: String,
        clientType: Int,
        title: String,
        description: String,
        username: String,
        email: String,
        country: String,
        ISP: String,
        plan: String,
        files: [URL] = []
    ) {
        self.os = os
        self.osVersion = osVersion
        self.client = client
        self.clientVersion = clientVersion
        self.clientType = clientType
        self.title = title
        self.description = description
        self.username = username
        self.email = email
        self.country = country
        self.ISP = ISP
        self.plan = plan
        self.files = files
    }
}
