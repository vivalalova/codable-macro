import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing
import CodableMacroMacros

struct CodingIgnoredTests {
    let testMacros: [String: Macro.Type] = [
        "Codable": CodableMacro.self,
        "CodingIgnored": CodingIgnoredMacro.self
    ]

    @Test("基本屬性忽略 - 單一屬性標記 @CodingIgnored")
    func testBasicIgnore() throws {
        assertMacroExpansion(
            """
            @Codable
            struct User {
                let id: String
                @CodingIgnored
                var tempData: String
            }
            """,
            expandedSource: """
            struct User {
                let id: String
                var tempData: String

                enum CodingKeys: String, CodingKey {
                    case id
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.id = try container.decode(String.self, forKey: .id)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(id, forKey: .id)
                }

                static func fromDict(_ dict: [String: Any]) throws -> Self {
                    let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
                    let decoder = JSONDecoder()
                    return try decoder.decode(Self.self, from: jsonData)
                }

                static func fromDictArray(_ array: [[String: Any]]) throws -> [Self] {
                    try array.map { dict in
                        try fromDict(dict)
                    }
                }

                func toDict() throws -> [String: Any] {
                    let encoder = JSONEncoder()
                    let jsonData = try encoder.encode(self)
                    guard let dict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
                        throw DictConversionError.invalidDictionaryStructure
                    }
                    return dict
                }

                static func toDictArray(_ array: [Self]) throws -> [[String: Any]] {
                    try array.map { instance in
                        try instance.toDict()
                    }
                }
            }

            extension User: Codable {
            }
            """,
            macros: testMacros
        )
    }

    @Test("多屬性忽略 - 混合正常屬性和忽略屬性")
    func testMultipleIgnore() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Config {
                let apiKey: String
                let endpoint: String
                @CodingIgnored
                var cachedResponse: String?
                @CodingIgnored
                var lastFetchTime: Int
            }
            """,
            expandedSource: """
            struct Config {
                let apiKey: String
                let endpoint: String
                var cachedResponse: String?
                var lastFetchTime: Int

                enum CodingKeys: String, CodingKey {
                    case apiKey
                    case endpoint
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.apiKey = try container.decode(String.self, forKey: .apiKey)
                    self.endpoint = try container.decode(String.self, forKey: .endpoint)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(apiKey, forKey: .apiKey)
                    try container.encode(endpoint, forKey: .endpoint)
                }

                static func fromDict(_ dict: [String: Any]) throws -> Self {
                    let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
                    let decoder = JSONDecoder()
                    return try decoder.decode(Self.self, from: jsonData)
                }

                static func fromDictArray(_ array: [[String: Any]]) throws -> [Self] {
                    try array.map { dict in
                        try fromDict(dict)
                    }
                }

                func toDict() throws -> [String: Any] {
                    let encoder = JSONEncoder()
                    let jsonData = try encoder.encode(self)
                    guard let dict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
                        throw DictConversionError.invalidDictionaryStructure
                    }
                    return dict
                }

