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
///
/// 使用範例：
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
    named(toDictArray(_:))
)
@attached(extension, conformances: Codable)
public macro Codable() = #externalMacro(module: "CodableMacroMacros", type: "CodableMacro")
