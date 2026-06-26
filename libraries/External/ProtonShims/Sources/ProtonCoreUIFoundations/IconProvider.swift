#if canImport(UIKit)
    import SwiftUI
    import UIKit
#elseif canImport(AppKit)
    import AppKit
    import SwiftUI
#endif

public struct ProtonIconSet: Sendable {
    public let alias: ProtonIcon
    public let arrowsLeftRight: ProtonIcon
    public let arrowInToRectangle: ProtonIcon
    public let arrowLeft: ProtonIcon
    public let arrowOutFromRectangle: ProtonIcon
    public let arrowOutSquare: ProtonIcon
    public let arrowRight: ProtonIcon
    public let arrowRightArrowLeft: ProtonIcon
    public let arrowRotateRight: ProtonIcon
    public let arrowsSwapRight: ProtonIcon
    public let arrowsSwitch: ProtonIcon
    public let bell: ProtonIcon
    public let bolt: ProtonIcon
    public let brandTor: ProtonIcon
    public let bug: ProtonIcon
    public let calendarMainTransparent: ProtonIcon
    public let chartLine: ProtonIcon
    public let checkmark: ProtonIcon
    public let checkmarkCircleFilled: ProtonIcon
    public let chevronDownFilled: ProtonIcon
    public let chevronLeft: ProtonIcon
    public let chevronRight: ProtonIcon
    public let chevronRightFilled: ProtonIcon
    public let chevronsRight: ProtonIcon
    public let circleHalfFilled: ProtonIcon
    public let circleSlash: ProtonIcon
    public let clockRotateLeft: ProtonIcon
    public let code: ProtonIcon
    public let cogWheel: ProtonIcon
    public let cross: ProtonIcon
    public let crossBig: ProtonIcon
    public let crossCircleFilled: ProtonIcon
    public let driveMainTransparent: ProtonIcon
    public let earth: ProtonIcon
    public let emptyCircle: ProtonIcon
    public let eye: ProtonIcon
    public let eyeSlash: ProtonIcon
    public let fileEmpty: ProtonIcon
    public let gift: ProtonIcon
    public let globe: ProtonIcon
    public let grid2: ProtonIcon
    public let hourglass: ProtonIcon
    public let house: ProtonIcon
    public let houseFilled: ProtonIcon
    public let infoCircle: ProtonIcon
    public let infoCircleFilled: ProtonIcon
    public let keySkeleton: ProtonIcon
    public let lifeRing: ProtonIcon
    public let lock: ProtonIcon
    public let lockFilled: ProtonIcon
    public let lockLayers: ProtonIcon
    public let lockOpen: ProtonIcon
    public let lockOpenFilled: ProtonIcon
    public let lockOpenFilled2: ProtonIcon
    public let locks: ProtonIcon
    public let locksFilled: ProtonIcon
    public let magicWand: ProtonIcon
    public let magnifier: ProtonIcon
    public let mailMainTransparent: ProtonIcon
    public let mapPin: ProtonIcon
    public let minusCircle: ProtonIcon
    public let passMainTransparent: ProtonIcon
    public let pinFilled: ProtonIcon
    public let pinSlashFilled: ProtonIcon
    public let play: ProtonIcon
    public let plusCircle: ProtonIcon
    public let powerOff: ProtonIcon
    public let printer: ProtonIcon
    public let questionCircle: ProtonIcon
    public let rocket: ProtonIcon
    public let servers: ProtonIcon
    public let shield: ProtonIcon
    public let shieldFilled: ProtonIcon
    public let shieldHalfFilled: ProtonIcon
    public let sidePanelLeft: ProtonIcon
    public let sliders: ProtonIcon
    public let speechBubble: ProtonIcon
    public let squares: ProtonIcon
    public let star: ProtonIcon
    public let threeDotsHorizontal: ProtonIcon
    public let threeDotsVertical: ProtonIcon
    public let trashCross: ProtonIcon
    public let trashCrossFilled: ProtonIcon
    public let user: ProtonIcon
    public let userCircle: ProtonIcon
    public let users: ProtonIcon
    public let windowTerminal: ProtonIcon
    public let wrench: ProtonIcon

