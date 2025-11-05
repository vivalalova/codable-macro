import Testing
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Foundation

@testable import CodableMacroMacros

let complexTestMacros: [String: Macro.Type] = [
    "Codable": CodableMacro.self,
    "CodingKey": CodingKeyMacro.self,
    "CodingIgnored": CodingIgnoredMacro.self,
]

// MARK: - 複雜使用案例測試

/// 測試多種功能組合的複雜使用情況
struct ComplexUseCaseTests {

    // MARK: - Transform + Nested KeyPath 組合

    @Test("Transform + Nested KeyPath - URL 從巢狀路徑轉換")
    func testTransformWithNestedKeyPath() {
        assertMacroExpansion(
            """
            @Codable
            struct APIConfig {
                @CodingKey("server.endpoint", transform: .url)
                let endpoint: URL

                let apiKey: String
            }
            """,
            expandedSource: """
            struct APIConfig {
                let endpoint: URL

                let apiKey: String

                public enum CodingKeys: String, CodingKey {
                    case apiKey
                }

                public init(endpoint: URL, apiKey: String) {
                    self.endpoint = endpoint
                    self.apiKey = apiKey
                }

                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.apiKey = try container.decode(String.self, forKey: .apiKey)
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        let rootContainer = try decoder.container(keyedBy: DynamicKey.self)
                        let container1 = try rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "server"))
                        let transformer = URLTransform()
                        let jsonValue = try container1.decode(String.self, forKey: DynamicKey(stringValue: "endpoint"))
                        self.endpoint = try transformer.decode(jsonValue)
                    }
                }

                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(apiKey, forKey: .apiKey)
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        var rootContainer = encoder.container(keyedBy: DynamicKey.self)
                        var container1 = rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "server"))
                        let transformer = URLTransform()
                        let jsonValue = try transformer.encode(self.endpoint)
                        try container1.encode(jsonValue, forKey: DynamicKey(stringValue: "endpoint"))
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

            extension APIConfig: Codable {
            }
            """,
            macros: complexTestMacros
        )
    }

    @Test("Transform + Nested KeyPath - 深層巢狀")
    func testTransformWithDeepNestedKeyPath() {
        assertMacroExpansion(
            """
            @Codable
            struct UserProfile {
                @CodingKey("data.user.profile.avatar", transform: .url)
                let avatarUrl: URL

                @CodingKey("data.user.id", transform: .uuid)
                let userId: UUID
            }
            """,
            expandedSource: """
            struct UserProfile {
                let avatarUrl: URL

                let userId: UUID

                public init(avatarUrl: URL, userId: UUID) {
                    self.avatarUrl = avatarUrl
                    self.userId = userId
                }

                public init(from decoder: Decoder) throws {
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        let rootContainer = try decoder.container(keyedBy: DynamicKey.self)
                        let container1 = try rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "data"))
                        let container2 = try container1.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "user"))
                        let container3 = try container2.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "profile"))
                        let transformer = URLTransform()
                        let jsonValue = try container3.decode(String.self, forKey: DynamicKey(stringValue: "avatar"))
                        self.avatarUrl = try transformer.decode(jsonValue)
                    }
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        let rootContainer = try decoder.container(keyedBy: DynamicKey.self)
                        let container1 = try rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "data"))
                        let container2 = try container1.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "user"))
                        let transformer = UUIDTransform()
                        let jsonValue = try container2.decode(String.self, forKey: DynamicKey(stringValue: "id"))
                        self.userId = try transformer.decode(jsonValue)
                    }
                }

                public func encode(to encoder: Encoder) throws {
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        var rootContainer = encoder.container(keyedBy: DynamicKey.self)
                        var container1 = rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "data"))
                        var container2 = container1.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "user"))
                        var container3 = container2.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "profile"))
                        let transformer = URLTransform()
                        let jsonValue = try transformer.encode(self.avatarUrl)
                        try container3.encode(jsonValue, forKey: DynamicKey(stringValue: "avatar"))
                    }
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        var rootContainer = encoder.container(keyedBy: DynamicKey.self)
                        var container1 = rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "data"))
                        var container2 = container1.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "user"))
                        let transformer = UUIDTransform()
                        let jsonValue = try transformer.encode(self.userId)
                        try container2.encode(jsonValue, forKey: DynamicKey(stringValue: "id"))
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

            extension UserProfile: Codable {
            }
            """,
            macros: complexTestMacros
        )
    }

    // MARK: - Transform + Optional + Nested KeyPath 組合

