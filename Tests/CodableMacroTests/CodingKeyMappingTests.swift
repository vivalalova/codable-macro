import Testing
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
@testable import CodableMacroMacros
@testable import CodableMacro

/// CodingKey mapping 功能測試
struct CodingKeyMappingTests {

    @Test("基本 key mapping")
    func testBasicKeyMapping() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Message {
                @CodingKey("tool_use_id")
                var toolUseId: String
                var content: String
            }
            """,
            expandedSource: """
            struct Message {
                var toolUseId: String
                var content: String

                enum CodingKeys: String, CodingKey {
                    case toolUseId = "tool_use_id"
                    case content
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.toolUseId = try container.decode(String.self, forKey: .toolUseId)
                    self.content = try container.decode(String.self, forKey: .content)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(toolUseId, forKey: .toolUseId)
                    try container.encode(content, forKey: .content)
                }
            }

            extension Message: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self, "CodingKey": CodingKeyMacro.self]
        )
    }

    @Test("混合自訂和預設 key")
    func testMixedCustomAndDefaultKeys() throws {
        assertMacroExpansion(
            """
            @Codable
            struct User {
                let id: String
                @CodingKey("user_name")
                let userName: String
                @CodingKey("email_address")
                let emailAddress: String?
                let age: Int
            }
            """,
            expandedSource: """
            struct User {
                let id: String
                let userName: String
                let emailAddress: String?
                let age: Int

                enum CodingKeys: String, CodingKey {
                    case id
                    case userName = "user_name"
                    case emailAddress = "email_address"
                    case age
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.id = try container.decode(String.self, forKey: .id)
                    self.userName = try container.decode(String.self, forKey: .userName)
                    self.emailAddress = try container.decodeIfPresent(String.self, forKey: .emailAddress)
                    self.age = try container.decode(Int.self, forKey: .age)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(id, forKey: .id)
                    try container.encode(userName, forKey: .userName)
                    try container.encodeIfPresent(emailAddress, forKey: .emailAddress)
                    try container.encode(age, forKey: .age)
                }
            }

            extension User: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self, "CodingKey": CodingKeyMacro.self]
        )
    }

    @Test("Optional 屬性的 mapping")
    func testOptionalPropertyMapping() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Response {
                @CodingKey("request_id")
                let requestId: String?
                @CodingKey("error_message")
                let errorMessage: String?
            }
            """,
            expandedSource: """
            struct Response {
                let requestId: String?
                let errorMessage: String?

                enum CodingKeys: String, CodingKey {
                    case requestId = "request_id"
                    case errorMessage = "error_message"
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.requestId = try container.decodeIfPresent(String.self, forKey: .requestId)
                    self.errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encodeIfPresent(requestId, forKey: .requestId)
                    try container.encodeIfPresent(errorMessage, forKey: .errorMessage)
                }
            }

            extension Response: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self, "CodingKey": CodingKeyMacro.self]
        )
    }

    @Test("所有屬性都使用自訂 key")
    func testAllCustomKeys() throws {
        assertMacroExpansion(
            """
            @Codable
            struct APIRequest {
                @CodingKey("api_key")
                let apiKey: String
                @CodingKey("request_id")
                let requestId: String
                @CodingKey("user_id")
                let userId: Int
            }
            """,
            expandedSource: """
            struct APIRequest {
                let apiKey: String
                let requestId: String
                let userId: Int

                enum CodingKeys: String, CodingKey {
                    case apiKey = "api_key"
                    case requestId = "request_id"
                    case userId = "user_id"
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.apiKey = try container.decode(String.self, forKey: .apiKey)
                    self.requestId = try container.decode(String.self, forKey: .requestId)
                    self.userId = try container.decode(Int.self, forKey: .userId)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(apiKey, forKey: .apiKey)
                    try container.encode(requestId, forKey: .requestId)
                    try container.encode(userId, forKey: .userId)
                }
            }

            extension APIRequest: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self, "CodingKey": CodingKeyMacro.self]
        )
    }
}
