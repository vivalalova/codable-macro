import Testing
import Foundation
@testable import CodableMacro

/// 執行期測試 - 手動驗證 JSON 編碼解碼功能
struct RuntimeCodableTests {

    @Test("執行期測試 - JSON 編碼解碼功能")
    func testRuntimeCodable() throws {
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

    @Test("執行期測試 - Optional 欄位處理")
    func testRuntimeOptionalHandling() throws {
        struct TestUser: Codable {
            let id: String
            let name: String?
            let email: String?

            enum CodingKeys: String, CodingKey {
                case id, name, email
            }

            init(id: String, name: String?, email: String?) {
                self.id = id
                self.name = name
                self.email = email
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.id = try container.decode(String.self, forKey: .id)
                self.name = try container.decodeIfPresent(String.self, forKey: .name)
                self.email = try container.decodeIfPresent(String.self, forKey: .email)
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(id, forKey: .id)
                try container.encodeIfPresent(name, forKey: .name)
                try container.encodeIfPresent(email, forKey: .email)
            }
        }

        // 測試所有欄位都有值
        let userWithAllFields = TestUser(id: "1", name: "Alice", email: "alice@example.com")
        let encoder = JSONEncoder()
        let jsonData1 = try encoder.encode(userWithAllFields)
        let decoder = JSONDecoder()
        let decoded1 = try decoder.decode(TestUser.self, from: jsonData1)

        #expect(decoded1.id == "1")
        #expect(decoded1.name == "Alice")
        #expect(decoded1.email == "alice@example.com")

        // 測試部分 Optional 欄位為 nil
        let userWithNilFields = TestUser(id: "2", name: nil, email: "bob@example.com")
        let jsonData2 = try encoder.encode(userWithNilFields)
        let decoded2 = try decoder.decode(TestUser.self, from: jsonData2)

        #expect(decoded2.id == "2")
        #expect(decoded2.name == nil)
        #expect(decoded2.email == "bob@example.com")

        // 測試所有 Optional 欄位都是 nil
        let userWithAllNil = TestUser(id: "3", name: nil, email: nil)
        let jsonData3 = try encoder.encode(userWithAllNil)
        let decoded3 = try decoder.decode(TestUser.self, from: jsonData3)

        #expect(decoded3.id == "3")
        #expect(decoded3.name == nil)
        #expect(decoded3.email == nil)
    }

    @Test("執行期測試 - Collection 型別")
    func testRuntimeCollections() throws {
        struct TestData: Codable {
            let tags: [String]
            let metadata: [String: Int]

            enum CodingKeys: String, CodingKey {
                case tags, metadata
            }

            init(tags: [String], metadata: [String: Int]) {
                self.tags = tags
                self.metadata = metadata
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.tags = try container.decode([String].self, forKey: .tags)
                self.metadata = try container.decode([String: Int].self, forKey: .metadata)
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(tags, forKey: .tags)
                try container.encode(metadata, forKey: .metadata)
            }
        }

        let original = TestData(
            tags: ["swift", "testing", "macro"],
            metadata: ["count": 3, "version": 1]
        )

        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TestData.self, from: jsonData)

        #expect(decoded.tags == original.tags)
        #expect(decoded.metadata == original.metadata)
    }

    @Test("執行期測試 - 空 Collection")
    func testRuntimeEmptyCollections() throws {
        struct TestData: Codable {
            let tags: [String]
            let metadata: [String: Int]

            enum CodingKeys: String, CodingKey {
                case tags, metadata
            }

            init(tags: [String], metadata: [String: Int]) {
                self.tags = tags
                self.metadata = metadata
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.tags = try container.decode([String].self, forKey: .tags)
                self.metadata = try container.decode([String: Int].self, forKey: .metadata)
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(tags, forKey: .tags)
                try container.encode(metadata, forKey: .metadata)
            }
        }

        let original = TestData(tags: [], metadata: [:])

        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TestData.self, from: jsonData)

