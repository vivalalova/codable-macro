import Testing
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
@testable import CodableMacroMacros
@testable import CodableMacro

/// 字典轉換測試
struct DictConversionTests {

    @Test("Dictionary 轉換 - Struct 基本功能")
    func testStructDictConversion() throws {
        assertMacroExpansion(
            """
            @Codable
            struct User {
                let id: String
                let name: String
                let age: Int
            }
            """,
            expandedSource: """
            struct User {
                let id: String
                let name: String
                let age: Int

                enum CodingKeys: String, CodingKey {
                    case id
                    case name
                    case age
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.id = try container.decode(String.self, forKey: .id)
                    self.name = try container.decode(String.self, forKey: .name)
                    self.age = try container.decode(Int.self, forKey: .age)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(id, forKey: .id)
                    try container.encode(name, forKey: .name)
                    try container.encode(age, forKey: .age)
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
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("Dictionary 轉換 - Optional 屬性")
    func testDictConversionWithOptional() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Profile {
                let id: String
                let bio: String?
                let avatar: String?
            }
            """,
            expandedSource: """
            struct Profile {
                let id: String
                let bio: String?
                let avatar: String?

                enum CodingKeys: String, CodingKey {
                    case id
                    case bio
                    case avatar
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.id = try container.decode(String.self, forKey: .id)
                    self.bio = try container.decodeIfPresent(String.self, forKey: .bio)
                    self.avatar = try container.decodeIfPresent(String.self, forKey: .avatar)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(id, forKey: .id)
                    try container.encodeIfPresent(bio, forKey: .bio)
                    try container.encodeIfPresent(avatar, forKey: .avatar)
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

            extension Profile: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("Dictionary 轉換 - Class 類型")
    func testClassDictConversion() throws {
        assertMacroExpansion(
            """
            @Codable
            class Person {
                let id: String
                let name: String
            }
            """,
            expandedSource: """
            class Person {
                let id: String
                let name: String

                enum CodingKeys: String, CodingKey {
                    case id
                    case name
                }

                required init(from decoder: Decoder) throws {
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

            extension Person: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("Dictionary 轉換 - Simple Enum")
    func testSimpleEnumDictConversion() throws {
        assertMacroExpansion(
            """
            @Codable
            enum Status {
                case active
                case inactive
                case pending
            }
            """,
            expandedSource: """
            enum Status {
                case active
                case inactive
                case pending

                init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let value = try container.decode(String.self)

                    switch value {
                    case "active":
                        self = .active
                    case "inactive":
                        self = .inactive
                    case "pending":
                        self = .pending
                    default:
                        throw DecodingError.dataCorrupted(
                            DecodingError.Context(
                                codingPath: decoder.codingPath,
                                debugDescription: "Invalid enum case: \\(value)"
                            )
                        )
                    }
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.singleValueContainer()

                    switch self {
                    case .active:
                        try container.encode("active")
                    case .inactive:
                        try container.encode("inactive")
                    case .pending:
                        try container.encode("pending")
                    }
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

            extension Status: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("Dictionary 轉換 - Associated Values Enum")
    func testAssociatedValuesEnumDictConversion() throws {
        assertMacroExpansion(
            """
            @Codable
            enum Result {
                case success(data: String)
                case failure(error: String, code: Int)
            }
            """,
            expandedSource: """
            enum Result {
                case success(data: String)
                case failure(error: String, code: Int)

                enum CodingKeys: String, CodingKey {
                    case success
                    case failure
                }

                enum SuccessCodingKeys: String, CodingKey {
                    case data
                }

                enum FailureCodingKeys: String, CodingKey {
                    case error
                    case code
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)

                    if container.allKeys.count != 1 {
                        throw DecodingError.dataCorrupted(
                            DecodingError.Context(
                                codingPath: decoder.codingPath,
                                debugDescription: "Expected exactly one key"
                            )
                        )
                    }

                    let key = container.allKeys.first!

                    switch key {
                    case .success:
                        let nestedContainer = try container.nestedContainer(keyedBy: SuccessCodingKeys.self, forKey: .success)
                        let data = try nestedContainer.decode(String.self, forKey: .data)
                        self = .success(data: data)
                    case .failure:
                        let nestedContainer = try container.nestedContainer(keyedBy: FailureCodingKeys.self, forKey: .failure)
                        let error = try nestedContainer.decode(String.self, forKey: .error)
                        let code = try nestedContainer.decode(Int.self, forKey: .code)
                        self = .failure(error: error, code: code)
                    }
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)

                    switch self {
                    case .success(let data):
                        var nestedContainer = container.nestedContainer(keyedBy: SuccessCodingKeys.self, forKey: .success)
                        try nestedContainer.encode(data, forKey: .data)
                    case .failure(let error, let code):
                        var nestedContainer = container.nestedContainer(keyedBy: FailureCodingKeys.self, forKey: .failure)
                        try nestedContainer.encode(error, forKey: .error)
                        try nestedContainer.encode(code, forKey: .code)
                    }
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

            extension Result: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("Dictionary 轉換 - 空 Struct")
    func testEmptyStructDictConversion() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Empty {
            }
            """,
            expandedSource: """
            struct Empty {

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

            extension Empty: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("Dictionary 轉換 - 包含 Collection 型別")
    func testDictConversionWithCollections() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Settings {
                let tags: [String]
                let config: [String: String]
            }
            """,
            expandedSource: """
            struct Settings {
                let tags: [String]
                let config: [String: String]

                enum CodingKeys: String, CodingKey {
                    case tags
                    case config
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.tags = try container.decode([String].self, forKey: .tags)
                    self.config = try container.decode([String: String].self, forKey: .config)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(tags, forKey: .tags)
                    try container.encode(config, forKey: .config)
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

            extension Settings: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("Dictionary 轉換 - Optional Collection")
    func testDictConversionWithOptionalCollections() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Metadata {
                let id: String
                let tags: [String]?
                let info: [String: Any]?
            }
            """,
            expandedSource: """
            struct Metadata {
                let id: String
                let tags: [String]?
                let info: [String: Any]?

                enum CodingKeys: String, CodingKey {
                    case id
                    case tags
                    case info
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.id = try container.decode(String.self, forKey: .id)
                    self.tags = try container.decodeIfPresent([String].self, forKey: .tags)
                    self.info = try container.decodeIfPresent([String: Any].self, forKey: .info)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(id, forKey: .id)
                    try container.encodeIfPresent(tags, forKey: .tags)
                    try container.encodeIfPresent(info, forKey: .info)
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

            extension Metadata: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }
}
