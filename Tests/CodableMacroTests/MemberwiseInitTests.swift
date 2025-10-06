import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing
import CodableMacroMacros

struct MemberwiseInitTests {
    let testMacros: [String: Macro.Type] = [
        "Codable": CodableMacro.self
    ]

    @Test("基本 memberwise init")
    func testBasicMemberwiseInit() throws {
        assertMacroExpansion(
            """
            @Codable
            struct User {
                let id: String
                let name: String
            }
            """,
            expandedSource: """
            struct User {
                let id: String
                let name: String

                enum CodingKeys: String, CodingKey {
                    case id
                    case name
                }

                init(
                    id: String,
                    name: String
                ) {
                    self.id = id
                    self.name = name
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.id = try container.decode(String.self, forKey: .id)
                    self.name = try container.decode(String.self, forKey: .name)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(id, forKey: .id)
                    try container.encode(name, forKey: .name)
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

            extension User: Codable {
            }
            """,
            macros: testMacros
        )
    }

    @Test("Optional 屬性預設值為 nil")
    func testOptionalPropertiesDefaultNil() throws {
        assertMacroExpansion(
            """
            @Codable
            struct User {
                let id: String
                let name: String?
                let email: String?
            }
            """,
            expandedSource: """
            struct User {
                let id: String
                let name: String?
                let email: String?

                enum CodingKeys: String, CodingKey {
                    case id
                    case name
                    case email
                }

                init(
                    id: String,
                    name: String? = nil,
                    email: String? = nil
                ) {
                    self.id = id
                    self.name = name
                    self.email = email
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.id = try container.decode(String.self, forKey: .id)
                    self.name = try container.decodeIfPresent(String.self, forKey: .name)
                    self.email = try container.decodeIfPresent(String.self, forKey: .email)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(id, forKey: .id)
                    try container.encodeIfPresent(name, forKey: .name)
                    try container.encodeIfPresent(email, forKey: .email)
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

            extension User: Codable {
            }
            """,
            macros: testMacros
        )
    }

    @Test("混合 Optional 和預設值")
    func testMixedOptionalAndDefaultValues() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Config {
                let name: String
                let timeout: Int = 30
                let enabled: Bool?
                var retries: Int = 3
            }
            """,
            expandedSource: """
            struct Config {
                let name: String
                let timeout: Int = 30
                let enabled: Bool?
                var retries: Int = 3

                enum CodingKeys: String, CodingKey {
                    case name
                    case timeout
                    case enabled
                    case retries
                }

                init(
                    name: String,
                    timeout: Int = 30,
                    enabled: Bool? = nil,
                    retries: Int = 3
                ) {
                    self.name = name
                    self.timeout = timeout
                    self.enabled = enabled
                    self.retries = retries
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.name = try container.decode(String.self, forKey: .name)
                    self.enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled)
                    self.retries = try container.decodeIfPresent(Int.self, forKey: .retries) ?? 3
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(name, forKey: .name)
                    try container.encode(timeout, forKey: .timeout)
                    try container.encodeIfPresent(enabled, forKey: .enabled)
                    try container.encode(retries, forKey: .retries)
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

    @Test("Public struct memberwise init")
    func testPublicMemberwiseInit() throws {
        assertMacroExpansion(
            """
            @Codable
            public struct User {
                public let id: String
                public let name: String?
            }
            """,
            expandedSource: """
            public struct User {
                public let id: String
                public let name: String?

                public enum CodingKeys: String, CodingKey {
                    case id
                    case name
                }

                public init(
                    id: String,
                    name: String? = nil
                ) {
                    self.id = id
                    self.name = name
                }

                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.id = try container.decode(String.self, forKey: .id)
                    self.name = try container.decodeIfPresent(String.self, forKey: .name)
                }

                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(id, forKey: .id)
                    try container.encodeIfPresent(name, forKey: .name)
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

    @Test("@CodingIgnored 屬性不在 memberwise init 中")
    func testCodingIgnoredNotInMemberwiseInit() throws {
        assertMacroExpansion(
            """
            @Codable
            struct User {
                let id: String
                let name: String
                @CodingIgnored
                var cache: String = ""
            }
            """,
            expandedSource: """
            struct User {
                let id: String
                let name: String
                var cache: String = ""

                enum CodingKeys: String, CodingKey {
                    case id
                    case name
                }

                init(
                    id: String,
                    name: String
                ) {
                    self.id = id
                    self.name = name
                    self.cache = \"\"
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.id = try container.decode(String.self, forKey: .id)
                    self.name = try container.decode(String.self, forKey: .name)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(id, forKey: .id)
                    try container.encode(name, forKey: .name)
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

            extension User: Codable {
            }
            """,
            macros: testMacros
        )
    }

    @Test("有自訂 init 時不產生 memberwise init")
    func testNoMemberwiseInitWithCustomInit() throws {
        assertMacroExpansion(
            """
            @Codable
            struct User {
                let id: String
                let name: String

                init(id: String) {
                    self.id = id
                    self.name = "Default"
                }
            }
            """,
            expandedSource: """
            struct User {
                let id: String
                let name: String

                init(id: String) {
                    self.id = id
                    self.name = "Default"
                }

                enum CodingKeys: String, CodingKey {
                    case id
                    case name
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.id = try container.decode(String.self, forKey: .id)
                    self.name = try container.decode(String.self, forKey: .name)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(id, forKey: .id)
                    try container.encode(name, forKey: .name)
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

            extension User: Codable {
            }
            """,
            macros: testMacros
        )
    }

    @Test("有多個自訂 init 時不產生 memberwise init")
    func testNoMemberwiseInitWithMultipleCustomInit() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Config {
                let timeout: Int
                let retries: Int

                init() {
                    self.timeout = 30
                    self.retries = 3
                }

                init(timeout: Int) {
                    self.timeout = timeout
                    self.retries = 3
                }
            }
            """,
            expandedSource: """
            struct Config {
                let timeout: Int
                let retries: Int

                init() {
                    self.timeout = 30
                    self.retries = 3
                }

                init(timeout: Int) {
                    self.timeout = timeout
                    self.retries = 3
                }

                enum CodingKeys: String, CodingKey {
                    case timeout
                    case retries
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.timeout = try container.decode(Int.self, forKey: .timeout)
                    self.retries = try container.decode(Int.self, forKey: .retries)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(timeout, forKey: .timeout)
                    try container.encode(retries, forKey: .retries)
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
}