    @Test("Transform + Optional + Nested KeyPath - 三重組合")
    func testTransformOptionalNestedKeyPath() {
        assertMacroExpansion(
            """
            @Codable
            struct Profile {
                @CodingKey("user.avatar", transform: .url)
                let avatar: URL?

                let name: String
            }
            """,
            expandedSource: """
            struct Profile {
                let avatar: URL?

                let name: String

                public enum CodingKeys: String, CodingKey {
                    case name
                }

                public init(avatar: URL? = nil, name: String) {
                    self.avatar = avatar
                    self.name = name
                }

                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.name = try container.decode(String.self, forKey: .name)
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        let rootContainer = try decoder.container(keyedBy: DynamicKey.self)
                        let container1 = try rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "user"))
                        let transformer = URLTransform()
                        if let jsonValue = try container1.decodeIfPresent(String.self, forKey: DynamicKey(stringValue: "avatar")) {
                            self.avatar = try transformer.decode(jsonValue)
                        } else {
                            self.avatar = nil
                        }
                    }
                }

                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(name, forKey: .name)
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        var rootContainer = encoder.container(keyedBy: DynamicKey.self)
                        var container1 = rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "user"))
                        let transformer = URLTransform()
                        if let value = self.avatar {
                            let jsonValue = try transformer.encode(value)
                            try container1.encode(jsonValue, forKey: DynamicKey(stringValue: "avatar"))
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
            macros: complexTestMacros
        )
    }

    // MARK: - Transform + Default Value 組合

    @Test("Transform + Default Value - URL 帶預設值")
    func testTransformWithDefaultValue() {
        assertMacroExpansion(
            """
            @Codable
            struct ServerConfig {
                @CodingKey(transform: .url)
                let endpoint: URL = URL(string: "https://api.example.com")!

                let apiKey: String
            }
            """,
            expandedSource: """
            struct ServerConfig {
                let endpoint: URL = URL(string: "https://api.example.com")!

                let apiKey: String

                public enum CodingKeys: String, CodingKey {
                    case apiKey
                }

                public init(apiKey: String) {
                    self.apiKey = apiKey
                }

                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.apiKey = try container.decode(String.self, forKey: .apiKey)
                }

                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(apiKey, forKey: .apiKey)
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

            extension ServerConfig: Codable {
            }
            """,
            macros: complexTestMacros
        )
    }

    // MARK: - Nested KeyPath + Default Value 組合

    @Test("Nested KeyPath + Default Value - 巢狀路徑帶預設值")
    func testNestedKeyPathWithDefaultValue() {
        assertMacroExpansion(
            """
            @Codable
            struct AppSettings {
                @CodingKey("config.timeout")
                let timeout: Int = 30

                let appName: String
            }
            """,
            expandedSource: """
            struct AppSettings {
                let timeout: Int = 30

                let appName: String

                enum CodingKeys: String, CodingKey {
                    case appName
                }

                init(appName: String) {
                    self.appName = appName
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.appName = try container.decode(String.self, forKey: .appName)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(appName, forKey: .appName)
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        var rootContainer = encoder.container(keyedBy: DynamicKey.self)
                        var container1 = rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "config"))
                        try container1.encode(timeout, forKey: DynamicKey(stringValue: "timeout"))
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

            extension AppSettings: Codable {
            }
            """,
            macros: complexTestMacros
        )
    }

    // MARK: - 大型混合場景

    @Test("大型混合場景 - 所有功能組合")
    func testLargeComplexMixedScenario() {
        assertMacroExpansion(
            """
            @Codable
            struct ComplexAPIResponse {
                // 普通屬性
                let id: String
                let status: String

                // Transform
                @CodingKey(transform: .uuid)
                let sessionId: UUID

                // Nested KeyPath
                @CodingKey("data.user.name")
                let userName: String

                // Transform + Nested
                @CodingKey("data.server.endpoint", transform: .url)
                let serverUrl: URL

                // Optional
                let message: String?

                // Transform + Optional
                @CodingKey(transform: .url)
                let avatarUrl: URL?

                // Nested + Optional
                @CodingKey("data.user.email")
                let userEmail: String?

                // Default Value
                let retryCount: Int = 3

                // Transform + Default
                @CodingKey(transform: .boolInt)
                let enabled: Bool = true

                // Nested + Default
                @CodingKey("config.timeout")
                let timeout: Int = 30

                // Ignored
                @CodingIgnored
                var cachedData: String?
            }
            """,
            expandedSource: """
            struct ComplexAPIResponse {
                // 普通屬性
                let id: String
                let status: String

                // Transform
                let sessionId: UUID

                // Nested KeyPath
                let userName: String

                // Transform + Nested
                let serverUrl: URL

                // Optional
                let message: String?

                // Transform + Optional
                let avatarUrl: URL?

                // Nested + Optional
                let userEmail: String?

                // Default Value
                let retryCount: Int = 3

                // Transform + Default
                let enabled: Bool = true

                // Nested + Default
                let timeout: Int = 30

                // Ignored
                var cachedData: String?

                public enum CodingKeys: String, CodingKey {
                    case id
                    case status
                    case message
                }

                public init(sessionId: UUID, userName: String, serverUrl: URL, avatarUrl: URL? = nil, userEmail: String? = nil, id: String, status: String, message: String? = nil) {
                    self.sessionId = sessionId
                    self.userName = userName
                    self.serverUrl = serverUrl
                    self.avatarUrl = avatarUrl
                    self.userEmail = userEmail
                    self.id = id
                    self.status = status
                    self.message = message
                }

                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.id = try container.decode(String.self, forKey: .id)
                    self.status = try container.decode(String.self, forKey: .status)
                    self.message = try container.decodeIfPresent(String.self, forKey: .message)
                    do {
                        struct TransformKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        let transformContainer = try decoder.container(keyedBy: TransformKey.self)
                        let transformer = UUIDTransform()
                        let jsonValue = try transformContainer.decode(String.self, forKey: TransformKey(stringValue: "sessionId"))
                        self.sessionId = try transformer.decode(jsonValue)
                    }
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        let rootContainer = try decoder.container(keyedBy: DynamicKey.self)
                        let container1 = try rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "data"))
                        let container2 = try container1.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "user"))
                        self.userName = try container2.decode(String.self, forKey: DynamicKey(stringValue: "name"))
                    }
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        let rootContainer = try decoder.container(keyedBy: DynamicKey.self)
                        let container1 = try rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "data"))
                        let container2 = try container1.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "server"))
                        let transformer = URLTransform()
                        let jsonValue = try container2.decode(String.self, forKey: DynamicKey(stringValue: "endpoint"))
                        self.serverUrl = try transformer.decode(jsonValue)
                    }
                    do {
                        struct TransformKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        let transformContainer = try decoder.container(keyedBy: TransformKey.self)
                        let transformer = URLTransform()
                        if let jsonValue = try transformContainer.decodeIfPresent(String.self, forKey: TransformKey(stringValue: "avatarUrl")) {
                            self.avatarUrl = try transformer.decode(jsonValue)
                        } else {
                            self.avatarUrl = nil
                        }
                    }
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        let rootContainer = try decoder.container(keyedBy: DynamicKey.self)
                        let container1 = try rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "data"))
                        let container2 = try container1.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "user"))
                        self.userEmail = try container2.decodeIfPresent(String.self, forKey: DynamicKey(stringValue: "email"))
                    }
                }

                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(id, forKey: .id)
                    try container.encode(status, forKey: .status)
                    try container.encodeIfPresent(message, forKey: .message)
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
                        try transformContainer.encode(jsonValue, forKey: TransformKey(stringValue: "sessionId"))
                    }
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        var rootContainer = encoder.container(keyedBy: DynamicKey.self)
                        var container1 = rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "data"))
                        var container2 = container1.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "user"))
                        try container2.encode(userName, forKey: DynamicKey(stringValue: "name"))
                    }
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        var rootContainer = encoder.container(keyedBy: DynamicKey.self)
                        var container1 = rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "data"))
                        var container2 = container1.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "server"))
                        let transformer = URLTransform()
                        let jsonValue = try transformer.encode(self.serverUrl)
                        try container2.encode(jsonValue, forKey: DynamicKey(stringValue: "endpoint"))
                    }
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
                            try transformContainer.encode(jsonValue, forKey: TransformKey(stringValue: "avatarUrl"))
                        }
                    }
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        var rootContainer = encoder.container(keyedBy: DynamicKey.self)
                        var container1 = rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "data"))
                        var container2 = container1.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "user"))
                        if let userEmail = self.userEmail {
                            try container2.encode(userEmail, forKey: DynamicKey(stringValue: "email"))
                        }
                    }
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        var rootContainer = encoder.container(keyedBy: DynamicKey.self)
                        var container1 = rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "config"))
                        try container1.encode(timeout, forKey: DynamicKey(stringValue: "timeout"))
                    }
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

            extension ComplexAPIResponse: Codable {
            }
            """,
            macros: complexTestMacros
        )
    }

    // MARK: - 同一巢狀物件多屬性提取

    @Test("從同一巢狀物件提取多個屬性")
    func testMultiplePropertiesFromSameNestedObject() {
        assertMacroExpansion(
            """
            @Codable
            struct UserData {
                @CodingKey("user.firstName")
                let firstName: String

                @CodingKey("user.lastName")
                let lastName: String

                @CodingKey("user.age")
                let age: Int

                let id: String
            }
            """,
            expandedSource: """
            struct UserData {
                let firstName: String

                let lastName: String

                let age: Int

                let id: String

                enum CodingKeys: String, CodingKey {
                    case id
                }

                init(firstName: String, lastName: String, age: Int, id: String) {
                    self.firstName = firstName
                    self.lastName = lastName
                    self.age = age
                    self.id = id
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.id = try container.decode(String.self, forKey: .id)
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        let rootContainer = try decoder.container(keyedBy: DynamicKey.self)
                        let container1 = try rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "user"))
                        self.firstName = try container1.decode(String.self, forKey: DynamicKey(stringValue: "firstName"))
                    }
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        let rootContainer = try decoder.container(keyedBy: DynamicKey.self)
                        let container1 = try rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "user"))
                        self.lastName = try container1.decode(String.self, forKey: DynamicKey(stringValue: "lastName"))
                    }
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        let rootContainer = try decoder.container(keyedBy: DynamicKey.self)
                        let container1 = try rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "user"))
                        self.age = try container1.decode(Int.self, forKey: DynamicKey(stringValue: "age"))
                    }
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(id, forKey: .id)
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        var rootContainer = encoder.container(keyedBy: DynamicKey.self)
                        var container1 = rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "user"))
                        try container1.encode(firstName, forKey: DynamicKey(stringValue: "firstName"))
                    }
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        var rootContainer = encoder.container(keyedBy: DynamicKey.self)
                        var container1 = rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "user"))
                        try container1.encode(lastName, forKey: DynamicKey(stringValue: "lastName"))
                    }
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        var rootContainer = encoder.container(keyedBy: DynamicKey.self)
                        var container1 = rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "user"))
                        try container1.encode(age, forKey: DynamicKey(stringValue: "age"))
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

            extension UserData: Codable {
            }
            """,
            macros: complexTestMacros
        )
    }

    // MARK: - 多種轉換器混合使用

    @Test("多種轉換器在同一 struct 中使用")
    func testMultipleTransformersInStruct() {
        assertMacroExpansion(
            """
            @Codable
            struct ComplexData {
                @CodingKey(transform: .url)
                let homepage: URL

                @CodingKey(transform: .uuid)
                let userId: UUID

                @CodingKey(transform: .timestampDate)
                let createdAt: Date

                @CodingKey(transform: .boolInt)
                let isActive: Bool
            }
            """,
            expandedSource: """
            struct ComplexData {
                let homepage: URL

                let userId: UUID

                let createdAt: Date

                let isActive: Bool

                public init(homepage: URL, userId: UUID, createdAt: Date, isActive: Bool) {
                    self.homepage = homepage
                    self.userId = userId
                    self.createdAt = createdAt
                    self.isActive = isActive
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
                        let jsonValue = try transformContainer.decode(String.self, forKey: TransformKey(stringValue: "homepage"))
                        self.homepage = try transformer.decode(jsonValue)
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
                        let jsonValue = try transformContainer.decode(String.self, forKey: TransformKey(stringValue: "userId"))
                        self.userId = try transformer.decode(jsonValue)
                    }
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
                    do {
                        struct TransformKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        let transformContainer = try decoder.container(keyedBy: TransformKey.self)
                        let transformer = BoolIntTransform()
                        let jsonValue = try transformContainer.decode(Int.self, forKey: TransformKey(stringValue: "isActive"))
                        self.isActive = try transformer.decode(jsonValue)
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
                        let jsonValue = try transformer.encode(self.homepage)
                        try transformContainer.encode(jsonValue, forKey: TransformKey(stringValue: "homepage"))
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
                        let jsonValue = try transformer.encode(self.userId)
                        try transformContainer.encode(jsonValue, forKey: TransformKey(stringValue: "userId"))
                    }
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
                    do {
                        struct TransformKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        var transformContainer = encoder.container(keyedBy: TransformKey.self)
                        let transformer = BoolIntTransform()
                        let jsonValue = try transformer.encode(self.isActive)
                        try transformContainer.encode(jsonValue, forKey: TransformKey(stringValue: "isActive"))
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

            extension ComplexData: Codable {
            }
            """,
            macros: complexTestMacros
        )
    }
}
