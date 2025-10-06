import Foundation

/// URL ↔ String 轉換器
public struct URLTransform: CodingTransform {
    public typealias SwiftType = URL
    public typealias JSONType = String

    public init() {}

    public func encode(_ value: URL) throws -> String {
        return value.absoluteString
    }

    public func decode(_ value: String) throws -> URL {
        guard let url = URL(string: value) else {
            throw TransformError.invalidURL(value)
        }
        return url
    }
}
