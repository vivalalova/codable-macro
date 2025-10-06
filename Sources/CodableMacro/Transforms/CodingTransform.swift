import Foundation

/// 型別轉換器協定
///
/// 定義 Swift 型別與 JSON 型別之間的雙向轉換邏輯
public protocol CodingTransform {
    /// Swift 型別（屬性實際型別）
    associatedtype SwiftType

    /// JSON 型別（在 JSON 中的表示型別，必須符合 Codable）
    associatedtype JSONType: Codable

    /// 將 Swift 型別編碼為 JSON 型別
    /// - Parameter value: Swift 型別的值
    /// - Returns: 轉換後的 JSON 型別值
    /// - Throws: 轉換失敗時拋出錯誤
    func encode(_ value: SwiftType) throws -> JSONType

    /// 將 JSON 型別解碼為 Swift 型別
    /// - Parameter value: JSON 型別的值
    /// - Returns: 轉換後的 Swift 型別值
    /// - Throws: 轉換失敗時拋出錯誤
    func decode(_ value: JSONType) throws -> SwiftType
}
