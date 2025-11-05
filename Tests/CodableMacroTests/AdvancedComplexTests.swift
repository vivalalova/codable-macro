import Testing
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Foundation

@testable import CodableMacroMacros

let advancedTestMacros: [String: Macro.Type] = [
    "Codable": CodableMacro.self,
    "CodingKey": CodingKeyMacro.self,
    "CodingIgnored": CodingIgnoredMacro.self,
]

// MARK: - 進階複雜使用案例測試

/// 測試更進階和邊界情況的複雜使用案例
struct AdvancedComplexTests {

    // MARK: - 集合類型 + Transform

    @Test("陣列類型轉換 - [URL]")
    func testArrayTransform() {
        assertMacroExpansion(
            """
            @Codable
            struct MediaGallery {
                @CodingKey(transform: .url)
                let images: [URL]

                let title: String
            }
            """,
            expandedSource: """
            struct MediaGallery {
                let images: [URL]

                let title: String

                public enum CodingKeys: String, CodingKey {
                    case title
                }

                public init(images: [URL], title: String) {
                    self.images = images
                    self.title = title
                }

                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.title = try container.decode(String.self, forKey: .title)
                    do {
                        struct TransformKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        let transformContainer = try decoder.container(keyedBy: TransformKey.self)
                        let transformer = URLTransform()
                        let jsonValue = try transformContainer.decode([String].self, forKey: TransformKey(stringValue: "images"))
                        self.images = try jsonValue.map { try transformer.decode($0) }
                    }
                }

                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(title, forKey: .title)
                    do {
                        struct TransformKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        var transformContainer = encoder.container(keyedBy: TransformKey.self)
                        let transformer = URLTransform()
                        let jsonValue = try self.images.map { try transformer.encode($0) }
                        try transformContainer.encode(jsonValue, forKey: TransformKey(stringValue: "images"))
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

            extension MediaGallery: Codable {
            }
            """,
            macros: advancedTestMacros
        )
    }

    @Test("Optional 陣列類型轉換 - [UUID]?")
    func testOptionalArrayTransform() {
        assertMacroExpansion(
            """
            @Codable
            struct Session {
                @CodingKey(transform: .uuid)
                let participantIds: [UUID]?
            }
            """,
            expandedSource: """
            struct Session {
                let participantIds: [UUID]?

                public init(participantIds: [UUID]? = nil) {
                    self.participantIds = participantIds
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
                        if let jsonValue = try transformContainer.decodeIfPresent([String].self, forKey: TransformKey(stringValue: "participantIds")) {
                            self.participantIds = try jsonValue.map { try transformer.decode($0) }
                        } else {
                            self.participantIds = nil
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
                        let transformer = UUIDTransform()
                        if let value = self.participantIds {
                            let jsonValue = try value.map { try transformer.encode($0) }
                            try transformContainer.encode(jsonValue, forKey: TransformKey(stringValue: "participantIds"))
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

            extension Session: Codable {
            }
            """,
            macros: advancedTestMacros
        )
    }

    // MARK: - 極端深層巢狀

    @Test("極端深層巢狀 - 5 層路徑")
    func testVeryDeepNesting() {
        assertMacroExpansion(
            """
            @Codable
            struct DeepData {
                @CodingKey("level1.level2.level3.level4.value")
                let deepValue: String

                let id: String
            }
            """,
            expandedSource: """
            struct DeepData {
                let deepValue: String

                let id: String

                enum CodingKeys: String, CodingKey {
                    case id
                }

                init(deepValue: String, id: String) {
                    self.deepValue = deepValue
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
                        let container1 = try rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "level1"))
                        let container2 = try container1.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "level2"))
                        let container3 = try container2.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "level3"))
                        let container4 = try container3.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "level4"))
                        self.deepValue = try container4.decode(String.self, forKey: DynamicKey(stringValue: "value"))
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
                        var container1 = rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "level1"))
                        var container2 = container1.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "level2"))
                        var container3 = container2.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "level3"))
                        var container4 = container3.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "level4"))
                        try container4.encode(deepValue, forKey: DynamicKey(stringValue: "value"))
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

            extension DeepData: Codable {
            }
            """,
            macros: advancedTestMacros
        )
    }

