import Foundation
import CodableMacro

// MARK: - 範例使用

/// 基本的 Message 結構
@Codable
struct Message {
    let id: String
    let content: String
    let timestamp: Date
}

/// 支援 Optional 屬性的 User 結構
@Codable
struct User {
    let id: String
    let name: String?
    let email: String?
    let age: Int
}

/// 支援 Collection 型別的 Post 結構  
@Codable
struct Post {
    let id: String
    let title: String
    let tags: [String]
    let metadata: [String: String]
    let views: Int
    let isPublished: Bool
}

/// 支援巢狀結構的複雜範例
@Codable
struct BlogPost {
    let id: String
    let title: String
    let content: String
    let author: User
    let comments: [Comment]?
    let createdAt: Date
}

@Codable
struct Comment {
    let id: String
    let content: String
    let author: String
    let timestamp: Date
}

// MARK: - 使用範例

func demonstrateUsage() {
    print("=== @Codable Macro 使用範例 ===\n")
    
    // 1. 基本 struct 範例
    let message = Message(
        id: "msg-1",
        content: "Hello, Swift Macros!",
        timestamp: Date()
    )
    
    // 2. 帶有 Optional 屬性的 struct
    let user = User(
        id: "user-1", 
        name: "John Doe",
        email: "john@example.com",
        age: 30
    )
    
    // 3. 帶有 Collection 的 struct
    let post = Post(
        id: "post-1",
        title: "Swift Macros 介紹",
        tags: ["swift", "macros", "programming"],
        metadata: ["category": "technology", "difficulty": "intermediate"],
        views: 1250,
        isPublished: true
    )
    
    print("✅ 所有結構都可以正常初始化")
    print("✅ @Codable macro 自動生成了 Codable 實作")
    print("✅ 支援基本型別、Optional 型別和 Collection 型別")
    
    // 實際的 JSON 編碼測試
    do {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        print("\n=== JSON 編碼結果 ===")
        
        // 編碼 Message
        let messageData = try encoder.encode(message)
        let messageJson = String(data: messageData, encoding: .utf8)!
        print("Message JSON:\n\(messageJson)")
        
        // 編碼 User  
        let userData = try encoder.encode(user)
        let userJson = String(data: userData, encoding: .utf8)!
        print("\nUser JSON:\n\(userJson)")
        
        // 編碼 Post
        let postData = try encoder.encode(post)  
        let postJson = String(data: postData, encoding: .utf8)!
        print("\nPost JSON:\n\(postJson)")
        
        print("\n✅ JSON 編碼成功！")
        
    } catch {
        print("❌ 編碼失敗: \(error)")
    }
}

// 如果直接執行此檔案，會運行示範
if CommandLine.arguments.contains("--demo") {
    demonstrateUsage()
}