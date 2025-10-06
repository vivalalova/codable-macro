import Testing
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Foundation

@testable import CodableMacroMacros

let testMacros: [String: Macro.Type] = [
    "Codable": CodableMacro.self,
    "CodingKey": CodingKeyMacro.self,
]

// MARK: - Macro 展開測試

@Test("URL 轉換 - 基本使用")
func testURLTransformBasic() {
    assertMacroExpansion(
        """
        @Codable
        struct Message {
            @CodingKey(transform: .url)
            let endpoint: URL

            let content: String
        }
        """,
        expandedSource: """
        struct Message {
            let endpoint: URL

            let content: String

            public enum CodingKeys: String, CodingKey {
                case content
            }

            public init(endpoint: URL, content: String) {
                self.endpoint = endpoint
                self.content = content
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.content = try container.decode(String.self, forKey: .content)
                do {
                    struct TransformKey: CodingKey {
                        var stringValue: String
                        var intValue: Int? { nil }
                        init(stringValue: String) { self.stringValue = stringValue }
                        init?(intValue: Int) { nil }
                    }
                    let transformContainer = try decoder.container(keyedBy: TransformKey.self)
                    let transformer = URLTransform()
                    let jsonValue = try transformContainer.decode(String.self, forKey: TransformKey(stringValue: "endpoint"))
                    self.endpoint = try transformer.decode(jsonValue)
                }
            }

            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(content, forKey: .content)
                do {
                    struct TransformKey: CodingKey {
                        var stringValue: String
                        var intValue: Int? { nil }
                        init(stringValue: String) { self.stringValue = stringValue }
                        init?(intValue: Int) { nil }
                    }
                    var transformContainer = encoder.container(keyedBy: TransformKey.self)
                    let transformer = URLTransform()
                    let jsonValue = try transformer.encode(self.endpoint)
                    try transformContainer.encode(jsonValue, forKey: TransformKey(stringValue: "endpoint"))
                }
            }

            public static func fromDict(_ dict: [String: Any]) throws -> Self {
                let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
                let decoder = JSONDecoder()
                return try decoder.decode(Self.self, from: jsonData)
            }

            public static func fromDictArray(_ array: [[String: Any]]) throws -> [Self] {
                return try array.map { try fromDict($0) }
            }

            public func toDict() throws -> [String: Any] {
                let encoder = JSONEncoder()
                let data = try encoder.encode(self)
                guard let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    throw DictConversionError.invalidDictionaryStructure
                }
                return dict
            }

            public static func toDictArray(_ array: [Self]) throws -> [[String: Any]] {
                return try array.map { try $0.toDict() }
            }
        }

        extension Message: Codable {
        }
        """,
        macros: testMacros
    )
}

@Test("UUID 轉換 - 自訂 key")
func testUUIDTransformWithCustomKey() {
    assertMacroExpansion(
        """
        @Codable
        struct Session {
            @CodingKey("session_id", transform: .uuid)
            let sessionId: UUID
        }
        """,
        expandedSource: """
        struct Session {
            let sessionId: UUID

            public init(sessionId: UUID) {
                self.sessionId = sessionId
            }

            public init(from decoder: Decoder) throws {
                do {
                    struct TransformKey: CodingKey {
                        var stringValue: String
                        var intValue: Int? { nil }
                        init(stringValue: String) { self.stringValue = stringValue }
                        init?(intValue: Int) { nil }
                    }
                    let transformContainer = try decoder.container(keyedBy: TransformKey.self)
                    let transformer = UUIDTransform()
                    let jsonValue = try transformContainer.decode(String.self, forKey: TransformKey(stringValue: "session_id"))
                    self.sessionId = try transformer.decode(jsonValue)
                }
            }

            public func encode(to encoder: Encoder) throws {
                do {
                    struct TransformKey: CodingKey {
                        var stringValue: String
                        var intValue: Int? { nil }
                        init(stringValue: String) { self.stringValue = stringValue }
                        init?(intValue: Int) { nil }
                    }
                    var transformContainer = encoder.container(keyedBy: TransformKey.self)
                    let transformer = UUIDTransform()
                    let jsonValue = try transformer.encode(self.sessionId)
                    try transformContainer.encode(jsonValue, forKey: TransformKey(stringValue: "session_id"))
                }
            }

            public static func fromDict(_ dict: [String: Any]) throws -> Self {
                let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
                let decoder = JSONDecoder()
                return try decoder.decode(Self.self, from: jsonData)
            }

            public static func fromDictArray(_ array: [[String: Any]]) throws -> [Self] {
                return try array.map { try fromDict($0) }
            }

            public func toDict() throws -> [String: Any] {
                let encoder = JSONEncoder()
                let data = try encoder.encode(self)
                guard let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    throw DictConversionError.invalidDictionaryStructure
                }
                return dict
            }

            public static func toDictArray(_ array: [Self]) throws -> [[String: Any]] {
                return try array.map { try $0.toDict() }
            }
        }

        extension Session: Codable {
        }
        """,
        macros: testMacros
    )
}

