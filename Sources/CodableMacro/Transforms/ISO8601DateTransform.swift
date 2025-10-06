import Foundation

/// Date ↔ ISO8601 String 轉換器
public struct ISO8601DateTransform: CodingTransform {
    public typealias SwiftType = Date
    public typealias JSONType = String

    private let formatter: ISO8601DateFormatter

    public init() {
        self.formatter = ISO8601DateFormatter()
    }

    public func encode(_ value: Date) throws -> String {
        return formatter.string(from: value)
    }

    public func decode(_ value: String) throws -> Date {
        guard let date = formatter.date(from: value) else {
            throw TransformError.invalidISO8601Date(value)
        }
        return date
    }
}
