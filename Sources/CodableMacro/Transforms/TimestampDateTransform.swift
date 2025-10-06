import Foundation

/// Date ↔ Unix Timestamp (Double) 轉換器
public struct TimestampDateTransform: CodingTransform {
    public typealias SwiftType = Date
    public typealias JSONType = Double

    public init() {}

    public func encode(_ value: Date) throws -> Double {
        return value.timeIntervalSince1970
    }

    public func decode(_ value: Double) throws -> Date {
        return Date(timeIntervalSince1970: value)
    }
}