    @Test("相同前綴不同深度的巢狀路徑")
    func testMixedDepthNestedPaths() {
        assertMacroExpansion(
            """
            @Codable
            struct UserInfo {
                @CodingKey("user.name")
                let name: String

                @CodingKey("user.profile.avatar")
                let avatar: String

                @CodingKey("user.profile.bio")
                let bio: String?
            }
            """,
            expandedSource: """
            struct UserInfo {
                let name: String

                let avatar: String

                let bio: String?

                init(name: String, avatar: String, bio: String? = nil) {
                    self.name = name
                    self.avatar = avatar
                    self.bio = bio
                }

                init(from decoder: Decoder) throws {
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        let rootContainer = try decoder.container(keyedBy: DynamicKey.self)
                        let container1 = try rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "user"))
                        self.name = try container1.decode(String.self, forKey: DynamicKey(stringValue: "name"))
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
                        let container2 = try container1.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "profile"))
                        self.avatar = try container2.decode(String.self, forKey: DynamicKey(stringValue: "avatar"))
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
                        let container2 = try container1.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "profile"))
                        self.bio = try container2.decodeIfPresent(String.self, forKey: DynamicKey(stringValue: "bio"))
                    }
                }

                func encode(to encoder: Encoder) throws {
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        var rootContainer = encoder.container(keyedBy: DynamicKey.self)
                        var container1 = rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "user"))
                        try container1.encode(name, forKey: DynamicKey(stringValue: "name"))
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
                        var container2 = container1.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "profile"))
                        try container2.encode(avatar, forKey: DynamicKey(stringValue: "avatar"))
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
                        var container2 = container1.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "profile"))
                        if let bio = self.bio {
                            try container2.encode(bio, forKey: DynamicKey(stringValue: "bio"))
                        }
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

            extension UserInfo: Codable {
            }
            """,
            macros: advancedTestMacros
        )
    }

    // MARK: - 所有屬性都使用特殊功能

    @Test("所有屬性都是巢狀路徑")
    func testAllPropertiesNested() {
        assertMacroExpansion(
            """
            @Codable
            struct FlattenedData {
                @CodingKey("data.id")
                let id: String

                @CodingKey("data.name")
                let name: String

                @CodingKey("meta.timestamp")
                let timestamp: Int
            }
            """,
            expandedSource: """
            struct FlattenedData {
                let id: String

                let name: String

                let timestamp: Int

                init(id: String, name: String, timestamp: Int) {
                    self.id = id
                    self.name = name
                    self.timestamp = timestamp
                }

                init(from decoder: Decoder) throws {
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        let rootContainer = try decoder.container(keyedBy: DynamicKey.self)
                        let container1 = try rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "data"))
                        self.id = try container1.decode(String.self, forKey: DynamicKey(stringValue: "id"))
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
                        self.name = try container1.decode(String.self, forKey: DynamicKey(stringValue: "name"))
                    }
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        let rootContainer = try decoder.container(keyedBy: DynamicKey.self)
                        let container1 = try rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "meta"))
                        self.timestamp = try container1.decode(Int.self, forKey: DynamicKey(stringValue: "timestamp"))
                    }
                }

                func encode(to encoder: Encoder) throws {
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        var rootContainer = encoder.container(keyedBy: DynamicKey.self)
                        var container1 = rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "data"))
                        try container1.encode(id, forKey: DynamicKey(stringValue: "id"))
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
                        try container1.encode(name, forKey: DynamicKey(stringValue: "name"))
                    }
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        var rootContainer = encoder.container(keyedBy: DynamicKey.self)
                        var container1 = rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "meta"))
                        try container1.encode(timestamp, forKey: DynamicKey(stringValue: "timestamp"))
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

            extension FlattenedData: Codable {
            }
            """,
            macros: advancedTestMacros
        )
    }

    @Test("所有屬性都需要轉換")
    func testAllPropertiesWithTransform() {
        assertMacroExpansion(
            """
            @Codable
            struct TransformOnly {
                @CodingKey(transform: .url)
                let homepage: URL

                @CodingKey(transform: .uuid)
                let userId: UUID

                @CodingKey(transform: .boolInt)
                let isActive: Bool
            }
            """,
            expandedSource: """
            struct TransformOnly {
                let homepage: URL

                let userId: UUID

                let isActive: Bool

                public init(homepage: URL, userId: UUID, isActive: Bool) {
                    self.homepage = homepage
                    self.userId = userId
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

            extension TransformOnly: Codable {
            }
            """,
            macros: advancedTestMacros
        )
    }