@Test("Optional URL 轉換")
func testOptionalURLTransform() {
    assertMacroExpansion(
        """
        @Codable
        struct Profile {
            @CodingKey("avatar_url", transform: .url)
            let avatarUrl: URL?
        }
        """,
        expandedSource: """
        struct Profile {
            let avatarUrl: URL?

            public init(avatarUrl: URL? = nil) {
                self.avatarUrl = avatarUrl
            }

            public init(from decoder: Decoder) throws {
                do {
                    struct TransformKey: CodingKey {
                        var stringValue: String
                        var intValue: Int? { nil }
                        init(stringValue: String) { self.stringValue = stringValue }
                        init?(intValue: Int) { nil }
                    }
                    let transformContainer = try decoder.container(keyedBy: TransformKey.self)
                    let transformer = URLTransform()
                    if let jsonValue = try transformContainer.decodeIfPresent(String.self, forKey: TransformKey(stringValue: "avatar_url")) {
                        self.avatarUrl = try transformer.decode(jsonValue)
                    } else {
                        self.avatarUrl = nil
                    }
                }
            }

            public func encode(to encoder: Encoder) throws {
                do {
                    struct TransformKey: CodingKey {
                        var stringValue: String
                        var intValue: Int? { nil }
                        init(stringValue: String) { self.stringValue = stringValue }
                        init?(intValue: Int) { nil }
                    }
                    var transformContainer = encoder.container(keyedBy: TransformKey.self)
                    let transformer = URLTransform()
                    if let value = self.avatarUrl {
                        let jsonValue = try transformer.encode(value)
                        try transformContainer.encode(jsonValue, forKey: TransformKey(stringValue: "avatar_url"))
                    }
                }
            }

            public static func fromDict(_ dict: [String: Any]) throws -> Self {
                let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
                let decoder = JSONDecoder()
                return try decoder.decode(Self.self, from: jsonData)
            }

            public static func fromDictArray(_ array: [[String: Any]]) throws -> [Self] {
                return try array.map { try fromDict($0) }
            }

            public func toDict() throws -> [String: Any] {
                let encoder = JSONEncoder()
                let data = try encoder.encode(self)
                guard let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    throw DictConversionError.invalidDictionaryStructure
                }
                return dict
            }

            public static func toDictArray(_ array: [Self]) throws -> [[String: Any]] {
                return try array.map { try $0.toDict() }
            }
        }

        extension Profile: Codable {
        }
        """,
        macros: testMacros
    )
}

