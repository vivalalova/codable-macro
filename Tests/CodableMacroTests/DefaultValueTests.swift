import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing
import CodableMacroMacros

struct DefaultValueTests {
    let testMacros: [String: Macro.Type] = [
        "Codable": CodableMacro.self
    ]

    @Test("基本預設值 - Optional Int 預設為 0")
    func testBasicDefaultValue() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Config {
                let timeout: Int? = 30
            }
            """,
            expandedSource: """
            struct Config {
                let timeout: Int? = 30

                enum CodingKeys: String, CodingKey {
                    case timeout
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.timeout = try container.decodeIfPresent(Int.self, forKey: .timeout) ?? 30
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encodeIfPresent(timeout, forKey: .timeout)
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

    @Test("混合屬性 - 有預設值和無預設值")
    func testMixedDefaultValues() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Settings {
                let name: String
                let enabled: Bool? = true
                let value: Int?
            }
            """,
            expandedSource: """
            struct Settings {
                let name: String
                let enabled: Bool? = true
                let value: Int?

                enum CodingKeys: String, CodingKey {
                    case name
                    case enabled
                    case value
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.name = try container.decode(String.self, forKey: .name)
                    self.enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
                    self.value = try container.decodeIfPresent(Int.self, forKey: .value)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(name, forKey: .name)
                    try container.encodeIfPresent(enabled, forKey: .enabled)
                    try container.encodeIfPresent(value, forKey: .value)
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

            extension Settings: Codable {
            }
            """,
            macros: testMacros
        )
    }

    @Test("非 Optional 屬性預設值 - let 屬性跳過初始化")
    func testNonOptionalWithDefaultValue() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Config {
                let timeout: Int = 30
                let debug: Bool = false
            }
            """,
            expandedSource: """
            struct Config {
                let timeout: Int = 30
                let debug: Bool = false

                enum CodingKeys: String, CodingKey {
                    case timeout
                    case debug
                }

                init(from decoder: Decoder) throws {
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(timeout, forKey: .timeout)
                    try container.encode(debug, forKey: .debug)
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

    @Test("複雜型別預設值 - let 屬性跳過初始化")
    func testComplexDefaultValues() throws {
        assertMacroExpansion(
            """
            @Codable
            struct AppConfig {
                let name: String
                let tags: [String] = []
                let metadata: [String: String] = [:]
            }
            """,
            expandedSource: """
            struct AppConfig {
                let name: String
                let tags: [String] = []
                let metadata: [String: String] = [:]

                enum CodingKeys: String, CodingKey {
                    case name
                    case tags
                    case metadata
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.name = try container.decode(String.self, forKey: .name)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(name, forKey: .name)
                    try container.encode(tags, forKey: .tags)
                    try container.encode(metadata, forKey: .metadata)
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

            extension AppConfig: Codable {
            }
            """,
            macros: testMacros
        )
    }

    @Test("var 屬性預設值 - 可從 JSON 覆蓋")
    func testVarWithDefaultValue() throws {
        assertMacroExpansion(
            """
            @Codable
            struct MutableConfig {
                let id: String
                var timeout: Int = 30
                var enabled: Bool = true
            }
            """,
            expandedSource: """
            struct MutableConfig {
                let id: String
                var timeout: Int = 30
                var enabled: Bool = true

                enum CodingKeys: String, CodingKey {
                    case id
                    case timeout
                    case enabled
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.id = try container.decode(String.self, forKey: .id)
                    self.timeout = try container.decodeIfPresent(Int.self, forKey: .timeout) ?? 30
                    self.enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(id, forKey: .id)
                    try container.encode(timeout, forKey: .timeout)
                    try container.encode(enabled, forKey: .enabled)
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

            extension MutableConfig: Codable {
            }
            """,
            macros: testMacros
        )
    }
}
