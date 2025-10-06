import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing
import CodableMacroMacros

struct PublicVisibilityTests {
    let testMacros: [String: Macro.Type] = [
        "Codable": CodableMacro.self
    ]

    @Test("Public struct - 所有生成的成員都是 public")
    func testPublicStruct() throws {
        assertMacroExpansion(
            """
            @Codable
            public struct User {
                public let id: String
                public let name: String
            }
            """,
            expandedSource: """
            public struct User {
                public let id: String
                public let name: String

                public enum CodingKeys: String, CodingKey {
                    case id
                    case name
                }

                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.id = try container.decode(String.self, forKey: .id)
                    self.name = try container.decode(String.self, forKey: .name)
                }

                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(id, forKey: .id)
                    try container.encode(name, forKey: .name)
                }

                public static func fromDict(_ dict: [String: Any]) throws -> Self {
                    let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
                    let decoder = JSONDecoder()
                    return try decoder.decode(Self.self, from: jsonData)
                }

                public static func fromDictArray(_ array: [[String: Any]]) throws -> [Self] {
                    try array.map { dict in
                        try fromDict(dict)
                    }
                }

                public func toDict() throws -> [String: Any] {
                    let encoder = JSONEncoder()
                    let jsonData = try encoder.encode(self)
                    guard let dict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
                        throw CodableMacro.DictConversionError.invalidDictionaryStructure
                    }
                    return dict
                }

                public static func toDictArray(_ array: [Self]) throws -> [[String: Any]] {
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

    @Test("Public class - init 需要 public required")
    func testPublicClass() throws {
        assertMacroExpansion(
            """
            @Codable
            public class Vehicle {
                public let brand: String
                public let model: String
            }
            """,
            expandedSource: """
            public class Vehicle {
                public let brand: String
                public let model: String

                public enum CodingKeys: String, CodingKey {
                    case brand
                    case model
                }

                public required init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.brand = try container.decode(String.self, forKey: .brand)
                    self.model = try container.decode(String.self, forKey: .model)
                }

                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(brand, forKey: .brand)
                    try container.encode(model, forKey: .model)
                }

                public static func fromDict(_ dict: [String: Any]) throws -> Self {
                    let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
                    let decoder = JSONDecoder()
                    return try decoder.decode(Self.self, from: jsonData)
                }

                public static func fromDictArray(_ array: [[String: Any]]) throws -> [Self] {
                    try array.map { dict in
                        try fromDict(dict)
                    }
                }

                public func toDict() throws -> [String: Any] {
                    let encoder = JSONEncoder()
                    let jsonData = try encoder.encode(self)
                    guard let dict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
                        throw CodableMacro.DictConversionError.invalidDictionaryStructure
                    }
                    return dict
                }

                public static func toDictArray(_ array: [Self]) throws -> [[String: Any]] {
                    try array.map { instance in
                        try instance.toDict()
                    }
                }
            }

            extension Vehicle: Codable {
            }
            """,
            macros: testMacros
        )
    }

    @Test("Internal struct - 維持原行為（無 public 修飾詞）")
    func testInternalStruct() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Config {
                let apiKey: String
            }
            """,
            expandedSource: """
            struct Config {
                let apiKey: String

                enum CodingKeys: String, CodingKey {
                    case apiKey
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
                        throw CodableMacro.DictConversionError.invalidDictionaryStructure
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

    @Test("Public struct with Optional - 測試 decodeIfPresent 也是 public")
    func testPublicStructWithOptional() throws {
        assertMacroExpansion(
            """
            @Codable
            public struct Profile {
                public let username: String
                public let bio: String?
            }
            """,
            expandedSource: """
            public struct Profile {
                public let username: String
                public let bio: String?

                public enum CodingKeys: String, CodingKey {
                    case username
                    case bio
                }

                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.username = try container.decode(String.self, forKey: .username)
                    self.bio = try container.decodeIfPresent(String.self, forKey: .bio)
                }

                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(username, forKey: .username)
                    try container.encodeIfPresent(bio, forKey: .bio)
                }

                public static func fromDict(_ dict: [String: Any]) throws -> Self {
                    let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
                    let decoder = JSONDecoder()
                    return try decoder.decode(Self.self, from: jsonData)
                }

                public static func fromDictArray(_ array: [[String: Any]]) throws -> [Self] {
                    try array.map { dict in
                        try fromDict(dict)
                    }
                }

                public func toDict() throws -> [String: Any] {
                    let encoder = JSONEncoder()
                    let jsonData = try encoder.encode(self)
                    guard let dict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
                        throw CodableMacro.DictConversionError.invalidDictionaryStructure
                    }
                    return dict
                }

                public static func toDictArray(_ array: [Self]) throws -> [[String: Any]] {
                    try array.map { instance in
                        try instance.toDict()
                    }
                }
            }

            extension Profile: Codable {
            }
            """,
            macros: testMacros
        )
    }

    @Test("Public struct 與 @CodingKey 混合")
    func testPublicWithCodingKey() throws {
        assertMacroExpansion(
            """
            @Codable
            public struct APIRequest {
                @CodingKey("api_key")
                public let apiKey: String
            }
            """,
            expandedSource: """
            public struct APIRequest {
                public let apiKey: String

                public enum CodingKeys: String, CodingKey {
                    case apiKey = "api_key"
                }

                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.apiKey = try container.decode(String.self, forKey: .apiKey)
                }

                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(apiKey, forKey: .apiKey)
                }

                public static func fromDict(_ dict: [String: Any]) throws -> Self {
                    let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
                    let decoder = JSONDecoder()
                    return try decoder.decode(Self.self, from: jsonData)
                }

                public static func fromDictArray(_ array: [[String: Any]]) throws -> [Self] {
                    try array.map { dict in
                        try fromDict(dict)
                    }
                }

                public func toDict() throws -> [String: Any] {
                    let encoder = JSONEncoder()
                    let jsonData = try encoder.encode(self)
                    guard let dict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
                        throw CodableMacro.DictConversionError.invalidDictionaryStructure
                    }
                    return dict
                }

                public static func toDictArray(_ array: [Self]) throws -> [[String: Any]] {
                    try array.map { instance in
                        try instance.toDict()
                    }
                }
            }

            extension APIRequest: Codable {
            }
            """,
            macros: testMacros
        )
    }
}
