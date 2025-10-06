/// 字典轉換錯誤
public enum DictConversionError: Error, CustomStringConvertible {
    case invalidDictionaryStructure
    case serializationFailed(Error)
    case deserializationFailed(Error)

    public var description: String {
        switch self {
        case .invalidDictionaryStructure:
            return "Invalid dictionary structure: expected [String: Any]"
        case .serializationFailed(let error):
            return "Serialization failed: \(error)"
        case .deserializationFailed(let error):
            return "Deserialization failed: \(error)"
        }
    }
}

/// @Codable macro 讓結構自動符合 Codable protocol
///
/// 此 macro 會自動產生：
/// - CodingKeys enum
/// - init(from decoder: Decoder) 初始化方法
/// - func encode(to encoder: Encoder) 編碼方法
/// - Dictionary 轉換方法（fromDict, toDict 等）
///
/// 支援 @CodingKey 自訂 JSON key 映射：
/// ```swift
/// @Codable
/// struct Message {
///     @CodingKey("tool_use_id")
///     var toolUseId: String
///
///     let content: String  // 使用預設 key
/// }
/// ```
///
/// 基本使用範例：
/// ```swift
/// @Codable
/// struct Message {
///   let id: String
///   let content: String
///   let timestamp: Date
/// }
/// ```
@attached(member, names:
    named(CodingKeys),
    named(init(from:)),
    named(encode(to:)),
    named(fromDict(_:)),
    named(fromDictArray(_:)),
    named(toDict()),
    named(toDictArray(_:)),
    arbitrary
)
@attached(extension, conformances: Codable)
public macro Codable() = #externalMacro(module: "CodableMacroMacros", type: "CodableMacro")

/// @CodingKey macro 用於自訂 JSON key 映射和型別轉換
///
/// 基本使用範例：
/// ```swift
/// @Codable
/// struct Message {
///     @CodingKey("tool_use_id")
///     var toolUseId: String
///
///     @CodingKey("workspace", transform: .url)
///     let workspace: URL
///
///     @CodingKey(transform: .uuid)
///     let sessionId: UUID
/// }
/// ```
@attached(peer)
public macro CodingKey(_ key: String? = nil, transform: CodingTransformer? = nil) = #externalMacro(module: "CodableMacroMacros", type: "CodingKeyMacro")

/// @CodingIgnored macro 用於標記不參與 Codable 編碼/解碼的屬性
///
/// 使用範例：
/// ```swift
/// @Codable
/// struct User {
///     let id: String
///
///     @CodingIgnored
///     var cachedData: String = ""
/// }
/// ```
@attached(peer)
public macro CodingIgnored() = #externalMacro(module: "CodableMacroMacros", type: "CodingIgnoredMacro")