    // MARK: - 實際應用場景

    @Test("實際應用 - GitHub API Response")
    func testGitHubAPIResponse() {
        assertMacroExpansion(
            """
            @Codable
            struct GitHubRepo {
                let id: Int
                let name: String

                @CodingKey("full_name")
                let fullName: String

                @CodingKey("html_url", transform: .url)
                let htmlUrl: URL

                @CodingKey("owner.login")
                let ownerLogin: String

                @CodingKey("owner.avatar_url", transform: .url)
                let ownerAvatar: URL?

                @CodingKey("created_at", transform: .iso8601Date)
                let createdAt: Date

                let description: String?

                @CodingKey("stargazers_count")
                let stars: Int

                @CodingKey("is_private")
                let isPrivate: Bool = false

                @CodingIgnored
                var isFavorite: Bool = false
            }
            """,
            expandedSource: """
            struct GitHubRepo {
                let id: Int
                let name: String

                let fullName: String

                let htmlUrl: URL

                let ownerLogin: String

                let ownerAvatar: URL?

                let createdAt: Date

                let description: String?

                let stars: Int

                let isPrivate: Bool = false

                var isFavorite: Bool = false

                public enum CodingKeys: String, CodingKey {
                    case id
                    case name
                    case fullName = "full_name"
                    case description
                    case stars = "stargazers_count"
                }

                public init(htmlUrl: URL, ownerLogin: String, ownerAvatar: URL? = nil, createdAt: Date, id: Int, name: String, fullName: String, description: String? = nil, stars: Int) {
                    self.htmlUrl = htmlUrl
                    self.ownerLogin = ownerLogin
                    self.ownerAvatar = ownerAvatar
                    self.createdAt = createdAt
                    self.id = id
                    self.name = name
                    self.fullName = fullName
                    self.description = description
                    self.stars = stars
                    self.isFavorite = false
                }

                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.id = try container.decode(Int.self, forKey: .id)
                    self.name = try container.decode(String.self, forKey: .name)
                    self.fullName = try container.decode(String.self, forKey: .fullName)
                    self.description = try container.decodeIfPresent(String.self, forKey: .description)
                    self.stars = try container.decode(Int.self, forKey: .stars)
                    do {
                        struct TransformKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        let transformContainer = try decoder.container(keyedBy: TransformKey.self)
                        let transformer = URLTransform()
                        let jsonValue = try transformContainer.decode(String.self, forKey: TransformKey(stringValue: "html_url"))
                        self.htmlUrl = try transformer.decode(jsonValue)
                    }
                    do {
                        struct TransformKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        let transformContainer = try decoder.container(keyedBy: TransformKey.self)
                        let transformer = ISO8601DateTransform()
                        let jsonValue = try transformContainer.decode(String.self, forKey: TransformKey(stringValue: "created_at"))
                        self.createdAt = try transformer.decode(jsonValue)
                    }
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        let rootContainer = try decoder.container(keyedBy: DynamicKey.self)
                        let container1 = try rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "owner"))
                        self.ownerLogin = try container1.decode(String.self, forKey: DynamicKey(stringValue: "login"))
                    }
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        let rootContainer = try decoder.container(keyedBy: DynamicKey.self)
                        let container1 = try rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "owner"))
                        let transformer = URLTransform()
                        if let jsonValue = try container1.decodeIfPresent(String.self, forKey: DynamicKey(stringValue: "avatar_url")) {
                            self.ownerAvatar = try transformer.decode(jsonValue)
                        } else {
                            self.ownerAvatar = nil
                        }
                    }
                    self.isFavorite = false
                }

                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(id, forKey: .id)
                    try container.encode(name, forKey: .name)
                    try container.encode(fullName, forKey: .fullName)
                    try container.encodeIfPresent(description, forKey: .description)
                    try container.encode(stars, forKey: .stars)
                    do {
                        struct TransformKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        var transformContainer = encoder.container(keyedBy: TransformKey.self)
                        let transformer = URLTransform()
                        let jsonValue = try transformer.encode(self.htmlUrl)
                        try transformContainer.encode(jsonValue, forKey: TransformKey(stringValue: "html_url"))
                    }
                    do {
                        struct TransformKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        var transformContainer = encoder.container(keyedBy: TransformKey.self)
                        let transformer = ISO8601DateTransform()
                        let jsonValue = try transformer.encode(self.createdAt)
                        try transformContainer.encode(jsonValue, forKey: TransformKey(stringValue: "created_at"))
                    }
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        var rootContainer = encoder.container(keyedBy: DynamicKey.self)
                        var container1 = rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "owner"))
                        try container1.encode(ownerLogin, forKey: DynamicKey(stringValue: "login"))
                    }
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        var rootContainer = encoder.container(keyedBy: DynamicKey.self)
                        var container1 = rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "owner"))
                        let transformer = URLTransform()
                        if let value = self.ownerAvatar {
                            let jsonValue = try transformer.encode(value)
                            try container1.encode(jsonValue, forKey: DynamicKey(stringValue: "avatar_url"))
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
                        var container1 = rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "owner"))
                        try container1.encode(isPrivate, forKey: DynamicKey(stringValue: "is_private"))
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

            extension GitHubRepo: Codable {
            }
            """,
            macros: advancedTestMacros
        )
    }