@Test("混合 transform 和普通屬性")
func testMixedTransformAndNormalProperties() {
    assertMacroExpansion(
        """
        @Codable
        struct AgentMessage {
            @CodingKey("workspace", transform: .url)
            let workspace: URL

            @CodingKey("session_id", transform: .uuid)
            let sessionId: UUID

            let content: String
            let priority: Int
        }
        """,
        expandedSource: """
        struct AgentMessage {
            let workspace: URL

            let sessionId: UUID

            let content: String
            let priority: Int

            public enum CodingKeys: String, CodingKey {
                case content
                case priority
            }

            public init(workspace: URL, sessionId: UUID, content: String, priority: Int) {
                self.workspace = workspace
                self.sessionId = sessionId
                self.content = content
                self.priority = priority
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.content = try container.decode(String.self, forKey: .content)
                self.priority = try container.decode(Int.self, forKey: .priority)
                do {
                    struct TransformKey: CodingKey {
                        var stringValue: String
                        var intValue: Int? { nil }
                        init(stringValue: String) { self.stringValue = stringValue }
                        init?(intValue: Int) { nil }
                    }
                    let transformContainer = try decoder.container(keyedBy: TransformKey.self)
                    let transformer = URLTransform()
                    let jsonValue = try transformContainer.decode(String.self, forKey: TransformKey(stringValue: "workspace"))
                    self.workspace = try transformer.decode(jsonValue)
                }
                do {
                    struct TransformKey: CodingKey {
                        var stringValue: String
                        var intValue: Int? { nil }
                        init(stringValue: String) { self.stringValue = stringValue }
                        init?(intValue: Int) { nil }
                    }
                    let transformContainer = try decoder.container(keyedBy: TransformKey.self)
                    let transformer = UUIDTransform()
                    let jsonValue = try transformContainer.decode(String.self, forKey: TransformKey(stringValue: "session_id"))
                    self.sessionId = try transformer.decode(jsonValue)
                }
            }

            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(content, forKey: .content)
                try container.encode(priority, forKey: .priority)
                do {
                    struct TransformKey: CodingKey {
                        var stringValue: String
                        var intValue: Int? { nil }
                        init(stringValue: String) { self.stringValue = stringValue }
                        init?(intValue: Int) { nil }
                    }
                    var transformContainer = encoder.container(keyedBy: TransformKey.self)
                    let transformer = URLTransform()
                    let jsonValue = try transformer.encode(self.workspace)
                    try transformContainer.encode(jsonValue, forKey: TransformKey(stringValue: "workspace"))
                }
                do {
                    struct TransformKey: CodingKey {
                        var stringValue: String
                        var intValue: Int? { nil }
                        init(stringValue: String) { self.stringValue = stringValue }
                        init?(intValue: Int) { nil }
                    }
                    var transformContainer = encoder.container(keyedBy: TransformKey.self)
                    let transformer = UUIDTransform()
                    let jsonValue = try transformer.encode(self.sessionId)
                    try transformContainer.encode(jsonValue, forKey: TransformKey(stringValue: "session_id"))
                }
            }

            public static func fromDict(_ dict: [String: Any]) throws -> Self {
                let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
                let decoder = JSONDecoder()
                return try decoder.decode(Self.self, from: jsonData)
            }

            public static func fromDictArray(_ array: [[String: Any]]) throws -> [Self] {
                return try array.map { try fromDict($0) }
            }

            public func toDict() throws -> [String: Any] {
                let encoder = JSONEncoder()
                let data = try encoder.encode(self)
                guard let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    throw DictConversionError.invalidDictionaryStructure
                }
                return dict
            }

            public static func toDictArray(_ array: [Self]) throws -> [[String: Any]] {
                return try array.map { try $0.toDict() }
            }
        }

        extension AgentMessage: Codable {
        }
        """,
        macros: testMacros
    )
}

