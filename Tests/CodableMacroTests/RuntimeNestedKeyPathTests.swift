import Testing
import Foundation
@testable import CodableMacro

// 測試用型別定義（必須在全域範圍）
@Codable
struct NestedUserProfile {
    @CodingKey("user.name")
    let userName: String

    @CodingKey("user.age")
    let userAge: Int
}

@Codable
struct NestedAPIResponse {
    @CodingKey("data.response.user.name")
    let userName: String
}

@Codable
struct NestedProduct {
    let id: String

    @CodingKey("info.name")
    let productName: String

    @CodingKey("info.price")
    let price: Double

    let quantity: Int
}

@Codable
struct NestedConfig {
    @CodingKey("settings.timeout")
    let timeout: Int?

    @CodingKey("settings.enabled")
    var enabled: Bool? = true
}

/// 執行期測試 - 巢狀路徑 JSON 編碼解碼功能
struct RuntimeNestedKeyPathTests {

    @Test("執行期測試 - 基本巢狀路徑")
    func testBasicNestedPath() throws {
        // 測試解碼
        let jsonString = """
        {
            "user": {
                "name": "Alice",
                "age": 30
            }
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(NestedUserProfile.self, from: jsonData)

        #expect(decoded.userName == "Alice")
        #expect(decoded.userAge == 30)

        // 測試編碼
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        let encodedData = try encoder.encode(decoded)
        let encodedString = String(data: encodedData, encoding: .utf8)!

        #expect(encodedString.contains("\"user\""))
        #expect(encodedString.contains("\"name\" : \"Alice\""))
        #expect(encodedString.contains("\"age\" : 30"))
    }

    @Test("執行期測試 - 深層巢狀路徑")
    func testDeepNestedPath() throws {
        // 測試解碼
        let jsonString = """
        {
            "data": {
                "response": {
                    "user": {
                        "name": "Bob"
                    }
                }
            }
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(NestedAPIResponse.self, from: jsonData)

        #expect(decoded.userName == "Bob")

        // 測試編碼
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(decoded)
        let encodedString = String(data: encodedData, encoding: .utf8)!

        #expect(encodedString.contains("\"data\""))
        #expect(encodedString.contains("\"response\""))
        #expect(encodedString.contains("\"user\""))
        #expect(encodedString.contains("\"name\":\"Bob\""))
    }

    @Test("執行期測試 - 混合簡單和巢狀屬性")
    func testMixedSimpleAndNested() throws {
        // 測試解碼
        let jsonString = """
        {
            "id": "prod-123",
            "info": {
                "name": "Widget",
                "price": 19.99
            },
            "quantity": 50
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(NestedProduct.self, from: jsonData)

        #expect(decoded.id == "prod-123")
        #expect(decoded.productName == "Widget")
        #expect(decoded.price == 19.99)
        #expect(decoded.quantity == 50)

        // 測試編碼
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let encodedData = try encoder.encode(decoded)
        let encodedString = String(data: encodedData, encoding: .utf8)!

        // 驗證 JSON 結構
        #expect(encodedString.contains("\"id\":\"prod-123\""))
        #expect(encodedString.contains("\"info\""))
        #expect(encodedString.contains("\"name\":\"Widget\""))
        #expect(encodedString.contains("\"price\":19.99"))
        #expect(encodedString.contains("\"quantity\":50"))
    }

    @Test("執行期測試 - Optional 巢狀屬性")
    func testOptionalNestedProperty() throws {
        // 測試有值的情況
        let json1 = """
        {
            "settings": {
                "timeout": 30,
                "enabled": false
            }
        }
        """
        let decoder = JSONDecoder()
        let decoded1 = try decoder.decode(NestedConfig.self, from: json1.data(using: .utf8)!)
        #expect(decoded1.timeout == 30)
        #expect(decoded1.enabled == false)

        // 測試缺少值的情況（使用預設值）
        let json2 = """
        {
            "settings": {}
        }
        """
        let decoded2 = try decoder.decode(NestedConfig.self, from: json2.data(using: .utf8)!)
        #expect(decoded2.timeout == nil)
        #expect(decoded2.enabled == true)  // 使用預設值
    }
}
