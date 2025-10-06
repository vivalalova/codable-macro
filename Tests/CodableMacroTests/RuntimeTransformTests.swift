import Testing
import Foundation

@testable import CodableMacro

// MARK: - 執行期測試

@Codable
struct URLMessage {
    @CodingKey("endpoint", transform: .url)
    let endpoint: URL

    let content: String
}

@Codable
struct UUIDSession {
    @CodingKey("session_id", transform: .uuid)
    let sessionId: UUID
}

@Codable
struct OptionalURLProfile {
    @CodingKey("avatar_url", transform: .url)
    let avatarUrl: URL?

    let name: String
}

@Codable
struct TimestampEvent {
    @CodingKey("created_at", transform: .timestampDate)
    let createdAt: Date

    let title: String
}

@Codable
struct BoolIntConfig {
    @CodingKey(transform: .boolInt)
    let enabled: Bool
}

@Codable
struct MixedMessage {
    @CodingKey("workspace", transform: .url)
    let workspace: URL

    @CodingKey("session_id", transform: .uuid)
    let sessionId: UUID

    let content: String
    let priority: Int
}

// MARK: - URL Transform 測試

@Test("URL Transform - 編碼與解碼")
func testURLTransformRoundtrip() throws {
    let original = URLMessage(
        endpoint: URL(string: "https://example.com/api")!,
        content: "Hello"
    )

    let encoder = JSONEncoder()
    let data = try encoder.encode(original)

    // 驗證 JSON 格式
    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    #expect(json["endpoint"] as? String == "https://example.com/api")
    #expect(json["content"] as? String == "Hello")

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(URLMessage.self, from: data)

    #expect(decoded.endpoint == original.endpoint)
    #expect(decoded.content == original.content)
}

@Test("URL Transform - 無效 URL 拋出錯誤")
func testURLTransformInvalidURL() throws {
    let json = """
    {
        "endpoint": "",
        "content": "Hello"
    }
    """

    let data = json.data(using: .utf8)!
    let decoder = JSONDecoder()

    #expect(throws: TransformError.self) {
        try decoder.decode(URLMessage.self, from: data)
    }
}

// MARK: - UUID Transform 測試

@Test("UUID Transform - 編碼與解碼")
func testUUIDTransformRoundtrip() throws {
    let uuid = UUID()
    let original = UUIDSession(sessionId: uuid)

    let encoder = JSONEncoder()
    let data = try encoder.encode(original)

    // 驗證 JSON 格式
    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    #expect(json["session_id"] as? String == uuid.uuidString)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(UUIDSession.self, from: data)

    #expect(decoded.sessionId == original.sessionId)
}

@Test("UUID Transform - 無效 UUID 拋出錯誤")
func testUUIDTransformInvalidUUID() throws {
    let json = """
    {
        "session_id": "not-a-valid-uuid"
    }
    """

    let data = json.data(using: .utf8)!
    let decoder = JSONDecoder()

    #expect(throws: TransformError.self) {
        try decoder.decode(UUIDSession.self, from: data)
    }
}

// MARK: - Optional URL Transform 測試

@Test("Optional URL Transform - 有值")
func testOptionalURLTransformWithValue() throws {
    let original = OptionalURLProfile(
        avatarUrl: URL(string: "https://example.com/avatar.jpg")!,
        name: "Alice"
    )

    let encoder = JSONEncoder()
    let data = try encoder.encode(original)

    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    #expect(json["avatar_url"] as? String == "https://example.com/avatar.jpg")
    #expect(json["name"] as? String == "Alice")

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(OptionalURLProfile.self, from: data)

    #expect(decoded.avatarUrl == original.avatarUrl)
    #expect(decoded.name == original.name)
}

@Test("Optional URL Transform - nil 值")
func testOptionalURLTransformWithNil() throws {
    let original = OptionalURLProfile(avatarUrl: nil, name: "Bob")

    let encoder = JSONEncoder()
    let data = try encoder.encode(original)

    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    #expect(json["avatar_url"] == nil)
    #expect(json["name"] as? String == "Bob")

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(OptionalURLProfile.self, from: data)

    #expect(decoded.avatarUrl == nil)
    #expect(decoded.name == original.name)
}