    // MARK: - Class 類型複雜場景

    @Test("Class 類型 - 複雜混合場景")
    func testClassWithComplexScenario() {
        assertMacroExpansion(
            """
            @Codable
            class UserSession {
                @CodingKey(transform: .uuid)
                let sessionId: UUID

                @CodingKey("user.name")
                let userName: String

                @CodingKey(transform: .timestampDate)
                var lastActive: Date

                let isActive: Bool = true

                @CodingIgnored
                var deviceInfo: String?
            }
            """,
            expandedSource: """
            class UserSession {
                let sessionId: UUID

                let userName: String

                var lastActive: Date

                let isActive: Bool = true

                var deviceInfo: String?

                public enum CodingKeys: String, CodingKey {
                }

                public required init(from decoder: Decoder) throws {
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
                        struct TransformKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        let transformContainer = try decoder.container(keyedBy: TransformKey.self)
                        let transformer = TimestampDateTransform()
                        let jsonValue = try transformContainer.decode(Double.self, forKey: TransformKey(stringValue: "lastActive"))
                        self.lastActive = try transformer.decode(jsonValue)
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
                        self.userName = try container1.decode(String.self, forKey: DynamicKey(stringValue: "name"))
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
                        try transformContainer.encode(jsonValue, forKey: TransformKey(stringValue: "sessionId"))
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
                        let jsonValue = try transformer.encode(self.lastActive)
                        try transformContainer.encode(jsonValue, forKey: TransformKey(stringValue: "lastActive"))
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
                        try container1.encode(userName, forKey: DynamicKey(stringValue: "name"))
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
                        try container1.encode(isActive, forKey: DynamicKey(stringValue: "isActive"))
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

            extension UserSession: Codable {
            }
            """,
            macros: advancedTestMacros
        )
    }

    // MARK: - 特殊字元和命名

    @Test("特殊字元在 key 中 - snake_case 和 kebab-case")
    func testSpecialCharactersInKeys() {
        assertMacroExpansion(
            """
            @Codable
            struct SpecialKeys {
                @CodingKey("user_name")
                let userName: String

                @CodingKey("api-key")
                let apiKey: String

                @CodingKey("user.first-name")
                let firstName: String
            }
            """,
            expandedSource: """
            struct SpecialKeys {
                let userName: String

                let apiKey: String

                let firstName: String

                enum CodingKeys: String, CodingKey {
                    case userName = "user_name"
                    case apiKey = "api-key"
                }

                init(userName: String, apiKey: String, firstName: String) {
                    self.userName = userName
                    self.apiKey = apiKey
                    self.firstName = firstName
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.userName = try container.decode(String.self, forKey: .userName)
                    self.apiKey = try container.decode(String.self, forKey: .apiKey)
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        let rootContainer = try decoder.container(keyedBy: DynamicKey.self)
                        let container1 = try rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "user"))
                        self.firstName = try container1.decode(String.self, forKey: DynamicKey(stringValue: "first-name"))
                    }
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(userName, forKey: .userName)
                    try container.encode(apiKey, forKey: .apiKey)
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        var rootContainer = encoder.container(keyedBy: DynamicKey.self)
                        var container1 = rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "user"))
                        try container1.encode(firstName, forKey: DynamicKey(stringValue: "first-name"))
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

            extension SpecialKeys: Codable {
            }
            """,
            macros: advancedTestMacros
        )
    }

