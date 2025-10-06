import Foundation

/// 型別轉換器參數
///
/// 用於 @CodingKey macro 的 transform 參數，提供型別安全的轉換器選擇。
///
/// 使用範例：
/// ```swift
/// @Codable
/// struct Message {
///     @CodingKey("endpoint", transform: .url)
///     let endpoint: URL
/// }
/// ```
///
/// 擴展自訂轉換器：
/// ```swift
/// extension CodingTransformer {
///     public static let colorHex = CodingTransformer("ColorHexTransform")
/// }
/// ```
public struct CodingTransformer: Sendable {
    /// 轉換器的類型名稱
    public let typeName: String

    /// 初始化轉換器參數
    /// - Parameter typeName: 轉換器的類型名稱（必須與實際的轉換器類型名稱一致）
    public init(_ typeName: String) {
        self.typeName = typeName
    }

    // MARK: - 內建轉換器

    /// URL ↔ String 轉換器
    public static let url = CodingTransformer("URLTransform")

    /// UUID ↔ String 轉換器
    public static let uuid = CodingTransformer("UUIDTransform")

    /// Date ↔ ISO8601 String 轉換器
    public static let iso8601Date = CodingTransformer("ISO8601DateTransform")

    /// Date ↔ Unix Timestamp (Double) 轉換器
    public static let timestampDate = CodingTransformer("TimestampDateTransform")

    /// Bool ↔ Int (0/1) 轉換器
    public static let boolInt = CodingTransformer("BoolIntTransform")
}
