import Foundation

// 手動實作的測試範例，展示 @Codable macro 應該產生的效果

/// 基本的 Message 結構
struct Message: Codable {
    let id: String
    let content: String
    let timestamp: Date
    
    // 一般初始化方法
    init(id: String, content: String, timestamp: Date) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
    }
    
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

/// 支援 Optional 屬性的 User 結構
struct User: Codable {
    let id: String
    let name: String?
    let email: String?
    let age: Int
    
    // 一般初始化方法
    init(id: String, name: String?, email: String?, age: Int) {
        self.id = id
        self.name = name
        self.email = email
        self.age = age
    }
    
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

/// 支援 Collection 型別的 Post 結構
struct Post: Codable {
    let id: String
    let title: String
    let tags: [String]
    let metadata: [String: String]
    let views: Int
    let isPublished: Bool
    
    // 一般初始化方法
    init(id: String, title: String, tags: [String], metadata: [String: String], views: Int, isPublished: Bool) {
        self.id = id
        self.title = title
        self.tags = tags
        self.metadata = metadata
        self.views = views
        self.isPublished = isPublished
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case tags
        case metadata
        case views
        case isPublished
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.tags = try container.decode([String].self, forKey: .tags)
        self.metadata = try container.decode([String: String].self, forKey: .metadata)
        self.views = try container.decode(Int.self, forKey: .views)
        self.isPublished = try container.decode(Bool.self, forKey: .isPublished)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(tags, forKey: .tags)
        try container.encode(metadata, forKey: .metadata)
        try container.encode(views, forKey: .views)
        try container.encode(isPublished, forKey: .isPublished)
    }
}

// MARK: - 使用範例

func demonstrateUsage() {
    print("=== @Codable Macro 功能測試 ===\n")
    
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
    print("✅ 手動實作的 Codable 功能正常運作")
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
        
        // JSON 解碼測試
        print("\n=== JSON 解碼測試 ===")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let decodedMessage = try decoder.decode(Message.self, from: messageData)
        print("✅ Message 解碼成功: \(decodedMessage.content)")
        
        let decodedUser = try decoder.decode(User.self, from: userData)
        print("✅ User 解碼成功: \(decodedUser.name ?? "無名稱")")
        
        let decodedPost = try decoder.decode(Post.self, from: postData)
        print("✅ Post 解碼成功: \(decodedPost.title)")
        
    } catch {
        print("❌ 編碼/解碼失敗: \(error)")
    }
}

// 如果直接執行此檔案，會運行示範
if CommandLine.arguments.contains("--demo") || CommandLine.arguments.count == 1 {
    demonstrateUsage()
}