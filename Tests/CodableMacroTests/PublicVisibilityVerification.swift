import Foundation
import CodableMacro

// 這個檔案用於編譯期驗證 public 可見性是否正確
// 如果 public 修飾詞缺失，編譯會失敗

@Codable
public struct PublicUser {
    public let id: String
    public let name: String
}

// 驗證可以在模組外使用（假設這是另一個模組的程式碼）
public func testPublicAccess() throws {
    let json = """
    {
        "id": "123",
        "name": "Test"
    }
    """

    let data = json.data(using: .utf8)!
    let user = try JSONDecoder().decode(PublicUser.self, from: data)

    // 這些方法都應該是 public 可訪問的
    let dict = try user.toDict()
    let userFromDict = try PublicUser.fromDict(dict)

    _ = userFromDict
}
