import Testing
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
@testable import CodableMacroMacros
@testable import CodableMacro
import Foundation

/// 測試宏的功能
struct CodableMacroTests {
    
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
    
    @Test("只能應用於 struct 和 class")
    func testOnlyStructsAndClasses() throws {
        assertMacroExpansion(
            """
            @Codable
            enum Color {
                case red, green, blue
            }
            """,
            expandedSource: """
            enum Color {
                case red, green, blue
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@Codable 只能應用於 struct 或 class", line: 1, column: 1)
            ],
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

    @Test("邊界案例 - 單一屬性")
    func testSingleProperty() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SimpleId {
                let id: String
            }
            """,
            expandedSource: """
            struct SimpleId {
                let id: String

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
            }

            extension SimpleId: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("邊界案例 - 空 struct")
    func testEmptyStruct() throws {
        assertMacroExpansion(
            """
            @Codable
            struct EmptyStruct {
            }
            """,
            expandedSource: """
            struct EmptyStruct {

                enum CodingKeys: String, CodingKey {
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                }
            }

            extension EmptyStruct: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("錯誤案例 - actor 類型不支援")
    func testActorNotSupported() throws {
        assertMacroExpansion(
            """
            @Codable
            actor Counter {
                var count: Int = 0
            }
            """,
            expandedSource: """
            actor Counter {
                var count: Int = 0
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@Codable 只能應用於 struct 或 class", line: 1, column: 1)
            ],
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("錯誤案例 - protocol 不支援")
    func testProtocolNotSupported() throws {
        assertMacroExpansion(
            """
            @Codable
            protocol Identifiable {
                var id: String { get }
            }
            """,
            expandedSource: """
            protocol Identifiable {
                var id: String { get }
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@Codable 只能應用於 struct 或 class", line: 1, column: 1)
            ],
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("Simple enum - 基本功能")
    func testSimpleEnum() throws {
        assertMacroExpansion(
            """
            @Codable
            enum Direction {
                case north
                case south
                case east
                case west
            }
            """,
            expandedSource: """
            enum Direction {
                case north
                case south
                case east
                case west

                init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let value = try container.decode(String.self)

                    switch value {
                    case "north":
                        self = .north
                    case "south":
                        self = .south
                    case "east":
                        self = .east
                    case "west":
                        self = .west
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
                    case .north:
                        try container.encode("north")
                    case .south:
                        try container.encode("south")
                    case .east:
                        try container.encode("east")
                    case .west:
                        try container.encode("west")
                    }
                }
            }

            extension Direction: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("Simple enum - 單一 case")
    func testSimpleEnumSingleCase() throws {
        assertMacroExpansion(
            """
            @Codable
            enum Status {
                case active
            }
            """,
            expandedSource: """
            enum Status {
                case active

                init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let value = try container.decode(String.self)

                    switch value {
                    case "active":
                        self = .active
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
                    }
                }
            }

            extension Status: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("Associated values enum - 有標籤參數")
    func testAssociatedValuesEnumWithLabels() throws {
        assertMacroExpansion(
            """
            @Codable
            enum NetworkResponse {
                case success(data: String, statusCode: Int)
                case failure(error: String)
                case empty
            }
            """,
            expandedSource: """
            enum NetworkResponse {
                case success(data: String, statusCode: Int)
                case failure(error: String)
                case empty

                enum CodingKeys: String, CodingKey {
                    case success
                    case failure
                    case empty
                }

                enum SuccessCodingKeys: String, CodingKey {
                    case data
                    case statusCode
                }

                enum FailureCodingKeys: String, CodingKey {
                    case error
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
                        let statusCode = try nestedContainer.decode(Int.self, forKey: .statusCode)
                        self = .success(data: data, statusCode: statusCode)
                    case .failure:
                        let nestedContainer = try container.nestedContainer(keyedBy: FailureCodingKeys.self, forKey: .failure)
                        let error = try nestedContainer.decode(String.self, forKey: .error)
                        self = .failure(error: error)
                    case .empty:
                        self = .empty
                    }
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)

                    switch self {
                    case .success(let data, let statusCode):
                        var nestedContainer = container.nestedContainer(keyedBy: SuccessCodingKeys.self, forKey: .success)
                        try nestedContainer.encode(data, forKey: .data)
                        try nestedContainer.encode(statusCode, forKey: .statusCode)
                    case .failure(let error):
                        var nestedContainer = container.nestedContainer(keyedBy: FailureCodingKeys.self, forKey: .failure)
                        try nestedContainer.encode(error, forKey: .error)
                    case .empty:
                        _ = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .empty)
                    }
                }
            }

            extension NetworkResponse: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("Associated values enum - 無標籤參數")
    func testAssociatedValuesEnumWithoutLabels() throws {
        assertMacroExpansion(
            """
            @Codable
            enum Result {
                case success(String)
                case failure(Int, String)
            }
            """,
            expandedSource: """
            enum Result {
                case success(String)
                case failure(Int, String)

                enum CodingKeys: String, CodingKey {
                    case success
                    case failure
                }

                enum SuccessCodingKeys: String, CodingKey {
                    case _0
                }

                enum FailureCodingKeys: String, CodingKey {
                    case _0
                    case _1
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
                        let _0 = try nestedContainer.decode(String.self, forKey: ._0)
                        self = .success(_0)
                    case .failure:
                        let nestedContainer = try container.nestedContainer(keyedBy: FailureCodingKeys.self, forKey: .failure)
                        let _0 = try nestedContainer.decode(Int.self, forKey: ._0)
                        let _1 = try nestedContainer.decode(String.self, forKey: ._1)
                        self = .failure(_0, _1)
                    }
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)

                    switch self {
                    case .success(let _0):
                        var nestedContainer = container.nestedContainer(keyedBy: SuccessCodingKeys.self, forKey: .success)
                        try nestedContainer.encode(_0, forKey: ._0)
                    case .failure(let _0, let _1):
                        var nestedContainer = container.nestedContainer(keyedBy: FailureCodingKeys.self, forKey: .failure)
                        try nestedContainer.encode(_0, forKey: ._0)
                        try nestedContainer.encode(_1, forKey: ._1)
                    }
                }
            }

            extension Result: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("Raw value enum - 應提供診斷訊息")
    func testRawValueEnum() throws {
        assertMacroExpansion(
            """
            @Codable
            enum Color: String {
                case red
                case green
                case blue
            }
            """,
            expandedSource: """
            enum Color: String {
                case red
                case green
                case blue
            }

            extension Color: Codable {
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "Enum with raw value already conforms to Codable", line: 1, column: 1, severity: .warning)
            ],
            macros: ["Codable": CodableMacro.self]
        )
    }
}

/// 手動測試 - 驗證產生的程式碼能否正確運作
/// 這個測試需要手動驗證，因為我們的 macro 生成了正確的 Codable 實作
struct CodableManualTest {
    
    @Test("手動驗證 JSON 編碼解碼功能")
    func testManualCodable() throws {
        // 手動定義一個符合 Codable 的 struct 來模擬我們 macro 的輸出
        struct TestMessage: Codable {
            let id: String
            let content: String
            let timestamp: Date
            let isRead: Bool
            let tags: [String]?
            
            enum CodingKeys: String, CodingKey {
                case id
                case content
                case timestamp
                case isRead
                case tags
            }
            
            init(id: String, content: String, timestamp: Date, isRead: Bool, tags: [String]?) {
                self.id = id
                self.content = content
                self.timestamp = timestamp
                self.isRead = isRead
                self.tags = tags
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.id = try container.decode(String.self, forKey: .id)
                self.content = try container.decode(String.self, forKey: .content)
                self.timestamp = try container.decode(Date.self, forKey: .timestamp)
                self.isRead = try container.decode(Bool.self, forKey: .isRead)
                self.tags = try container.decodeIfPresent([String].self, forKey: .tags)
            }
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(id, forKey: .id)
                try container.encode(content, forKey: .content)
                try container.encode(timestamp, forKey: .timestamp)
                try container.encode(isRead, forKey: .isRead)
                try container.encodeIfPresent(tags, forKey: .tags)
            }
        }
        
        let originalMessage = TestMessage(
            id: "123",
            content: "Hello, World!",
            timestamp: Date(),
            isRead: false,
            tags: ["swift", "macro"]
        )
        
        // 測試編碼
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(originalMessage)
        
        // 測試解碼
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedMessage = try decoder.decode(TestMessage.self, from: jsonData)
        
        // 驗證資料正確性
        #expect(decodedMessage.id == originalMessage.id)
        #expect(decodedMessage.content == originalMessage.content)
        #expect(decodedMessage.isRead == originalMessage.isRead)
        #expect(decodedMessage.tags == originalMessage.tags)
        // 時間戳比較需要特殊處理，因為編碼解碼可能會改變精度
        #expect(abs(decodedMessage.timestamp.timeIntervalSince1970 - originalMessage.timestamp.timeIntervalSince1970) < 1.0)
        
        // 驗證 JSON 字符串包含預期的鍵
        let jsonString = String(data: jsonData, encoding: .utf8)!
        #expect(jsonString.contains("\"id\":\"123\""))
        #expect(jsonString.contains("\"content\":\"Hello, World!\""))
        #expect(jsonString.contains("\"isRead\":false"))
        #expect(jsonString.contains("\"tags\":[\"swift\",\"macro\"]"))
    }
}