                static func toDictArray(_ array: [Self]) throws -> [[String: Any]] {
                    try array.map { instance in
                        try instance.toDict()
                    }
                }
            }

            extension Config: Codable {
            }
            """,
            macros: testMacros
        )
    }

    @Test("自動忽略 computed property")
    func testComputedPropertyAutoIgnore() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Article {
                let title: String
                let content: String
                var wordCount: Int {
                    content.split(separator: " ").count
                }
            }
            """,
            expandedSource: """
            struct Article {
                let title: String
                let content: String
                var wordCount: Int {
                    content.split(separator: " ").count
                }

                enum CodingKeys: String, CodingKey {
                    case title
                    case content
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.title = try container.decode(String.self, forKey: .title)
                    self.content = try container.decode(String.self, forKey: .content)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(title, forKey: .title)
                    try container.encode(content, forKey: .content)
                }

                static func fromDict(_ dict: [String: Any]) throws -> Self {
                    let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
                    let decoder = JSONDecoder()
                    return try decoder.decode(Self.self, from: jsonData)
                }

                static func fromDictArray(_ array: [[String: Any]]) throws -> [Self] {
                    try array.map { dict in
                        try fromDict(dict)
                    }
                }

                func toDict() throws -> [String: Any] {
                    let encoder = JSONEncoder()
                    let jsonData = try encoder.encode(self)
                    guard let dict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
                        throw DictConversionError.invalidDictionaryStructure
                    }
                    return dict
                }

                static func toDictArray(_ array: [Self]) throws -> [[String: Any]] {
                    try array.map { instance in
                        try instance.toDict()
                    }
                }
            }

            extension Article: Codable {
            }
            """,
            macros: testMacros
        )
    }

    @Test("混合測試 - @CodingIgnored 和 computed property")
    func testMixedIgnore() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Product {
                let name: String
                let price: Double
                @CodingIgnored
                var discount: Double = 0
                var finalPrice: Double {
                    price * (1 - discount)
                }
            }
            """,
            expandedSource: """
            struct Product {
                let name: String
                let price: Double
                var discount: Double = 0
                var finalPrice: Double {
                    price * (1 - discount)
                }

                enum CodingKeys: String, CodingKey {
                    case name
                    case price
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.name = try container.decode(String.self, forKey: .name)
                    self.price = try container.decode(Double.self, forKey: .price)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(name, forKey: .name)
                    try container.encode(price, forKey: .price)
                }

                static func fromDict(_ dict: [String: Any]) throws -> Self {
                    let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
                    let decoder = JSONDecoder()
                    return try decoder.decode(Self.self, from: jsonData)
                }

                static func fromDictArray(_ array: [[String: Any]]) throws -> [Self] {
                    try array.map { dict in
                        try fromDict(dict)
                    }
                }

                func toDict() throws -> [String: Any] {
                    let encoder = JSONEncoder()
                    let jsonData = try encoder.encode(self)
                    guard let dict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
                        throw DictConversionError.invalidDictionaryStructure
                    }
                    return dict
                }

                static func toDictArray(_ array: [Self]) throws -> [[String: Any]] {
                    try array.map { instance in
                        try instance.toDict()
                    }
                }
            }

            extension Product: Codable {
            }
            """,
            macros: testMacros
        )
    }

    @Test("Optional 屬性忽略")
    func testOptionalIgnore() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Session {
                let token: String
                @CodingIgnored
                var metadata: [String: Any]?
            }
            """,
            expandedSource: """
            struct Session {
                let token: String
                var metadata: [String: Any]?

                enum CodingKeys: String, CodingKey {
                    case token
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.token = try container.decode(String.self, forKey: .token)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(token, forKey: .token)
                }

                static func fromDict(_ dict: [String: Any]) throws -> Self {
                    let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
                    let decoder = JSONDecoder()
                    return try decoder.decode(Self.self, from: jsonData)
                }

                static func fromDictArray(_ array: [[String: Any]]) throws -> [Self] {
                    try array.map { dict in
                        try fromDict(dict)
                    }
                }

                func toDict() throws -> [String: Any] {
                    let encoder = JSONEncoder()
                    let jsonData = try encoder.encode(self)
                    guard let dict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
                        throw DictConversionError.invalidDictionaryStructure
                    }
                    return dict
                }

                static func toDictArray(_ array: [Self]) throws -> [[String: Any]] {
                    try array.map { instance in
                        try instance.toDict()
                    }
                }
            }

            extension Session: Codable {
            }
            """,
            macros: testMacros
        )
    }

    @Test("所有屬性被忽略 - 應產生空 CodingKeys")
    func testAllPropertiesIgnored() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Cache {
                @CodingIgnored
                var data: String
                @CodingIgnored
                var timestamp: Int
            }
            """,
            expandedSource: """
            struct Cache {
                var data: String
                var timestamp: Int

                enum CodingKeys: String, CodingKey {
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                }

                static func fromDict(_ dict: [String: Any]) throws -> Self {
                    let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
                    let decoder = JSONDecoder()
                    return try decoder.decode(Self.self, from: jsonData)
                }

                static func fromDictArray(_ array: [[String: Any]]) throws -> [Self] {
                    try array.map { dict in
                        try fromDict(dict)
                    }
                }

                func toDict() throws -> [String: Any] {
                    let encoder = JSONEncoder()
                    let jsonData = try encoder.encode(self)
                    guard let dict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
                        throw DictConversionError.invalidDictionaryStructure
                    }
                    return dict
                }

                static func toDictArray(_ array: [Self]) throws -> [[String: Any]] {
                    try array.map { instance in
                        try instance.toDict()
                    }
                }
            }

            extension Cache: Codable {
            }
            """,
            macros: testMacros
        )
    }

    @Test("Class 類型支援忽略")
    func testClassIgnore() throws {
        assertMacroExpansion(
            """
            @Codable
            class ViewModel {
                let id: String
                @CodingIgnored
                var isLoading: Bool = false
            }
            """,
            expandedSource: """
            class ViewModel {
                let id: String
                var isLoading: Bool = false

                enum CodingKeys: String, CodingKey {
                    case id
                }

                required init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.id = try container.decode(String.self, forKey: .id)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(id, forKey: .id)
                }

                static func fromDict(_ dict: [String: Any]) throws -> Self {
                    let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
                    let decoder = JSONDecoder()
                    return try decoder.decode(Self.self, from: jsonData)
                }

                static func fromDictArray(_ array: [[String: Any]]) throws -> [Self] {
                    try array.map { dict in
                        try fromDict(dict)
                    }
                }

                func toDict() throws -> [String: Any] {
                    let encoder = JSONEncoder()
                    let jsonData = try encoder.encode(self)
                    guard let dict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
                        throw DictConversionError.invalidDictionaryStructure
                    }
                    return dict
                }

                static func toDictArray(_ array: [Self]) throws -> [[String: Any]] {
                    try array.map { instance in
                        try instance.toDict()
                    }
                }
            }

            extension ViewModel: Codable {
            }
            """,
            macros: testMacros
        )
    }

    @Test("與 @CodingKey 混合使用")
    func testIgnoreWithCodingKey() throws {
        assertMacroExpansion(
            """
            @Codable
            struct APIResponse {
                @CodingKey("api_key")
                let apiKey: String
                @CodingIgnored
                var rawResponse: String?
            }
            """,
            expandedSource: """
            struct APIResponse {
                let apiKey: String
                var rawResponse: String?

                enum CodingKeys: String, CodingKey {
                    case apiKey = "api_key"
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.apiKey = try container.decode(String.self, forKey: .apiKey)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(apiKey, forKey: .apiKey)
                }

                static func fromDict(_ dict: [String: Any]) throws -> Self {
                    let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
                    let decoder = JSONDecoder()
                    return try decoder.decode(Self.self, from: jsonData)
                }

                static func fromDictArray(_ array: [[String: Any]]) throws -> [Self] {
                    try array.map { dict in
                        try fromDict(dict)
                    }
                }

                func toDict() throws -> [String: Any] {
                    let encoder = JSONEncoder()
                    let jsonData = try encoder.encode(self)
                    guard let dict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
                        throw DictConversionError.invalidDictionaryStructure
                    }
                    return dict
                }

                static func toDictArray(_ array: [Self]) throws -> [[String: Any]] {
                    try array.map { instance in
                        try instance.toDict()
                    }
                }
            }

            extension APIResponse: Codable {
            }
            """,
            macros: testMacros
        )
    }
}
