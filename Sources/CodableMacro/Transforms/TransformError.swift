import Foundation

/// 轉換錯誤
public enum TransformError: Error, CustomStringConvertible {
    case invalidURL(String)
    case invalidUUID(String)
    case invalidISO8601Date(String)
    case invalidBoolInt(Int)
    case invalidValue
    case encodingFailed(Error)
    case decodingFailed(Error)

    public var description: String {
        switch self {
        case .invalidURL(let value):
            return "Invalid URL string: \(value)"
        case .invalidUUID(let value):
            return "Invalid UUID string: \(value)"
        case .invalidISO8601Date(let value):
            return "Invalid ISO8601 date string: \(value)"
        case .invalidBoolInt(let value):
            return "Invalid Bool Int value (expected 0 or 1): \(value)"
        case .invalidValue:
            return "Invalid value for transformation"
        case .encodingFailed(let error):
            return "Encoding failed: \(error)"
        case .decodingFailed(let error):
            return "Decoding failed: \(error)"
        }
    }
}
