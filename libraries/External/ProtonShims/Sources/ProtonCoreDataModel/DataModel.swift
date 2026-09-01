import Foundation

public struct User: Codable, Sendable {
    public var ID: String = ""
    public var displayName: String?
    public var email: String?
    public var role: Int?
    public var maxSpace: Int64?
    public var maxBaseSpace: Int64?
    public var maxDriveSpace: Int64?
    public var usedSpace: Int64?
    public var usedBaseSpace: Int64?
    public var usedDriveSpace: Int64?
    public var maxUpload: Int64?
    public var delinquent: Int?
    public var keys: [UserKey]?
    public var credit: Int?
    public var currency: String?
    public var createTime: Int?
    public var accountRecovery: AccountRecovery?
    public var subscribed: Int?
    public var edmOptOut: Int?

    public init() {}
}

public struct UserKey: Codable, Sendable {
    public init() {}
}

public struct Address: Codable, Sendable {
    public var ID: String = ""
    public var Email: String = ""
    public var Status: Int?
    public var `Type`: Int?
    public var Order: Int?
    public var DisplayName: String?
    public var Signature: String?
    public var Send: Int?
    public var Receive: Int?

    public init() {}
}

public struct AccountRecovery: Codable, Sendable {
    public var state: Int?
    public var reason: Int?
    public var startTime: Int?
    public var endTime: Int?
    public var UID: String?

    public init() {}
}

public struct UserInfo: Sendable {
    public var displayName: String?
    public var hideEmbeddedImages: Bool?
    public var hideRemoteImages: Bool?
    public var imageProxy: Int?
    public var maxSpace: Int64?
    public var maxBaseSpace: Int64?
    public var maxDriveSpace: Int64?
    public var notificationEmail: String?
    public var signature: String?
    public var usedSpace: Int64?
    public var usedBaseSpace: Int64?
    public var usedDriveSpace: Int64?
    public var userAddresses: [Address]
    public var autoSC: Int?
    public var language: String?
    public var maxUpload: Int64?
    public var notify: Int?
    public var swipeLeft: Int?
    public var swipeRight: Int?
    public var role: Int?
    public var delinquent: Int?
    public var keys: [UserKey]?
    public var userId: String?
    public var sign: Int?
    public var attachPublicKey: Int?
    public var linkConfirmation: Int?
    public var credit: Int?
    public var currency: String?
    public var createTime: Int64?
    public var pwdMode: Int?
    public var twoFA: Int?
    public var enableFolderColor: Int?
    public var inheritParentFolderColor: Int?
    public var passwordMode: Int?
    public var twoFactor: Int?
    public var subscribed: Int?
    public var groupingMode: Int?
    public var weekStart: Int?
    public var delaySendSeconds: Int?
    public var telemetry: Int?
    public var crashReports: Int?
    public var conversationToolbarActions: String?
    public var messageToolbarActions: String?
    public var listToolbarActions: String?
    public var referralProgram: Int?
    public var edmOptOut: Int?

    public init(
        displayName: String? = nil,
        hideEmbeddedImages: Bool? = nil,
        hideRemoteImages: Bool? = nil,
        imageProxy: Int? = nil,
        maxSpace: Int64? = nil,
        maxBaseSpace: Int64? = nil,
        maxDriveSpace: Int64? = nil,
        notificationEmail: String? = nil,
        signature: String? = nil,
        usedSpace: Int64? = nil,
        usedBaseSpace: Int64? = nil,
        usedDriveSpace: Int64? = nil,
        userAddresses: [Address] = [],
        autoSC: Int? = nil,
        language: String? = nil,
        maxUpload: Int64? = nil,
        notify: Int? = nil,
        swipeLeft: Int? = nil,
        swipeRight: Int? = nil,
        role: Int? = nil,
        delinquent: Int? = nil,
        keys: [UserKey]? = nil,
        userId: String? = nil,
        sign: Int? = nil,
        attachPublicKey: Int? = nil,
        linkConfirmation: Int? = nil,
        credit: Int? = nil,
        currency: String? = nil,
        createTime: Int64? = nil,
        pwdMode: Int? = nil,
        twoFA: Int? = nil,
        enableFolderColor: Int? = nil,
        inheritParentFolderColor: Int? = nil,
        passwordMode: Int? = nil,
        twoFactor: Int? = nil,
        subscribed: Int? = nil,
        groupingMode: Int? = nil,
        weekStart: Int? = nil,
        delaySendSeconds: Int? = nil,
        telemetry: Int? = nil,
        crashReports: Int? = nil,
        conversationToolbarActions: String? = nil,
        messageToolbarActions: String? = nil,
        listToolbarActions: String? = nil,
        referralProgram: Int? = nil,
        edmOptOut: Int? = nil
    ) {
        self.displayName = displayName
        self.hideEmbeddedImages = hideEmbeddedImages
        self.hideRemoteImages = hideRemoteImages
        self.imageProxy = imageProxy
        self.maxSpace = maxSpace
        self.maxBaseSpace = maxBaseSpace
        self.maxDriveSpace = maxDriveSpace
        self.notificationEmail = notificationEmail
        self.signature = signature
        self.usedSpace = usedSpace
        self.usedBaseSpace = usedBaseSpace
        self.usedDriveSpace = usedDriveSpace
        self.userAddresses = userAddresses
        self.autoSC = autoSC
        self.language = language
        self.maxUpload = maxUpload
        self.notify = notify
        self.swipeLeft = swipeLeft
        self.swipeRight = swipeRight
        self.role = role
        self.delinquent = delinquent
        self.keys = keys
        self.userId = userId
        self.sign = sign
        self.attachPublicKey = attachPublicKey
        self.linkConfirmation = linkConfirmation
        self.credit = credit
        self.currency = currency
        self.createTime = createTime
        self.pwdMode = pwdMode
        self.twoFA = twoFA
        self.enableFolderColor = enableFolderColor
        self.inheritParentFolderColor = inheritParentFolderColor
        self.passwordMode = passwordMode
        self.twoFactor = twoFactor
        self.subscribed = subscribed
        self.groupingMode = groupingMode
        self.weekStart = weekStart
        self.delaySendSeconds = delaySendSeconds
        self.telemetry = telemetry
        self.crashReports = crashReports
        self.conversationToolbarActions = conversationToolbarActions
        self.messageToolbarActions = messageToolbarActions
        self.listToolbarActions = listToolbarActions
        self.referralProgram = referralProgram
        self.edmOptOut = edmOptOut
    }
}
