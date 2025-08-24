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
@attached(member, names: named(CodingKeys), named(init(from:)), named(encode(to:)))
@attached(extension, conformances: Codable)
public macro Codable() = #externalMacro(module: "CodableMacroMacros", type: "CodableMacro")
