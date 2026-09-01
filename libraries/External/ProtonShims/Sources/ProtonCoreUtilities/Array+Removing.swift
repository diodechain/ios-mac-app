import Foundation

public extension Array where Element: Equatable {
    func removing(_ elements: [Element], if condition: Bool) -> [Element] {
        guard condition else { return self }
        return filter { !elements.contains($0) }
    }

    func removing(_ elements: [Element]) -> [Element] {
        filter { !elements.contains($0) }
    }
}