    // MARK: - 大型結構測試

    @Test("超大型 struct - 25+ 屬性混合所有功能")
    func testVeryLargeStruct() {
        assertMacroExpansion(
            """
            @Codable
            struct MegaStruct {
                // 簡單屬性
                let id: String
                let name: String
                let version: Int

                // Optional 屬性
                let description: String?
                let notes: String?

                // Transform 屬性
                @CodingKey(transform: .url)
                let homepage: URL

                @CodingKey(transform: .uuid)
                let userId: UUID

                @CodingKey(transform: .timestampDate)
                let createdAt: Date

                // Nested 屬性
                @CodingKey("meta.author")
                let author: String

                @CodingKey("meta.version")
                let metaVersion: String

                @CodingKey("config.timeout")
                let timeout: Int

                // Transform + Nested
                @CodingKey("data.endpoint", transform: .url)
                let dataEndpoint: URL

                @CodingKey("user.avatar", transform: .url)
                let userAvatar: URL?

                // Default values
                let retryCount: Int = 3
                let enabled: Bool = true

                // Custom keys
                @CodingKey("is_active")
                let isActive: Bool

                @CodingKey("updated_at")
                let updatedAt: String?

                // Ignored
                @CodingIgnored
                var cachedData: String?

                @CodingIgnored
                var tempValue: Int = 0

                // More properties
                let priority: Int
                let category: String
                let tags: [String]
                let status: String

                @CodingKey("extra.data")
                let extraData: String?
            }
            """,
            expandedSource: """
            struct MegaStruct {
                // 簡單屬性
                let id: String
                let name: String
                let version: Int

                // Optional 屬性
                let description: String?
                let notes: String?

                // Transform 屬性
                let homepage: URL

                let userId: UUID

                let createdAt: Date

                // Nested 屬性
                let author: String

                let metaVersion: String

                let timeout: Int

                // Transform + Nested
                let dataEndpoint: URL

                let userAvatar: URL?

                // Default values
                let retryCount: Int = 3
                let enabled: Bool = true

                // Custom keys
                let isActive: Bool

                let updatedAt: String?

                // Ignored
                var cachedData: String?

                var tempValue: Int = 0

                // More properties
                let priority: Int
                let category: String
                let tags: [String]
                let status: String

                let extraData: String?

                public enum CodingKeys: String, CodingKey {
                    case id
                    case name
                    case version
                    case description
                    case notes
                    case isActive = "is_active"
                    case updatedAt = "updated_at"
                    case priority
                    case category
                    case tags
                    case status
                }

                public init(homepage: URL, userId: UUID, createdAt: Date, author: String, metaVersion: String, timeout: Int, dataEndpoint: URL, userAvatar: URL? = nil, id: String, name: String, version: Int, description: String? = nil, notes: String? = nil, isActive: Bool, updatedAt: String? = nil, priority: Int, category: String, tags: [String], status: String, extraData: String? = nil) {
                    self.homepage = homepage
                    self.userId = userId
                    self.createdAt = createdAt
                    self.author = author
                    self.metaVersion = metaVersion
                    self.timeout = timeout
                    self.dataEndpoint = dataEndpoint
                    self.userAvatar = userAvatar
                    self.id = id
                    self.name = name
                    self.version = version
                    self.description = description
                    self.notes = notes
                    self.isActive = isActive
                    self.updatedAt = updatedAt
                    self.priority = priority
                    self.category = category
                    self.tags = tags
                    self.status = status
                    self.extraData = extraData
                    self.tempValue = 0
                }

                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.id = try container.decode(String.self, forKey: .id)
                    self.name = try container.decode(String.self, forKey: .name)
                    self.version = try container.decode(Int.self, forKey: .version)
                    self.description = try container.decodeIfPresent(String.self, forKey: .description)
                    self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
                    self.isActive = try container.decode(Bool.self, forKey: .isActive)
                    self.updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
                    self.priority = try container.decode(Int.self, forKey: .priority)
                    self.category = try container.decode(String.self, forKey: .category)
                    self.tags = try container.decode([String].self, forKey: .tags)
                    self.status = try container.decode(String.self, forKey: .status)
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
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        let rootContainer = try decoder.container(keyedBy: DynamicKey.self)
                        let container1 = try rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "meta"))
                        self.author = try container1.decode(String.self, forKey: DynamicKey(stringValue: "author"))
                    }
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        let rootContainer = try decoder.container(keyedBy: DynamicKey.self)
                        let container1 = try rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "meta"))
                        self.metaVersion = try container1.decode(String.self, forKey: DynamicKey(stringValue: "version"))
                    }
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        let rootContainer = try decoder.container(keyedBy: DynamicKey.self)
                        let container1 = try rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "config"))
                        self.timeout = try container1.decode(Int.self, forKey: DynamicKey(stringValue: "timeout"))
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
                        let transformer = URLTransform()
                        let jsonValue = try container1.decode(String.self, forKey: DynamicKey(stringValue: "endpoint"))
                        self.dataEndpoint = try transformer.decode(jsonValue)
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
                        let transformer = URLTransform()
                        if let jsonValue = try container1.decodeIfPresent(String.self, forKey: DynamicKey(stringValue: "avatar")) {
                            self.userAvatar = try transformer.decode(jsonValue)
                        } else {
                            self.userAvatar = nil
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
                        let container1 = try rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "extra"))
                        self.extraData = try container1.decodeIfPresent(String.self, forKey: DynamicKey(stringValue: "data"))
                    }
                    self.tempValue = 0
                }

                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(id, forKey: .id)
                    try container.encode(name, forKey: .name)
                    try container.encode(version, forKey: .version)
                    try container.encodeIfPresent(description, forKey: .description)
                    try container.encodeIfPresent(notes, forKey: .notes)
                    try container.encode(isActive, forKey: .isActive)
                    try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
                    try container.encode(priority, forKey: .priority)
                    try container.encode(category, forKey: .category)
                    try container.encode(tags, forKey: .tags)
                    try container.encode(status, forKey: .status)
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
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        var rootContainer = encoder.container(keyedBy: DynamicKey.self)
                        var container1 = rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "meta"))
                        try container1.encode(author, forKey: DynamicKey(stringValue: "author"))
                    }
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        var rootContainer = encoder.container(keyedBy: DynamicKey.self)
                        var container1 = rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "meta"))
                        try container1.encode(metaVersion, forKey: DynamicKey(stringValue: "version"))
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
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        var rootContainer = encoder.container(keyedBy: DynamicKey.self)
                        var container1 = rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "data"))
                        let transformer = URLTransform()
                        let jsonValue = try transformer.encode(self.dataEndpoint)
                        try container1.encode(jsonValue, forKey: DynamicKey(stringValue: "endpoint"))
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
                        let transformer = URLTransform()
                        if let value = self.userAvatar {
                            let jsonValue = try transformer.encode(value)
                            try container1.encode(jsonValue, forKey: DynamicKey(stringValue: "avatar"))
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
                        var container1 = rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "meta"))
                        try container1.encode(retryCount, forKey: DynamicKey(stringValue: "retryCount"))
                    }
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        var rootContainer = encoder.container(keyedBy: DynamicKey.self)
                        var container1 = rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "meta"))
                        try container1.encode(enabled, forKey: DynamicKey(stringValue: "enabled"))
                    }
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        var rootContainer = encoder.container(keyedBy: DynamicKey.self)
                        var container1 = rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "extra"))
                        if let extraData = self.extraData {
                            try container1.encode(extraData, forKey: DynamicKey(stringValue: "data"))
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

            extension MegaStruct: Codable {
            }
            """,
            macros: advancedTestMacros
        )
    }
}