@Test("Date 轉換 - Timestamp")
func testTimestampDateTransform() {
    assertMacroExpansion(
        """
        @Codable
        struct Event {
            @CodingKey(transform: .timestampDate)
            let createdAt: Date
        }
        """,
        expandedSource: """
        struct Event {
            let createdAt: Date

            public init(createdAt: Date) {
                self.createdAt = createdAt
            }

            public init(from decoder: Decoder) throws {
                do {
                    struct TransformKey: CodingKey {
                        var stringValue: String
                        var intValue: Int? { nil }
                        init(stringValue: String) { self.stringValue = stringValue }
                        init?(intValue: Int) { nil }
                    }
                    let transformContainer = try decoder.container(keyedBy: TransformKey.self)
                    let transformer = TimestampDateTransform()
                    let jsonValue = try transformContainer.decode(Double.self, forKey: TransformKey(stringValue: "createdAt"))
                    self.createdAt = try transformer.decode(jsonValue)
                }
            }

            public func encode(to encoder: Encoder) throws {
                do {
                    struct TransformKey: CodingKey {
                        var stringValue: String
                        var intValue: Int? { nil }
                        init(stringValue: String) { self.stringValue = stringValue }
                        init?(intValue: Int) { nil }
                    }
                    var transformContainer = encoder.container(keyedBy: TransformKey.self)
                    let transformer = TimestampDateTransform()
                    let jsonValue = try transformer.encode(self.createdAt)
                    try transformContainer.encode(jsonValue, forKey: TransformKey(stringValue: "createdAt"))
                }
            }

            public static func fromDict(_ dict: [String: Any]) throws -> Self {
                let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
                let decoder = JSONDecoder()
                return try decoder.decode(Self.self, from: jsonData)
            }

            public static func fromDictArray(_ array: [[String: Any]]) throws -> [Self] {
                return try array.map { try fromDict($0) }
            }

            public func toDict() throws -> [String: Any] {
                let encoder = JSONEncoder()
                let data = try encoder.encode(self)
                guard let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    throw DictConversionError.invalidDictionaryStructure
                }
                return dict
            }

            public static func toDictArray(_ array: [Self]) throws -> [[String: Any]] {
                return try array.map { try $0.toDict() }
            }
        }

        extension Event: Codable {
        }
        """,
        macros: testMacros
    )
}

@Test("Bool Int 轉換")
func testBoolIntTransform() {
    assertMacroExpansion(
        """
        @Codable
        struct Config {
            @CodingKey(transform: .boolInt)
            let enabled: Bool
        }
        """,
        expandedSource: """
        struct Config {
            let enabled: Bool

            public init(enabled: Bool) {
                self.enabled = enabled
            }

            public init(from decoder: Decoder) throws {
                do {
                    struct TransformKey: CodingKey {
                        var stringValue: String
                        var intValue: Int? { nil }
                        init(stringValue: String) { self.stringValue = stringValue }
                        init?(intValue: Int) { nil }
                    }
                    let transformContainer = try decoder.container(keyedBy: TransformKey.self)
                    let transformer = BoolIntTransform()
                    let jsonValue = try transformContainer.decode(Int.self, forKey: TransformKey(stringValue: "enabled"))
                    self.enabled = try transformer.decode(jsonValue)
                }
            }

            public func encode(to encoder: Encoder) throws {
                do {
                    struct TransformKey: CodingKey {
                        var stringValue: String
                        var intValue: Int? { nil }
                        init(stringValue: String) { self.stringValue = stringValue }
                        init?(intValue: Int) { nil }
                    }
                    var transformContainer = encoder.container(keyedBy: TransformKey.self)
                    let transformer = BoolIntTransform()
                    let jsonValue = try transformer.encode(self.enabled)
                    try transformContainer.encode(jsonValue, forKey: TransformKey(stringValue: "enabled"))
                }
            }

            public static func fromDict(_ dict: [String: Any]) throws -> Self {
                let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
                let decoder = JSONDecoder()
                return try decoder.decode(Self.self, from: jsonData)
            }

            public static func fromDictArray(_ array: [[String: Any]]) throws -> [Self] {
                return try array.map { try fromDict($0) }
            }

            public func toDict() throws -> [String: Any] {
                let encoder = JSONEncoder()
                let data = try encoder.encode(self)
                guard let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    throw DictConversionError.invalidDictionaryStructure
                }
                return dict
            }

            public static func toDictArray(_ array: [Self]) throws -> [[String: Any]] {
                return try array.map { try $0.toDict() }
            }
        }

        extension Config: Codable {
        }
        """,
        macros: testMacros
    )
}
