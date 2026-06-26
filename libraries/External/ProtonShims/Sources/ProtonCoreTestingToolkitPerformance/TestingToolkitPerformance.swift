import Foundation

public enum MeasurementConfig {
    public static var product: String = "vpn"

    @discardableResult
    public static func setProduct(_ product: String) -> MeasurementConfig.Type {
        self.product = product
        return self
    }
}