@Test("Optional URL Transform - JSON 缺少欄位")
func testOptionalURLTransformMissingField() throws {
    let json = """
    {
        "name": "Charlie"
    }
    """

    let data = json.data(using: .utf8)!
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(OptionalURLProfile.self, from: data)

    #expect(decoded.avatarUrl == nil)
    #expect(decoded.name == "Charlie")
}

// MARK: - Timestamp Date Transform 測試

@Test("Timestamp Date Transform - 編碼與解碼")
func testTimestampDateTransformRoundtrip() throws {
    let date = Date(timeIntervalSince1970: 1704067200) // 2024-01-01 00:00:00 UTC
    let original = TimestampEvent(createdAt: date, title: "New Year")

    let encoder = JSONEncoder()
    let data = try encoder.encode(original)

    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    #expect(json["created_at"] as? Double == 1704067200.0)
    #expect(json["title"] as? String == "New Year")

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(TimestampEvent.self, from: data)

    #expect(decoded.createdAt.timeIntervalSince1970 == original.createdAt.timeIntervalSince1970)
    #expect(decoded.title == original.title)
}

// MARK: - Bool Int Transform 測試

@Test("Bool Int Transform - true 編碼為 1")
func testBoolIntTransformTrue() throws {
    let original = BoolIntConfig(enabled: true)

    let encoder = JSONEncoder()
    let data = try encoder.encode(original)

    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    #expect(json["enabled"] as? Int == 1)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(BoolIntConfig.self, from: data)

    #expect(decoded.enabled == true)
}

@Test("Bool Int Transform - false 編碼為 0")
func testBoolIntTransformFalse() throws {
    let original = BoolIntConfig(enabled: false)

    let encoder = JSONEncoder()
    let data = try encoder.encode(original)

    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    #expect(json["enabled"] as? Int == 0)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(BoolIntConfig.self, from: data)

    #expect(decoded.enabled == false)
}

@Test("Bool Int Transform - 無效值拋出錯誤")
func testBoolIntTransformInvalidValue() throws {
    let json = """
    {
        "enabled": 5
    }
    """

    let data = json.data(using: .utf8)!
    let decoder = JSONDecoder()

    #expect(throws: TransformError.self) {
        try decoder.decode(BoolIntConfig.self, from: data)
    }
}

// MARK: - 混合屬性測試

@Test("混合 Transform 和普通屬性")
func testMixedProperties() throws {
    let url = URL(string: "https://workspace.example.com")!
    let uuid = UUID()
    let original = MixedMessage(
        workspace: url,
        sessionId: uuid,
        content: "Test message",
        priority: 5
    )

    let encoder = JSONEncoder()
    let data = try encoder.encode(original)

    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    #expect(json["workspace"] as? String == url.absoluteString)
    #expect(json["session_id"] as? String == uuid.uuidString)
    #expect(json["content"] as? String == "Test message")
    #expect(json["priority"] as? Int == 5)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(MixedMessage.self, from: data)

    #expect(decoded.workspace == original.workspace)
    #expect(decoded.sessionId == original.sessionId)
    #expect(decoded.content == original.content)
    #expect(decoded.priority == original.priority)
}

// MARK: - 錯誤訊息測試

@Test("Transform 錯誤訊息包含詳細資訊")
func testTransformErrorMessages() {
    let urlError = TransformError.invalidURL("bad url")
    #expect(urlError.description.contains("Invalid URL string"))
    #expect(urlError.description.contains("bad url"))

    let uuidError = TransformError.invalidUUID("bad uuid")
    #expect(uuidError.description.contains("Invalid UUID string"))
    #expect(uuidError.description.contains("bad uuid"))

    let boolIntError = TransformError.invalidBoolInt(5)
    #expect(boolIntError.description.contains("Invalid Bool Int value"))
    #expect(boolIntError.description.contains("5"))
}
