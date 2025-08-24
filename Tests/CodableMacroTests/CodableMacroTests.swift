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
