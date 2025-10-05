# @Codable Swift Macro

一個強大的 Swift Macro，可以自動為 struct 和 class 產生 Codable 協定的實作。

## 功能特色

- ✅ 自動產生 `CodingKeys` enum
- ✅ 自動產生 `init(from decoder: Decoder)` 初始化方法  
- ✅ 自動產生 `encode(to encoder: Encoder)` 編碼方法
- ✅ 自動添加 Codable 協定符合
- ✅ 支援基本型別 (String, Int, Double, Bool, Date 等)
- ✅ 支援 Optional 型別 (`String?`, `Int?` 等)
- ✅ 支援 Collection 型別 (`[String]`, `[String: String]` 等)
- ✅ 支援巢狀 Codable 型別
- ✅ 完整的錯誤處理和診斷訊息

## 安裝

### Swift Package Manager

在 `Package.swift` 中添加依賴：

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/codable-macro.git", from: "1.0.0")
]
```

然後在你的 target 中添加：

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "CodableMacro", package: "codable-macro")
    ]
)
```

## 使用方法

### 基本使用

```swift
import CodableMacro

@Codable
struct Message {
    let id: String
    let content: String
    let timestamp: Date
}

// 自動產生的程式碼等同於：
struct Message: Codable {
    let id: String
    let content: String  
    let timestamp: Date
    
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
```

### Optional 型別支援

```swift
@Codable
struct User {
    let id: String
    let name: String?      // Optional 屬性
    let email: String?     // Optional 屬性  
    let age: Int
}

// 自動使用 decodeIfPresent 和 encodeIfPresent 處理 Optional 型別
```

### Collection 型別支援

```swift
@Codable
struct Post {
    let id: String
    let tags: [String]                    // Array
    let metadata: [String: String]        // Dictionary
    let views: Int
    let isPublished: Bool
}
```

### Enum 型別支援

#### Simple Enum（無參數）

```swift
@Codable
enum Direction {
    case north
    case south
    case east
    case west
}

// 編碼為字串："north", "south" 等
```

#### Enum with Associated Values（有關聯值）

```swift
@Codable
enum NetworkResponse {
    case success(data: String, statusCode: Int)
    case failure(error: String)
    case empty
}

// 編碼為：
// {"success": {"data": "...", "statusCode": 200}}
// {"failure": {"error": "Network timeout"}}
// {"empty": {}}
```

#### 無標籤關聯值

```swift
@Codable
enum Result {
    case success(String)
    case failure(Int, String)
}

// 無標籤參數使用 _0, _1 作為 key
// {"success": {"_0": "OK"}}
// {"failure": {"_0": 500, "_1": "Error"}}
```

#### Enum with Raw Value（已自動符合）

```swift
// ⚠️ 不需要使用 @Codable macro
enum Status: String, Codable {
    case active
    case inactive
}

// Raw value enum 已自動符合 Codable
```

### 巢狀型別支援

```swift
@Codable
struct BlogPost {
    let id: String
    let title: String
    let author: User           // 巢狀 Codable 型別
    let comments: [Comment]?   // Optional Array of Codable 型別
    let createdAt: Date
}

@Codable
struct Comment {
    let id: String
    let content: String
    let author: String
    let timestamp: Date
}
```

## 支援的型別

- ✅ `struct`
- ✅ `class`（自動產生 `required init`）
- ✅ `enum`（Simple enum、Associated values enum）
- ✅ `let` 和 `var` 屬性
- ✅ Optional 型別（自動使用 `decodeIfPresent`/`encodeIfPresent`）
- ✅ Collection 型別（Array、Dictionary 等）
- ✅ 巢狀 Codable 型別

## 限制

- ❌ 不支援 `actor`、`protocol`
- ❌ Enum with raw value 已自動符合 Codable，無需使用 macro
- ❌ 所有屬性必須有型別標註
- ❌ 屬性型別必須符合 Codable 協定

## JSON 編碼/解碼範例

```swift
let user = User(
    id: "123",
    name: "John Doe", 
    email: "john@example.com",
    age: 30
)

// 編碼為 JSON
let encoder = JSONEncoder()
let jsonData = try encoder.encode(user)

// 從 JSON 解碼
let decoder = JSONDecoder()
let decodedUser = try decoder.decode(User.self, from: jsonData)
```

## 開發與測試

```bash
# 編譯專案
swift build

# 執行測試
swift test

# 查看使用範例
# 範例程式碼位於 Examples.swift 和 TestExample.swift
```

## 技術實作

此 macro 使用 Swift 的最新 Macro 系統實作：

- **MemberMacro**: 自動添加 CodingKeys enum、init(from:) 和 encode(to:) 方法
- **ExtensionMacro**: 自動添加 Codable 協定符合
- **SwiftSyntax**: 用於程式碼解析和生成
- **SwiftSyntaxBuilder**: 用於建構新的語法節點

## 貢獻

歡迎提交 Issue 和 Pull Request！

## 授權

MIT License