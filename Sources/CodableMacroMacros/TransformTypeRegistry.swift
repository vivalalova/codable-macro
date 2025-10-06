import Foundation

/// 轉換器型別註冊表
///
/// 提供內建轉換器的型別映射，用於編譯期推斷 JSON 型別
struct TransformTypeRegistry {
    /// 內建轉換器的型別映射表
    /// Key: 轉換器型別名稱
    /// Value: JSON 型別名稱
    static let builtinTransforms: [String: String] = [
        "URLTransform": "String",
        "UUIDTransform": "String",
        "ISO8601DateTransform": "String",
        "TimestampDateTransform": "Double",
        "BoolIntTransform": "Int"
    ]

    /// 根據轉換器型別名稱查詢對應的 JSON 型別
    /// - Parameter transformerType: 轉換器型別名稱
    /// - Returns: JSON 型別名稱，若找不到則返回 nil
    static func jsonType(for transformerType: String) -> String? {
        return builtinTransforms[transformerType]
    }
}
