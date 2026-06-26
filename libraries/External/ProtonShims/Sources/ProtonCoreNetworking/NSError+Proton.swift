import Foundation

public extension NSError {
    var httpCode: Int {
        (userInfo["HttpCode"] as? Int) ?? (userInfo[NSLocalizedDescriptionKey] as? Int) ?? code
    }

    var responseCode: Int {
        (userInfo["ResponseCode"] as? Int) ?? code
    }
}

public extension Error {
    var responseCode: Int {
        if let responseError = self as? ResponseError {
            switch responseError {
            case let .apiError(_, responseCode, _, _):
                return responseCode
            case let .generic(_, code, _):
                return code
            case let .httpError(code, _):
                return code
            case .unknownError:
                return 0
            }
        }
        return (self as NSError).responseCode
    }
}
