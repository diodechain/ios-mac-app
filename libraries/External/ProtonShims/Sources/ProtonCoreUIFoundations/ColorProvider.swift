#if canImport(UIKit)
    import UIKit

    public typealias ProtonIcon = UIImage
    public typealias ProtonColor = UIColor
#elseif canImport(AppKit)
    import AppKit

    public typealias ProtonIcon = NSImage
    public typealias ProtonColor = NSColor
#endif

import SwiftUI

public enum Brand: Sendable {
    case vpn
    case mail
    case drive
    case calendar
    case pass
}

/// Diode-branded palette matching ProtonCore `var ColorProvider` API.
public struct ColorProviderPalette: Sendable {
    public static var brand: Brand = .vpn

    public var BrandNorm: ProtonColor
    public var Primary: ProtonColor
    public var TextAccent: ProtonColor
    public var InteractionNorm: ProtonColor
    public var InteractionNormHover: ProtonColor
    public var InteractionNormActive: ProtonColor
    public var InteractionDefault: ProtonColor
    public var InteractionDefaultHover: ProtonColor
    public var InteractionDefaultActive: ProtonColor
    public var BrandLighten20: ProtonColor
    public var BrandLighten40: ProtonColor
    public var BrandDarken40: ProtonColor
    public var BackgroundSecondary: ProtonColor
    public var BackgroundNorm: ProtonColor
    public var BackgroundWeak: ProtonColor
    public var BackgroundStrong: ProtonColor
    public var BackgroundDeep: ProtonColor
    public var TextWeak: ProtonColor
    public var TextHint: ProtonColor
    public var TextDisabled: ProtonColor
    public var TextInverted: ProtonColor
    public var TextInvert: ProtonColor
    public var TextNorm: ProtonColor
    public var InteractionWeak: ProtonColor
    public var InteractionWeakHover: ProtonColor
    public var InteractionWeakActive: ProtonColor
    public var InteractionStrong: ProtonColor
    public var InteractionNormPressed: ProtonColor
    public var InteractionNormDisabled: ProtonColor
    public var InteractionWeakPressed: ProtonColor
    public var InteractionWeakDisabled: ProtonColor
    public var InteractionStrongPressed: ProtonColor
    public var LinkNorm: ProtonColor
    public var LinkHover: ProtonColor
    public var LinkActive: ProtonColor
    public var SeparatorNorm: ProtonColor
    public var BorderNorm: ProtonColor
    public var BorderWeak: ProtonColor
    public var FieldNorm: ProtonColor
    public var FieldHover: ProtonColor
    public var FieldDisabled: ProtonColor
    public var NotificationWarning: ProtonColor
    public var NotificationSuccess: ProtonColor
    public var NotificationError: ProtonColor
    public var NotificationNorm: ProtonColor
    public var SignalDanger: ProtonColor
    public var SignalDangerHover: ProtonColor
    public var SignalDangerActive: ProtonColor
    public var SignalWarning: ProtonColor
    public var SignalWarningHover: ProtonColor
    public var SignalWarningActive: ProtonColor
    public var SignalSuccess: ProtonColor
    public var SignalSuccessHover: ProtonColor
    public var SignalSuccessActive: ProtonColor
    public var SignalInfo: ProtonColor
    public var SignalInfoHover: ProtonColor
    public var SignalInfoActive: ProtonColor
    public var White: ProtonColor
    public var IconWeak: ProtonColor
    public var IconHint: ProtonColor
    public var IconNorm: ProtonColor
    public var IconAccent: ProtonColor
    public var Shade40: Color
    public var PurpleBase: ProtonColor
    public var PinkBase: ProtonColor
    public var StrawberryBase: ProtonColor
    public var CarrotBase: ProtonColor
    public var SaharaBase: ProtonColor
    public var SlateblueBase: ProtonColor
    public var PacificBase: ProtonColor
    public var ReefBase: ProtonColor
    public var FernBase: ProtonColor
    public var OliveBase: ProtonColor

    public static let diode = ColorProviderPalette()
}

public var ColorProvider = ColorProviderPalette.diode

