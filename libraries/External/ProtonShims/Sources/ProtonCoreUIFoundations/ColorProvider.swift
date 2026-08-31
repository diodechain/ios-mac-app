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
    public var brand: Brand {
        get { Self.sharedBrand }
        nonmutating set { Self.sharedBrand = newValue }
    }

    private static var sharedBrand: Brand = .vpn

    public static var brand: Brand {
        get { sharedBrand }
        set { sharedBrand = newValue }
    }

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
        // Diode brand tokens from diode_vpn_android colors.xml / docs/design.md
        let brand = ProtonColor(protonHex: 0xF15D2F) // diode_orange
        let brandLight20 = ProtonColor(protonHex: 0xF5835A)
        let brandLight40 = ProtonColor(protonHex: 0xF9A88A)
        let brandDark40 = ProtonColor(protonHex: 0xED4423) // diode_orange_dark
        let danger = ProtonColor(protonHex: 0xEF4444) // diode_error
        let warning = ProtonColor(protonHex: 0xE8B500)
        let success = ProtonColor(protonHex: 0x1EA97A)
        let info = ProtonColor(protonHex: 0x2D3E50) // diode_web_blue
        let backgroundNorm = ProtonColor(protonHex: 0x161C2A) // diode_black_blue
        let backgroundWeak = ProtonColor(protonHex: 0x1E2739) // diode_indigo
        let interactionWeak = ProtonColor(protonHex: 0x3D4F6B) // diode_outline
        let surfaceElevated = ProtonColor(protonHex: 0x232D42) // diode_surface_elevated
        let onSurface = ProtonColor(protonHex: 0xE3E9ED)
        let onSurfaceSecondary = ProtonColor(protonHex: 0xBDC3C7)
        let accentDark = ProtonColor(protonHex: 0x243141)

        BrandNorm = brand
        Primary = brand
        TextAccent = brand
        InteractionNorm = brand
        InteractionNormHover = brandLight20
        InteractionNormActive = brandDark40
        InteractionDefault = interactionWeak
        InteractionDefaultHover = ProtonColor(protonHex: 0x4A5F7A)
        InteractionDefaultActive = accentDark
        BrandLighten20 = brandLight20
        BrandLighten40 = brandLight40
        BrandDarken40 = brandDark40
        BackgroundSecondary = backgroundWeak
        BackgroundNorm = backgroundNorm
        BackgroundWeak = surfaceElevated
        BackgroundStrong = ProtonColor(protonHex: 0x12161F)
        BackgroundDeep = ProtonColor(protonHex: 0x12161F)
        TextNorm = ProtonColor(protonHex: 0xF1F3F6) // diode_on_background
        TextWeak = onSurfaceSecondary
        TextHint = ProtonColor(protonHex: 0x5C5D5F) // diode_gray_muted
        TextDisabled = ProtonColor(protonHex: 0x5C5D5F)
        TextInverted = backgroundNorm
        TextInvert = backgroundNorm
        InteractionWeak = interactionWeak
        InteractionWeakHover = ProtonColor(protonHex: 0x4A5F7A)
        InteractionWeakActive = accentDark
        InteractionStrong = brandLight20
        InteractionNormPressed = brandDark40
        InteractionNormDisabled = interactionWeak
        InteractionWeakPressed = ProtonColor(protonHex: 0x4A5F7A)
        InteractionWeakDisabled = accentDark
        InteractionStrongPressed = brandDark40
        LinkNorm = brand
        LinkHover = brandLight20
        LinkActive = brandDark40
        SeparatorNorm = interactionWeak
        BorderNorm = interactionWeak
        BorderWeak = accentDark
        FieldNorm = backgroundWeak
        FieldHover = surfaceElevated
        FieldDisabled = backgroundNorm
        NotificationSuccess = success
        NotificationWarning = warning
        NotificationError = danger
        NotificationNorm = info
        SignalDanger = danger
        SignalDangerHover = ProtonColor(protonHex: 0xF87171)
        SignalDangerActive = ProtonColor(protonHex: 0xDC2626)
        SignalWarning = warning
        SignalWarningHover = ProtonColor(protonHex: 0xF0C94A)
        SignalWarningActive = ProtonColor(protonHex: 0xC99700)
        SignalSuccess = success
        SignalSuccessHover = ProtonColor(protonHex: 0x3BC99A)
        SignalSuccessActive = ProtonColor(protonHex: 0x168A62)
        SignalInfo = info
        SignalInfoHover = ProtonColor(protonHex: 0x3D5268)
        SignalInfoActive = ProtonColor(protonHex: 0x1F2A38)
        #if canImport(UIKit)
            White = UIColor.white
        #else
            White = NSColor.white
        #endif
        IconWeak = onSurfaceSecondary
        IconHint = ProtonColor(protonHex: 0x5C5D5F)
        IconNorm = onSurface
        IconAccent = brand
        Shade40 = Color(protonHex: 0x3D4F6B)
        PurpleBase = brand
        PinkBase = ProtonColor(protonHex: 0xE056FD)
        StrawberryBase = ProtonColor(protonHex: 0xF46B7D)
        CarrotBase = brand
        SaharaBase = ProtonColor(protonHex: 0xE8B500)
        SlateblueBase = info
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