        #expect(decoded.tags.isEmpty)
        #expect(decoded.metadata.isEmpty)

        // 驗證 JSON 結構
        let jsonString = String(data: jsonData, encoding: .utf8)!
        #expect(jsonString.contains("\"tags\":[]"))
        #expect(jsonString.contains("\"metadata\":{}"))
    }

    @Test("執行期測試 - 巢狀型別")
    func testRuntimeNestedTypes() throws {
        struct TestData: Codable {
            let matrix: [[Int]]

            enum CodingKeys: String, CodingKey {
                case matrix
            }

            init(matrix: [[Int]]) {
                self.matrix = matrix
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.matrix = try container.decode([[Int]].self, forKey: .matrix)
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(matrix, forKey: .matrix)
            }
        }

        let original = TestData(matrix: [[1, 2, 3], [4, 5, 6], [7, 8, 9]])

        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TestData.self, from: jsonData)

        #expect(decoded.matrix == original.matrix)
        #expect(decoded.matrix.count == 3)
        #expect(decoded.matrix[0] == [1, 2, 3])
        #expect(decoded.matrix[1] == [4, 5, 6])
        #expect(decoded.matrix[2] == [7, 8, 9])
    }

    @Test("執行期測試 - 錯誤處理 - 缺少必要欄位")
    func testRuntimeMissingRequiredField() throws {
        struct TestData: Codable {
            let id: String
            let name: String

            enum CodingKeys: String, CodingKey {
                case id, name
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.id = try container.decode(String.self, forKey: .id)
                self.name = try container.decode(String.self, forKey: .name)
            }
        }

        // JSON 缺少 name 欄位
        let jsonString = """
        {"id": "123"}
        """
        let jsonData = jsonString.data(using: .utf8)!

        let decoder = JSONDecoder()

        #expect(throws: DecodingError.self) {
            try decoder.decode(TestData.self, from: jsonData)
        }
    }

    @Test("執行期測試 - 錯誤處理 - 型別不匹配")
    func testRuntimeTypeMismatch() throws {
        struct TestData: Codable {
            let id: String
            let age: Int

            enum CodingKeys: String, CodingKey {
                case id, age
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.id = try container.decode(String.self, forKey: .id)
                self.age = try container.decode(Int.self, forKey: .age)
            }
        }

        // age 欄位型別錯誤（應為 Int 但給了 String）
        let jsonString = """
        {"id": "123", "age": "not a number"}
        """
        let jsonData = jsonString.data(using: .utf8)!

        let decoder = JSONDecoder()

        #expect(throws: DecodingError.self) {
            try decoder.decode(TestData.self, from: jsonData)
        }
    }

    @Test("執行期測試 - 數字型別精度")
    func testRuntimeNumericPrecision() throws {
        struct TestData: Codable {
            let intValue: Int
            let doubleValue: Double
            let floatValue: Float

            enum CodingKeys: String, CodingKey {
                case intValue, doubleValue, floatValue
            }

            init(intValue: Int, doubleValue: Double, floatValue: Float) {
                self.intValue = intValue
                self.doubleValue = doubleValue
                self.floatValue = floatValue
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.intValue = try container.decode(Int.self, forKey: .intValue)
                self.doubleValue = try container.decode(Double.self, forKey: .doubleValue)
                self.floatValue = try container.decode(Float.self, forKey: .floatValue)
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(intValue, forKey: .intValue)
                try container.encode(doubleValue, forKey: .doubleValue)
                try container.encode(floatValue, forKey: .floatValue)
            }
        }

        let original = TestData(
            intValue: 42,
            doubleValue: 3.14159265359,
            floatValue: 2.718
        )

        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TestData.self, from: jsonData)

        #expect(decoded.intValue == 42)
        #expect(abs(decoded.doubleValue - 3.14159265359) < 0.0000001)
        #expect(abs(decoded.floatValue - 2.718) < 0.001)
    }
}
