import Foundation
import Testing
import CodableMacro

/// 執行期測試：驗證 public 可見性在實際編譯時的行為
struct RuntimePublicVisibilityTests {

    @Test("Public struct 可以正常編碼解碼")
    func testPublicStructCodable() throws {
        let json = """
        {
            "type": "approval",
            "content": "OK"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let message = try decoder.decode(PublicMessage.self, from: data)

        #expect(message.type == "approval")
        #expect(message.content == "OK")

        // 測試編碼
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(message)
        let decoded = try decoder.decode(PublicMessage.self, from: jsonData)

        #expect(decoded.type == "approval")
        #expect(decoded.content == "OK")
    }

    @Test("Public struct 字典轉換")
    func testPublicStructDictConversion() throws {
        let dict: [String: Any] = [
            "type": "approval",
            "content": "OK"
        ]

        let message = try PublicMessage.fromDict(dict)
        #expect(message.type == "approval")
        #expect(message.content == "OK")

        let outputDict = try message.toDict()
        #expect(outputDict["type"] as? String == "approval")
        #expect(outputDict["content"] as? String == "OK")
    }
}

// MARK: - 測試用型別

@Codable
public struct PublicMessage {
    public let type: String
    public let content: String
}