private extension ColorProviderPalette {
    init() {
        let brand = ProtonColor(protonHex: 0x6B4EFF)
        let brandLight20 = ProtonColor(protonHex: 0x8971FF)
        let brandLight40 = ProtonColor(protonHex: 0xA794FF)
        let brandDark40 = ProtonColor(protonHex: 0x402F99)
        let danger = ProtonColor(protonHex: 0xE74C3C)
        let warning = ProtonColor(protonHex: 0xE8B500)
        let success = ProtonColor(protonHex: 0x1EA97A)
        let info = ProtonColor(protonHex: 0x4A90D9)
        let backgroundNorm = ProtonColor(protonHex: 0x1C1B24)
        let backgroundWeak = ProtonColor(protonHex: 0x26252E)
        let interactionWeak = ProtonColor(protonHex: 0x3A3847)

        BrandNorm = brand
        Primary = brand
        TextAccent = brand
        InteractionNorm = brand
        InteractionNormHover = brandLight20
        InteractionNormActive = brandDark40
        InteractionDefault = interactionWeak
        InteractionDefaultHover = ProtonColor(protonHex: 0x4A4858)
        InteractionDefaultActive = ProtonColor(protonHex: 0x2E2D38)
        BrandLighten20 = brandLight20
        BrandLighten40 = brandLight40
        BrandDarken40 = brandDark40
        BackgroundSecondary = backgroundWeak
        BackgroundNorm = backgroundNorm
        BackgroundWeak = ProtonColor(protonHex: 0x2E2D38)
        BackgroundStrong = ProtonColor(protonHex: 0x121118)
        BackgroundDeep = ProtonColor(protonHex: 0x121118)
        TextNorm = ProtonColor(protonHex: 0xFFFFFF)
        TextWeak = ProtonColor(protonHex: 0xB0AEC0)
        TextHint = ProtonColor(protonHex: 0x7A778A)
        TextDisabled = ProtonColor(protonHex: 0x5C596B)
        TextInverted = backgroundNorm
        TextInvert = backgroundNorm
        InteractionWeak = interactionWeak
        InteractionWeakHover = ProtonColor(protonHex: 0x4A4858)
        InteractionWeakActive = ProtonColor(protonHex: 0x2E2D38)
        InteractionStrong = brandLight20
        InteractionNormPressed = brandDark40
        InteractionNormDisabled = interactionWeak
        InteractionWeakPressed = ProtonColor(protonHex: 0x4A4858)
        InteractionWeakDisabled = ProtonColor(protonHex: 0x2E2D38)
        InteractionStrongPressed = brandDark40
        LinkNorm = brand
        LinkHover = brandLight20
        LinkActive = brandDark40
        SeparatorNorm = interactionWeak
        BorderNorm = interactionWeak
        BorderWeak = ProtonColor(protonHex: 0x2E2D38)
        FieldNorm = backgroundWeak
        FieldHover = ProtonColor(protonHex: 0x2E2D38)
        FieldDisabled = ProtonColor(protonHex: 0x1C1B24)
        NotificationSuccess = success
        NotificationWarning = warning
        NotificationError = danger
        NotificationNorm = info
        SignalDanger = danger
        SignalDangerHover = ProtonColor(protonHex: 0xF06A5C)
        SignalDangerActive = ProtonColor(protonHex: 0xC0392B)
        SignalWarning = warning
        SignalWarningHover = ProtonColor(protonHex: 0xF0C94A)
        SignalWarningActive = ProtonColor(protonHex: 0xC99700)
        SignalSuccess = success
        SignalSuccessHover = ProtonColor(protonHex: 0x3BC99A)
        SignalSuccessActive = ProtonColor(protonHex: 0x168A62)
        SignalInfo = info
        SignalInfoHover = ProtonColor(protonHex: 0x6AA8E8)
        SignalInfoActive = ProtonColor(protonHex: 0x2F6FB8)
        #if canImport(UIKit)
            White = UIColor.white
        #else
            White = NSColor.white
        #endif
        IconWeak = ProtonColor(protonHex: 0x7A778A)
        IconHint = ProtonColor(protonHex: 0x5C596B)
        IconNorm = ProtonColor(protonHex: 0xFFFFFF)
        IconAccent = brand
        Shade40 = Color(protonHex: 0x3A3847)
        PurpleBase = ProtonColor(protonHex: 0x6B4EFF)
        PinkBase = ProtonColor(protonHex: 0xE056FD)
        StrawberryBase = ProtonColor(protonHex: 0xF46B7D)
        CarrotBase = ProtonColor(protonHex: 0xF5833A)
        SaharaBase = ProtonColor(protonHex: 0xE8B500)
        SlateblueBase = ProtonColor(protonHex: 0x5B6EE1)
        PacificBase = ProtonColor(protonHex: 0x2D9CDB)
        ReefBase = ProtonColor(protonHex: 0x1EA97A)
        FernBase = ProtonColor(protonHex: 0x4CD964)
        OliveBase = ProtonColor(protonHex: 0x8BC34A)
    }
}

private extension ProtonColor {
    convenience init(protonHex hex: UInt32, alpha: CGFloat = 1) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255
        let green = CGFloat((hex >> 8) & 0xFF) / 255
        let blue = CGFloat(hex & 0xFF) / 255
        #if canImport(UIKit)
            self.init(red: red, green: green, blue: blue, alpha: alpha)
        #else
            self.init(srgbRed: red, green: green, blue: blue, alpha: alpha)
        #endif
    }
}

private extension Color {
    init(protonHex hex: UInt32, alpha: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(red: red, green: green, blue: blue, opacity: alpha)
    }
}
