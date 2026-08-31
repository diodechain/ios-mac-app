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
    public let arrowDown: ProtonIcon
    public let arrowLeft: ProtonIcon
    public let arrowOutFromRectangle: ProtonIcon
    public let arrowOutSquare: ProtonIcon
    public let arrowRight: ProtonIcon
    public let arrowRightArrowLeft: ProtonIcon
    public let arrowRotateRight: ProtonIcon
    public let arrowUp: ProtonIcon
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
    public let crossSmall: ProtonIcon
    public let driveMainTransparent: ProtonIcon
    public let earth: ProtonIcon
    public let emptyCircle: ProtonIcon
    public let exclamationCircleFilled: ProtonIcon
    public let exclamationTriangleFilled: ProtonIcon
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
    public let plus: ProtonIcon
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
    public let switchOff: ProtonIcon
    public let switchOn: ProtonIcon
    public let threeDotsHorizontal: ProtonIcon
    public let threeDotsVertical: ProtonIcon
    public let trashCross: ProtonIcon
    public let trashCrossFilled: ProtonIcon
    public let user: ProtonIcon
    public let userCircle: ProtonIcon
    public let users: ProtonIcon
    public let vpnMainTransparent: ProtonIcon
    public let windowTerminal: ProtonIcon
    public let wrench: ProtonIcon
    public let minus: ProtonIcon
    public let arrowUpBounceLeft: ProtonIcon

    public init() {
        alias = Self.symbol("a.circle.fill")
        arrowsLeftRight = Self.symbol("arrow.left.arrow.right")
        arrowInToRectangle = Self.symbol("rectangle.portrait.and.arrow.right")
        arrowDown = Self.symbol("arrow.down")
        arrowLeft = Self.symbol("chevron.left")
        arrowOutFromRectangle = Self.symbol("rectangle.portrait.and.arrow.right")
        arrowOutSquare = Self.symbol("arrow.up.forward.square")
        arrowRight = Self.symbol("chevron.right")
        arrowRightArrowLeft = Self.symbol("arrow.right.arrow.left")
        arrowRotateRight = Self.symbol("arrow.clockwise")
        arrowUp = Self.symbol("arrow.up")
        arrowsSwapRight = Self.symbol("arrow.triangle.swap")
        arrowsSwitch = Self.symbol("arrow.triangle.2.circlepath")
        bell = Self.symbol("bell.fill")
        bolt = Self.symbol("bolt.fill")
        brandTor = Self.symbol("network")
        bug = Self.symbol("ant.fill")
        calendarMainTransparent = Self.symbol("calendar")
        chartLine = Self.symbol("chart.line.uptrend.xyaxis")
        checkmark = Self.symbol("checkmark")
        checkmarkCircleFilled = Self.symbol("checkmark.circle.fill")
        chevronDownFilled = Self.symbol("chevron.down")
        chevronLeft = Self.symbol("chevron.left")
        chevronRight = Self.symbol("chevron.right")
        chevronRightFilled = Self.symbol("chevron.right")
        chevronsRight = Self.symbol("chevron.right.2")
        circleHalfFilled = Self.symbol("circle.lefthalf.filled")
        circleSlash = Self.symbol("circle.slash")
        clockRotateLeft = Self.symbol("clock.arrow.circlepath")
        code = Self.symbol("chevron.left.forwardslash.chevron.right")
        cogWheel = Self.symbol("gearshape.fill")
        cross = Self.symbol("xmark")
        crossBig = Self.symbol("xmark")
        crossCircleFilled = Self.symbol("xmark.circle.fill")
        crossSmall = Self.symbol("xmark")
        driveMainTransparent = Self.symbol("externaldrive.fill")
        earth = Self.symbol("globe.americas.fill")
        emptyCircle = Self.symbol("circle")
        exclamationCircleFilled = Self.symbol("exclamationmark.circle.fill")
        exclamationTriangleFilled = Self.symbol("exclamationmark.triangle.fill")
        eye = Self.symbol("eye.fill")
        eyeSlash = Self.symbol("eye.slash.fill")
        fileEmpty = Self.symbol("doc")
        gift = Self.symbol("gift.fill")
        globe = Self.symbol("globe")
        grid2 = Self.symbol("square.grid.2x2.fill")
        hourglass = Self.symbol("hourglass")
        house = Self.symbol("house")
        houseFilled = Self.symbol("house.fill")
        infoCircle = Self.symbol("info.circle")
        infoCircleFilled = Self.symbol("info.circle.fill")
        keySkeleton = Self.symbol("key.fill")
        lifeRing = Self.symbol("lifepreserver")
        lock = Self.symbol("lock")
        lockFilled = Self.symbol("lock.fill")
        lockLayers = Self.symbol("lock.square.stack.fill")
        lockOpen = Self.symbol("lock.open")
        lockOpenFilled = Self.symbol("lock.open.fill")
        lockOpenFilled2 = Self.symbol("lock.open.fill")
        locks = Self.symbol("lock.square.stack")
        locksFilled = Self.symbol("lock.square.stack.fill")
        magicWand = Self.symbol("wand.and.stars")
        magnifier = Self.symbol("magnifyingglass")
        mailMainTransparent = Self.symbol("envelope")
        mapPin = Self.symbol("mappin")
        minusCircle = Self.symbol("minus.circle")
        passMainTransparent = Self.symbol("key.horizontal")
        pinFilled = Self.symbol("pin.fill")
        pinSlashFilled = Self.symbol("pin.slash.fill")
        play = Self.symbol("play.fill")
        plusCircle = Self.symbol("plus.circle")
        powerOff = Self.symbol("power")
        plus = Self.symbol("plus")
        printer = Self.symbol("printer")
        questionCircle = Self.symbol("questionmark.circle")
        rocket = Self.symbol("airplane")
        servers = Self.symbol("server.rack")
        shield = Self.symbol("shield")
        shieldFilled = Self.symbol("shield.fill")
        shieldHalfFilled = Self.symbol("shield.lefthalf.filled")
        sidePanelLeft = Self.symbol("sidebar.left")
        sliders = Self.symbol("slider.horizontal.3")
        speechBubble = Self.symbol("bubble.left")
        squares = Self.symbol("square.on.square")
        star = Self.symbol("star.fill")
        switchOff = Self.symbol("togglepower")
        switchOn = Self.symbol("switch.2")
        threeDotsHorizontal = Self.symbol("ellipsis")
        threeDotsVertical = Self.symbol("ellipsis.vertical")
        trashCross = Self.symbol("trash")
        trashCrossFilled = Self.symbol("trash.fill")
        user = Self.symbol("person")
        userCircle = Self.symbol("person.circle")
        users = Self.symbol("person.2")
        vpnMainTransparent = Self.symbol("shield.lefthalf.filled")
        windowTerminal = Self.symbol("terminal")
        wrench = Self.symbol("wrench.adjustable")
        minus = Self.symbol("minus")
        arrowUpBounceLeft = Self.symbol("arrow.uturn.backward")
    }

    private static func symbol(_ name: String) -> ProtonIcon {
        #if canImport(UIKit)
        if let image = UIImage(systemName: name) {
            return image.withTintColor(
                UIColor(red: 241 / 255, green: 93 / 255, blue: 47 / 255, alpha: 1),
                renderingMode: .alwaysOriginal
            )
        }
        #elseif canImport(AppKit)
        if let image = NSImage(systemSymbolName: name, accessibilityDescription: nil) {
            let config = NSImage.SymbolConfiguration(paletteColors: [
                NSColor(red: 241 / 255, green: 93 / 255, blue: 47 / 255, alpha: 1),
            ])
            return image.withSymbolConfiguration(config) ?? image
        }
        #endif
        return ProtonIcon.placeholder()
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

public extension Image {
    init(_ icon: ProtonIcon) {
        #if canImport(UIKit)
        self.init(uiImage: icon)
        #elseif canImport(AppKit)
        self.init(nsImage: icon)
        #endif
    }
}

#if canImport(UIKit)
    extension UIImage {
        static func placeholder() -> UIImage {
            let size = CGSize(width: 24, height: 24)
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { context in
                // Diode orange placeholder until named assets replace glyphs.
                UIColor(red: 241 / 255, green: 93 / 255, blue: 47 / 255, alpha: 1).setFill()
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
            // Diode orange placeholder until named assets replace glyphs.
            NSColor(red: 241 / 255, green: 93 / 255, blue: 47 / 255, alpha: 1).setFill()
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
