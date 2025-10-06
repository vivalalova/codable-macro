import Foundation

/// UUID ↔ String 轉換器
public struct UUIDTransform: CodingTransform {
    public typealias SwiftType = UUID
    public typealias JSONType = String

    public init() {}

    public func encode(_ value: UUID) throws -> String {
        return value.uuidString
    }

    public func decode(_ value: String) throws -> UUID {
        guard let uuid = UUID(uuidString: value) else {
            throw TransformError.invalidUUID(value)
        }
        return uuid
    }
}