    public init() {
        let placeholder = ProtonIcon.placeholder()
        alias = placeholder
        arrowsLeftRight = placeholder
        arrowInToRectangle = placeholder
        arrowLeft = placeholder
        arrowOutFromRectangle = placeholder
        arrowOutSquare = placeholder
        arrowRight = placeholder
        arrowRightArrowLeft = placeholder
        arrowRotateRight = placeholder
        arrowsSwapRight = placeholder
        arrowsSwitch = placeholder
        bell = placeholder
        bolt = placeholder
        brandTor = placeholder
        bug = placeholder
        calendarMainTransparent = placeholder
        chartLine = placeholder
        checkmark = placeholder
        checkmarkCircleFilled = placeholder
        chevronDownFilled = placeholder
        chevronLeft = placeholder
        chevronRight = placeholder
        chevronRightFilled = placeholder
        chevronsRight = placeholder
        circleHalfFilled = placeholder
        circleSlash = placeholder
        clockRotateLeft = placeholder
        code = placeholder
        cogWheel = placeholder
        cross = placeholder
        crossBig = placeholder
        crossCircleFilled = placeholder
        driveMainTransparent = placeholder
        earth = placeholder
        emptyCircle = placeholder
        eye = placeholder
        eyeSlash = placeholder
        fileEmpty = placeholder
        gift = placeholder
        globe = placeholder
        grid2 = placeholder
        hourglass = placeholder
        house = placeholder
        houseFilled = placeholder
        infoCircle = placeholder
        infoCircleFilled = placeholder
        keySkeleton = placeholder
        lifeRing = placeholder
        lock = placeholder
        lockFilled = placeholder
        lockLayers = placeholder
        lockOpen = placeholder
        lockOpenFilled = placeholder
        lockOpenFilled2 = placeholder
        locks = placeholder
        locksFilled = placeholder
        magicWand = placeholder
        magnifier = placeholder
        mailMainTransparent = placeholder
        mapPin = placeholder
        minusCircle = placeholder
        passMainTransparent = placeholder
        pinFilled = placeholder
        pinSlashFilled = placeholder
        play = placeholder
        plusCircle = placeholder
        powerOff = placeholder
        printer = placeholder
        questionCircle = placeholder
        rocket = placeholder
        servers = placeholder
        shield = placeholder
        shieldFilled = placeholder
        shieldHalfFilled = placeholder
        sidePanelLeft = placeholder
        sliders = placeholder
        speechBubble = placeholder
        squares = placeholder
        star = placeholder
        threeDotsHorizontal = placeholder
        threeDotsVertical = placeholder
        trashCross = placeholder
        trashCrossFilled = placeholder
        user = placeholder
        userCircle = placeholder
        users = placeholder
        windowTerminal = placeholder
        wrench = placeholder
    }
}

@dynamicMemberLookup
public struct IconProviderPalette: Sendable {
    private let icons = ProtonIconSet()

    public subscript(dynamicMember keyPath: KeyPath<ProtonIconSet, ProtonIcon>) -> ProtonIcon {
        icons[keyPath: keyPath]
    }

    public func flag(forCountryCode _: String) -> ProtonIcon? {
        ProtonIcon.placeholder()
    }
}

public let IconProvider = IconProviderPalette()

#if canImport(UIKit)
    extension UIImage {
        static func placeholder() -> UIImage {
            let size = CGSize(width: 24, height: 24)
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { context in
                UIColor(red: 107 / 255, green: 78 / 255, blue: 255 / 255, alpha: 1).setFill()
                context.fill(CGRect(origin: .zero, size: size))
            }
        }
    }

    extension UIImage {
        public var swiftUIImage: Image {
            Image(uiImage: self)
        }

        public func resizable() -> Image {
            swiftUIImage.resizable()
        }
    }
#elseif canImport(AppKit)
    extension NSImage {
        static func placeholder() -> NSImage {
            let image = NSImage(size: NSSize(width: 24, height: 24))
            image.lockFocus()
            NSColor(red: 107 / 255, green: 78 / 255, blue: 255 / 255, alpha: 1).setFill()
            NSRect(x: 0, y: 0, width: 24, height: 24).fill()
            image.unlockFocus()
            return image
        }
    }

    extension NSImage {
        public var swiftUIImage: Image {
            Image(nsImage: self)
        }

        public func resizable() -> Image {
            swiftUIImage.resizable()
        }
    }
#endif
