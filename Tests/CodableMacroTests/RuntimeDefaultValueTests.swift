import Foundation
import Testing
import CodableMacro

/// 執行期測試：驗證預設值在實際 JSON 解碼時的行為
struct RuntimeDefaultValueTests {

    @Test("非 Optional 屬性預設值 - JSON 缺少欄位時使用預設值")
    func testNonOptionalDefaultValueDecoding() throws {
        let json = """
        {
            "apiKey": "secret123"
        }
        """

        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(APIConfig.self, from: data)

        #expect(decoded.apiKey == "secret123")
        #expect(decoded.timeout == 30)  // 使用預設值
        #expect(decoded.retryCount == 3)  // 使用預設值
    }

    @Test("非 Optional 屬性預設值 - let 屬性保持預設值無法覆蓋")
    func testNonOptionalDefaultValueOverride() throws {
        let json = """
        {
            "apiKey": "secret123",
            "timeout": 60,
            "retryCount": 5
        }
        """

        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(APIConfig.self, from: data)

        #expect(decoded.apiKey == "secret123")
        #expect(decoded.timeout == 30)  // let 屬性保持預設值，無法從 JSON 覆蓋
        #expect(decoded.retryCount == 3)  // let 屬性保持預設值，無法從 JSON 覆蓋
    }

    @Test("Optional 屬性預設值 - JSON 缺少欄位時使用預設值")
    func testOptionalDefaultValueDecoding() throws {
        let json = """
        {
            "stdout": "hello"
        }
        """

        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(CommandOutput.self, from: data)

        #expect(decoded.stdout == "hello")
        #expect(decoded.stderr == nil)  // 使用預設值
        #expect(decoded.exitCode == 0)  // 使用預設值
    }

    @Test("複雜型別預設值 - 陣列和字典")
    func testComplexDefaultValues() throws {
        let json = """
        {
            "id": "app1"
        }
        """

        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AppMetadata.self, from: data)

        #expect(decoded.id == "app1")
        #expect(decoded.tags == [])  // 使用預設值
        #expect(decoded.labels == [:])  // 使用預設值
        #expect(decoded.enabled == true)  // 使用預設值
    }

    @Test("混合預設值 - 部分有預設值部分沒有")
    func testMixedDefaultValues() throws {
        let json = """
        {
            "name": "TestService"
        }
        """

        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(ServiceConfig.self, from: data)

        #expect(decoded.name == "TestService")
        #expect(decoded.port == 8080)  // 使用預設值
        #expect(decoded.host == "localhost")  // 使用預設值
        #expect(decoded.ssl == nil)  // Optional，沒有預設值
    }
}

// MARK: - 測試用型別

@Codable
struct APIConfig {
    let apiKey: String
    let timeout: Int = 30
    let retryCount: Int = 3
}

@Codable
struct CommandOutput {
    let stdout: String?
    let stderr: String? = nil
    let exitCode: Int? = 0
}

@Codable
struct AppMetadata {
    let id: String
    let tags: [String] = []
    let labels: [String: String] = [:]
    let enabled: Bool = true
}

@Codable
struct ServiceConfig {
    let name: String
    let port: Int = 8080
    let host: String = "localhost"
    let ssl: Bool?
}
