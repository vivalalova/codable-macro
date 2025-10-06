import Foundation

/// Bool ↔ Int (0/1) 轉換器
public struct BoolIntTransform: CodingTransform {
    public typealias SwiftType = Bool
    public typealias JSONType = Int

    public init() {}

    public func encode(_ value: Bool) throws -> Int {
        return value ? 1 : 0
    }

    public func decode(_ value: Int) throws -> Bool {
        guard value == 0 || value == 1 else {
            throw TransformError.invalidBoolInt(value)
        }
        return value == 1
    }
}
