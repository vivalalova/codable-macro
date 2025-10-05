import Testing
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
@testable import CodableMacroMacros
@testable import CodableMacro

/// 基本功能測試
struct BasicCodableTests {

    @Test("基本功能測試 - 簡單 struct")
    func testBasicStruct() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Message {
                let id: String
                let content: String
                let timestamp: Date
            }
            """,
            expandedSource: """
            struct Message {
                let id: String
                let content: String
                let timestamp: Date

                enum CodingKeys: String, CodingKey {
                    case id
                    case content
                    case timestamp
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.id = try container.decode(String.self, forKey: .id)
                    self.content = try container.decode(String.self, forKey: .content)
                    self.timestamp = try container.decode(Date.self, forKey: .timestamp)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(id, forKey: .id)
                    try container.encode(content, forKey: .content)
                    try container.encode(timestamp, forKey: .timestamp)
                }
            }

            extension Message: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("Optional 型別測試")
    func testOptionalTypes() throws {
        assertMacroExpansion(
            """
            @Codable
            struct User {
                let id: String
                let name: String?
                let email: String?
                let age: Int
            }
            """,
            expandedSource: """
            struct User {
                let id: String
                let name: String?
                let email: String?
                let age: Int

                enum CodingKeys: String, CodingKey {
                    case id
                    case name
                    case email
                    case age
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.id = try container.decode(String.self, forKey: .id)
                    self.name = try container.decodeIfPresent(String.self, forKey: .name)
                    self.email = try container.decodeIfPresent(String.self, forKey: .email)
                    self.age = try container.decode(Int.self, forKey: .age)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(id, forKey: .id)
                    try container.encodeIfPresent(name, forKey: .name)
                    try container.encodeIfPresent(email, forKey: .email)
                    try container.encode(age, forKey: .age)
                }
            }

            extension User: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("Collection 型別測試")
    func testCollectionTypes() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Post {
                let id: String
                let tags: [String]
                let metadata: [String: String]
                let views: Int
            }
            """,
            expandedSource: """
            struct Post {
                let id: String
                let tags: [String]
                let metadata: [String: String]
                let views: Int

                enum CodingKeys: String, CodingKey {
                    case id
                    case tags
                    case metadata
                    case views
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.id = try container.decode(String.self, forKey: .id)
                    self.tags = try container.decode([String].self, forKey: .tags)
                    self.metadata = try container.decode([String: String].self, forKey: .metadata)
                    self.views = try container.decode(Int.self, forKey: .views)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(id, forKey: .id)
                    try container.encode(tags, forKey: .tags)
                    try container.encode(metadata, forKey: .metadata)
                    try container.encode(views, forKey: .views)
                }
            }

            extension Post: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("var 屬性測試")
    func testVarProperties() throws {
        assertMacroExpansion(
            """
            @Codable
            struct MutableUser {
                var id: String
                var name: String
                var age: Int
            }
            """,
            expandedSource: """
            struct MutableUser {
                var id: String
                var name: String
                var age: Int

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
            }

            extension MutableUser: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("混合 let 和 var 屬性測試")
    func testMixedLetVarProperties() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Article {
                let id: String
                var title: String
                var content: String
                let createdAt: Date
            }
            """,
            expandedSource: """
            struct Article {
                let id: String
                var title: String
                var content: String
                let createdAt: Date

                enum CodingKeys: String, CodingKey {
                    case id
                    case title
                    case content
                    case createdAt
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.id = try container.decode(String.self, forKey: .id)
                    self.title = try container.decode(String.self, forKey: .title)
                    self.content = try container.decode(String.self, forKey: .content)
                    self.createdAt = try container.decode(Date.self, forKey: .createdAt)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(id, forKey: .id)
                    try container.encode(title, forKey: .title)
                    try container.encode(content, forKey: .content)
                    try container.encode(createdAt, forKey: .createdAt)
                }
            }

            extension Article: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("class 類型測試")
    func testClassType() throws {
        assertMacroExpansion(
            """
            @Codable
            class Person {
                let id: String
                let name: String
                let age: Int
            }
            """,
            expandedSource: """
            class Person {
                let id: String
                let name: String
                let age: Int

                enum CodingKeys: String, CodingKey {
                    case id
                    case name
                    case age
                }

                required init(from decoder: Decoder) throws {
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
            }

            extension Person: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("混合型別測試 - 基本型別 + Optional + Collection")
    func testComplexMixedTypes() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Product {
                let id: String
                let name: String
                let price: Double
                let description: String?
                let tags: [String]
                let metadata: [String: String]?
                let isAvailable: Bool
            }
            """,
            expandedSource: """
            struct Product {
                let id: String
                let name: String
                let price: Double
                let description: String?
                let tags: [String]
                let metadata: [String: String]?
                let isAvailable: Bool

                enum CodingKeys: String, CodingKey {
                    case id
                    case name
                    case price
                    case description
                    case tags
                    case metadata
                    case isAvailable
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.id = try container.decode(String.self, forKey: .id)
                    self.name = try container.decode(String.self, forKey: .name)
                    self.price = try container.decode(Double.self, forKey: .price)
                    self.description = try container.decodeIfPresent(String.self, forKey: .description)
                    self.tags = try container.decode([String].self, forKey: .tags)
                    self.metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata)
                    self.isAvailable = try container.decode(Bool.self, forKey: .isAvailable)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(id, forKey: .id)
                    try container.encode(name, forKey: .name)
                    try container.encode(price, forKey: .price)
                    try container.encodeIfPresent(description, forKey: .description)
                    try container.encode(tags, forKey: .tags)
                    try container.encodeIfPresent(metadata, forKey: .metadata)
                    try container.encode(isAvailable, forKey: .isAvailable)
                }
            }

            extension Product: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("巢狀型別測試 - Optional 陣列")
    func testNestedArrayType() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Album {
                let id: String
                let title: String
                let tracks: [[String]]
            }
            """,
            expandedSource: """
            struct Album {
                let id: String
                let title: String
                let tracks: [[String]]

                enum CodingKeys: String, CodingKey {
                    case id
                    case title
                    case tracks
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.id = try container.decode(String.self, forKey: .id)
                    self.title = try container.decode(String.self, forKey: .title)
                    self.tracks = try container.decode([[String]].self, forKey: .tracks)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(id, forKey: .id)
                    try container.encode(title, forKey: .title)
                    try container.encode(tracks, forKey: .tracks)
                }
            }

            extension Album: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("多層巢狀 Optional 測試")
    func testDoubleOptionalType() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Config {
                let value: String??
            }
            """,
            expandedSource: """
            struct Config {
                let value: String??

                enum CodingKeys: String, CodingKey {
                    case value
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.value = try container.decodeIfPresent(String?.self, forKey: .value)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encodeIfPresent(value, forKey: .value)
                }
            }

            extension Config: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("空陣列和空字典測試")
    func testEmptyCollections() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Container {
                let items: [String]
                let dict: [String: Int]
            }
            """,
            expandedSource: """
            struct Container {
                let items: [String]
                let dict: [String: Int]

                enum CodingKeys: String, CodingKey {
                    case items
                    case dict
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.items = try container.decode([String].self, forKey: .items)
                    self.dict = try container.decode([String: Int].self, forKey: .dict)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(items, forKey: .items)
                    try container.encode(dict, forKey: .dict)
                }
            }

            extension Container: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("大型 struct 測試 - 10+ 屬性")
    func testLargeStruct() throws {
        assertMacroExpansion(
            """
            @Codable
            struct LargeData {
                let field1: String
                let field2: String
                let field3: Int
                let field4: Double
                let field5: Bool
                let field6: String?
                let field7: [String]
                let field8: [String: Int]
                let field9: Date
                let field10: String
                let field11: Int
                let field12: Double
            }
            """,
            expandedSource: """
            struct LargeData {
                let field1: String
                let field2: String
                let field3: Int
                let field4: Double
                let field5: Bool
                let field6: String?
                let field7: [String]
                let field8: [String: Int]
                let field9: Date
                let field10: String
                let field11: Int
                let field12: Double

                enum CodingKeys: String, CodingKey {
                    case field1
                    case field2
                    case field3
                    case field4
                    case field5
                    case field6
                    case field7
                    case field8
                    case field9
                    case field10
                    case field11
                    case field12
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.field1 = try container.decode(String.self, forKey: .field1)
                    self.field2 = try container.decode(String.self, forKey: .field2)
                    self.field3 = try container.decode(Int.self, forKey: .field3)
                    self.field4 = try container.decode(Double.self, forKey: .field4)
                    self.field5 = try container.decode(Bool.self, forKey: .field5)
                    self.field6 = try container.decodeIfPresent(String.self, forKey: .field6)
                    self.field7 = try container.decode([String].self, forKey: .field7)
                    self.field8 = try container.decode([String: Int].self, forKey: .field8)
                    self.field9 = try container.decode(Date.self, forKey: .field9)
                    self.field10 = try container.decode(String.self, forKey: .field10)
                    self.field11 = try container.decode(Int.self, forKey: .field11)
                    self.field12 = try container.decode(Double.self, forKey: .field12)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(field1, forKey: .field1)
                    try container.encode(field2, forKey: .field2)
                    try container.encode(field3, forKey: .field3)
                    try container.encode(field4, forKey: .field4)
                    try container.encode(field5, forKey: .field5)
                    try container.encodeIfPresent(field6, forKey: .field6)
                    try container.encode(field7, forKey: .field7)
                    try container.encode(field8, forKey: .field8)
                    try container.encode(field9, forKey: .field9)
                    try container.encode(field10, forKey: .field10)
                    try container.encode(field11, forKey: .field11)
                    try container.encode(field12, forKey: .field12)
                }
            }

            extension LargeData: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("Unicode 屬性名稱測試")
    func testUnicodePropertyNames() throws {
        assertMacroExpansion(
            """
            @Codable
            struct LocalizedData {
                let 名稱: String
                let 年齡: Int
                let 城市: String
            }
            """,
            expandedSource: """
            struct LocalizedData {
                let 名稱: String
                let 年齡: Int
                let 城市: String

                enum CodingKeys: String, CodingKey {
                    case 名稱
                    case 年齡
                    case 城市
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.名稱 = try container.decode(String.self, forKey: .名稱)
                    self.年齡 = try container.decode(Int.self, forKey: .年齡)
                    self.城市 = try container.decode(String.self, forKey: .城市)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(名稱, forKey: .名稱)
                    try container.encode(年齡, forKey: .年齡)
                    try container.encode(城市, forKey: .城市)
                }
            }

            extension LocalizedData: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }
}
