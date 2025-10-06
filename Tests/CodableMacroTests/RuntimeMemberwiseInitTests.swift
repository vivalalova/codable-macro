import Foundation
import Testing
import CodableMacro

/// 執行期測試：驗證 memberwise initializer 在實際執行時的行為
struct RuntimeMemberwiseInitTests {

    @Test("基本 memberwise init 創建實例")
    func testBasicMemberwiseInit() throws {
        let user = BasicUser(id: "123", name: "Alice")

        #expect(user.id == "123")
        #expect(user.name == "Alice")
    }

    @Test("Optional 屬性預設為 nil")
    func testOptionalDefaultsToNil() throws {
        // 只提供必需參數
        let user1 = OptionalUser(id: "123")

        #expect(user1.id == "123")
        #expect(user1.name == nil)
        #expect(user1.email == nil)

        // 提供部分 Optional 參數
        let user2 = OptionalUser(id: "456", name: "Bob")

        #expect(user2.id == "456")
        #expect(user2.name == "Bob")
        #expect(user2.email == nil)

        // 提供所有參數
        let user3 = OptionalUser(id: "789", name: "Charlie", email: "charlie@example.com")

        #expect(user3.id == "789")
        #expect(user3.name == "Charlie")
        #expect(user3.email == "charlie@example.com")
    }

    @Test("混合 Optional 和預設值")
    func testMixedOptionalAndDefaults() throws {
        // 只提供必需參數
        let config1 = MixedConfig(name: "AppConfig")

        #expect(config1.name == "AppConfig")
        #expect(config1.timeout == 30)  // let 屬性保持預設值
        #expect(config1.enabled == nil)
        #expect(config1.retries == 3)

        // 覆蓋 var 屬性的預設值（let 屬性無法覆蓋）
        let config2 = MixedConfig(name: "CustomConfig", enabled: true, retries: 5)

        #expect(config2.name == "CustomConfig")
        #expect(config2.timeout == 30)  // let 屬性無法從 memberwise init 覆蓋
        #expect(config2.enabled == true)
        #expect(config2.retries == 5)
    }

    @Test("Public struct memberwise init")
    func testPublicMemberwiseInit() throws {
        let message = PublicTestMessage(type: "info")

        #expect(message.type == "info")
        #expect(message.content == nil)

        let message2 = PublicTestMessage(type: "error", content: "Something went wrong")

        #expect(message2.type == "error")
        #expect(message2.content == "Something went wrong")
    }

    @Test("@CodingIgnored 屬性使用預設值")
    func testCodingIgnoredUsesDefault() throws {
        let user = UserWithCache(id: "123", name: "Alice")

        #expect(user.id == "123")
        #expect(user.name == "Alice")
        #expect(user.cache == "")  // @CodingIgnored 屬性使用預設值
    }

    @Test("全部都是 Optional 的 struct")
    func testAllOptionalStruct() throws {
        let metadata1 = OptionalMetadata()

        #expect(metadata1.title == nil)
        #expect(metadata1.description == nil)
        #expect(metadata1.tags == nil)

        let metadata2 = OptionalMetadata(title: "Test", tags: ["swift", "macro"])

        #expect(metadata2.title == "Test")
        #expect(metadata2.description == nil)
        #expect(metadata2.tags == ["swift", "macro"])
    }

    @Test("Collection 型別預設值")
    func testCollectionDefaults() throws {
        let app1 = AppConfig(id: "app1")

        #expect(app1.id == "app1")
        #expect(app1.tags == [])   // let 屬性保持預設值
        #expect(app1.labels == [:]) // let 屬性保持預設值

        // let 屬性有預設值無法從 memberwise init 覆蓋
        // tags 和 labels 都會保持預設值（[], [:]）
        let app2 = AppConfig(id: "app2")

        #expect(app2.id == "app2")
        #expect(app2.tags == [])    // let 屬性無法覆蓋
        #expect(app2.labels == [:])  // let 屬性無法覆蓋
    }

    @Test("Memberwise init 與 JSON 解碼共存")
    func testMemberwiseInitAndJSONDecoding() throws {
        // 使用 memberwise init 創建
        let user1 = BasicUser(id: "123", name: "Alice")

        // 編碼為 JSON
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(user1)

        // 從 JSON 解碼
        let decoder = JSONDecoder()
        let user2 = try decoder.decode(BasicUser.self, from: jsonData)

        #expect(user2.id == "123")
        #expect(user2.name == "Alice")

        // 兩種方式創建的實例內容相同
        #expect(user1.id == user2.id)
        #expect(user1.name == user2.name)
    }
}

// MARK: - 測試用型別

@Codable
struct BasicUser {
    let id: String
    let name: String
}

@Codable
struct OptionalUser {
    let id: String
    let name: String?
    let email: String?
}

@Codable
struct MixedConfig {
    let name: String
    let timeout: Int = 30
    let enabled: Bool?
    var retries: Int = 3
}

@Codable
public struct PublicTestMessage {
    public let type: String
    public let content: String?
}

@Codable
struct UserWithCache {
    let id: String
    let name: String
    @CodingIgnored
    var cache: String = ""
}

@Codable
struct OptionalMetadata {
    let title: String?
    let description: String?
    let tags: [String]?
}

@Codable
struct AppConfig {
    let id: String
    let tags: [String] = []
    let labels: [String: String] = [:]
}
