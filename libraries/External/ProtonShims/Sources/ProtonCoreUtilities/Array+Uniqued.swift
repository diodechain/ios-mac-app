import Foundation

public extension Array {
    func appending(_ element: Element) -> [Element] {
        self + [element]
    }

    func appending(_ elements: [Element]) -> [Element] {
        self + elements
    }

    func appending(_ element: Element, if condition: Bool) -> [Element] {
        condition ? appending(element) : self
    }

    func appending(_ elements: [Element], if condition: Bool) -> [Element] {
        condition ? appending(elements) : self
    }

    func appending(@ArrayBuilder<Element> _ builder: () -> [Element], if condition: Bool) -> [Element] {
        condition ? appending(builder()) : self
    }
}

@resultBuilder
public enum ArrayBuilder<Element> {
    public static func buildBlock(_ components: Element...) -> [Element] {
        components
    }

    public static func buildBlock(_ components: [Element]...) -> [Element] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [Element]?) -> [Element] {
        component ?? []
    }

    public static func buildEither(first component: [Element]) -> [Element] {
        component
    }

    public static func buildEither(second component: [Element]) -> [Element] {
        component
    }
}

public extension Array where Element: Hashable {
    var uniqued: [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

public extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        Array(self).uniqued
    }
}
