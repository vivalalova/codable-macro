# @Codable Swift Macro

一個強大的 Swift Macro，可以自動為 struct 和 class 產生 Codable 協定的實作。

## 功能特色

- ✅ 自動產生 `CodingKeys` enum
- ✅ 自動產生 memberwise initializer（支援 Optional 預設值）
- ✅ 自動產生 `init(from decoder: Decoder)` 初始化方法
- ✅ 自動產生 `encode(to encoder: Encoder)` 編碼方法
- ✅ 自動產生字典轉換方法（`fromDict`、`toDict` 等）
- ✅ 自動添加 Codable 協定符合
- ✅ **支援 @CodingKey 自訂 JSON key 映射**
- ✅ **支援 @CodingKey 巢狀路徑映射（如 `user.profile.name`）**
- ✅ **支援 @CodingKey 型別轉換（URL、UUID、Date 等）**
- ✅ **支援 @CodingIgnored 忽略特定屬性**
- ✅ **支援 Public 可見性（自動產生 public 修飾詞）**
- ✅ **支援屬性預設值（Optional 和非 Optional）**
- ✅ 支援基本型別 (String, Int, Double, Bool 等)
- ✅ 支援 Foundation 型別 (Date, UUID, URL, Data, Decimal 等)
- ✅ 支援 Optional 型別 (`String?`, `Int?` 等)
- ✅ 支援 Collection 型別 (`[String]`, `[String: String]` 等)
- ✅ 支援巢狀 Codable 型別
- ✅ 完整的錯誤處理和診斷訊息

## 安裝

### Swift Package Manager

在 `Package.swift` 中添加依賴：

```swift
dependencies: [
    .package(url: "https://github.com/vivalalova/codable-macro.git", from: "0.2.0")
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

    // Memberwise initializer
    init(
        id: String,
        content: String,
        timestamp: Date
    ) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
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

// 使用 memberwise initializer 創建實例
let message = Message(
    id: "123",
    content: "Hello",
    timestamp: Date()
)
```

### 自訂 JSON Key 映射

使用 `@CodingKey` 可以自訂屬性與 JSON key 的映射關係：

```swift
@Codable
struct APIRequest {
    @CodingKey("api_key")
    let apiKey: String

    @CodingKey("user_id")
    let userId: String

    let timestamp: Date  // 使用預設 key
}

// 自動產生的 CodingKeys：
// enum CodingKeys: String, CodingKey {
//     case apiKey = "api_key"
//     case userId = "user_id"
//     case timestamp
// }
```

JSON 範例：
```json
{
  "api_key": "abc123",
  "user_id": "user_456",
  "timestamp": "2024-01-01T00:00:00Z"
}
```

### 巢狀路徑映射

`@CodingKey` 支援使用點號（`.`）表示巢狀 JSON 路徑，將深層巢狀的資料直接映射到單一屬性：

```swift
@Codable
struct UserInfo {
    @CodingKey("user.profile.name")
    let userName: String

    @CodingKey("user.profile.age")
    let userAge: Int

    let id: String  // 簡單屬性可混合使用
}
```

對應的 JSON：
```json
{
    "id": "123",
    "user": {
        "profile": {
            "name": "Alice",
            "age": 30
        }
    }
}
```

**注意事項：**
- 支援任意深度的巢狀路徑（例如：`a.b.c.d.e`）
- 可以與簡單屬性混合使用
- 多個屬性可以共享路徑前綴（例如：`user.name` 和 `user.age`）
- 屬性支援預設值：`let` 保持預設值無法覆蓋，`var` 可從 JSON 覆蓋

### 型別轉換支援

使用 `@CodingKey(transform:)` 可以自訂型別在 JSON 和 Swift 之間的轉換：

```swift
@Codable
struct APIResponse {
    @CodingKey("endpoint", transform: .url)
    let endpoint: URL  // JSON 中為 String

    @CodingKey("session_id", transform: .uuid)
    let sessionId: UUID  // JSON 中為 String

    @CodingKey(transform: .timestampDate)
    let createdAt: Date  // JSON 中為 Double (timestamp)

    let content: String  // 不需要轉換
}
```

對應的 JSON：
```json
{
    "endpoint": "https://api.example.com/v1",
    "session_id": "550e8400-e29b-41d4-a716-446655440000",
    "createdAt": 1704067200.0,
    "content": "Hello"
}
```

#### 內建轉換器

透過 `CodingTransformer` 提供型別安全的 API：

- **`.url`**：`URL ↔ String`
- **`.uuid`**：`UUID ↔ String`
- **`.iso8601Date`**：`Date ↔ String`（ISO8601 格式）
- **`.timestampDate`**：`Date ↔ Double`（Unix timestamp）
- **`.boolInt`**：`Bool ↔ Int`（0/1 轉換）

#### 自訂轉換器

實作 `CodingTransform` protocol 並擴展 `CodingTransformer`：

```swift
import CodableMacro

// 1. 實作轉換器
struct ColorHexTransform: CodingTransform {
    typealias SwiftType = UIColor
    typealias JSONType = String

    func encode(_ value: UIColor) throws -> String {
        // 將 UIColor 轉換為 hex 字串
        return value.toHexString()
    }

    func decode(_ value: String) throws -> UIColor {
        // 從 hex 字串解析 UIColor
        guard let color = UIColor(hexString: value) else {
            throw TransformError.invalidValue
        }
        return color
    }
}

// 2. 擴展 CodingTransformer
extension CodingTransformer {
    public static let colorHex = CodingTransformer("ColorHexTransform")
}

// 3. 使用
@Codable
struct Theme {
    @CodingKey("primary_color", transform: .colorHex)
    let primaryColor: UIColor

    @CodingKey("accent_color", transform: .colorHex)
    let accentColor: UIColor
}
```

### 忽略特定屬性

使用 `@CodingIgnored` 標記不參與編碼/解碼的屬性：

```swift
@Codable
struct User {
    let id: String
    let name: String

    @CodingIgnored
    var cachedData: String = ""  // 不會被編碼/解碼

    // Computed properties 自動被忽略
    var displayName: String {
        "User: \(name)"
    }
}
```

### Public 可見性支援

`@Codable` 自動偵測型別的 `public` 修飾詞，並產生對應的 public 實作：

```swift
@Codable
public struct APIResponse {
    public let status: String
    public let data: String
}

// 生成的 init(from:) 和 encode(to:) 都會是 public
```

### 預設值支援

屬性可以宣告預設值，當 JSON 解碼缺少該欄位時自動使用預設值。

#### let 屬性預設值

`let` 屬性有預設值時，會保持預設值且**無法從 JSON 覆蓋**（因為 let 無法被初始化兩次）：

```swift
@Codable
struct ImmutableConfig {
    let apiKey: String
    let timeout: Int = 30      // 保持預設值 30，JSON 無法覆蓋
    let retries: Int = 3       // 保持預設值 3，JSON 無法覆蓋
}

// JSON: {"apiKey": "secret"}
// 解碼結果: ImmutableConfig(apiKey: "secret", timeout: 30, retries: 3)

// JSON: {"apiKey": "secret", "timeout": 60}
// 解碼結果: ImmutableConfig(apiKey: "secret", timeout: 30, retries: 3)
// 注意：timeout 仍然是 30，無法從 JSON 覆蓋
```

#### var 屬性預設值

`var` 屬性有預設值時，可以從 JSON 覆蓋：

```swift
@Codable
struct MutableConfig {
    let apiKey: String
    var timeout: Int = 30      // 可從 JSON 覆蓋
    var retries: Int? = 3      // Optional 預設值，可從 JSON 覆蓋
    var items: [String] = []   // Collection 預設值，可從 JSON 覆蓋
}

// JSON: {"apiKey": "secret"}
// 解碼結果: MutableConfig(apiKey: "secret", timeout: 30, retries: 3, items: [])

// JSON: {"apiKey": "secret", "timeout": 60}
// 解碼結果: MutableConfig(apiKey: "secret", timeout: 60, retries: 3, items: [])
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

// Memberwise init 中 Optional 屬性預設為 nil
let user1 = User(id: "123", age: 30)  // name 和 email 為 nil
let user2 = User(id: "456", name: "Alice", age: 25)  // email 為 nil
let user3 = User(id: "789", name: "Bob", email: "bob@example.com", age: 35)

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

### Dictionary 轉換

@Codable macro 自動產生字典轉換方法，方便與動態資料交互：

```swift
@Codable
struct User {
    let id: String
    let name: String
    let age: Int
}

// 從字典建立實例
let dict: [String: Any] = [
    "id": "123",
    "name": "Alice",
    "age": 30
]
let user = try User.fromDict(dict)

// 將實例轉換為字典
let outputDict = try user.toDict()
// outputDict = ["id": "123", "name": "Alice", "age": 30]

// 批次轉換
let usersArray: [[String: Any]] = [
    ["id": "123", "name": "Alice", "age": 30],
    ["id": "456", "name": "Bob", "age": 25]
]
let users = try User.fromDictArray(usersArray)
let dicts = try User.toDictArray(users)
```

**自動產生的方法：**
- `static func fromDict(_ dict: [String: Any]) throws -> Self` - 從字典建立實例
- `static func fromDictArray(_ array: [[String: Any]]) throws -> [Self]` - 從字典陣列建立實例陣列
- `func toDict() throws -> [String: Any]` - 將實例轉換為字典
- `static func toDictArray(_ array: [Self]) throws -> [[String: Any]]` - 將實例陣列轉換為字典陣列

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

### 宣告型別
- ✅ `struct`
- ✅ `class`（自動產生 `required init`）
- ✅ `enum`（Simple enum、Associated values enum）

### 屬性型別
- ✅ 基本型別：String, Int, Double, Float, Bool 等
- ✅ Foundation 型別：Date, UUID, URL, Data, Decimal 等所有符合 Codable 的型別
- ✅ Optional 型別（自動使用 `decodeIfPresent`/`encodeIfPresent`）
- ✅ Collection 型別（Array、Dictionary、Set 等）
- ✅ 巢狀 Codable 型別
- ✅ `let` 和 `var` 屬性

## 限制

- ❌ 不支援 `actor`、`protocol`
- ❌ Enum with raw value 已自動符合 Codable，無需使用 macro
- ❌ 所有屬性必須有型別標註
- ❌ 屬性型別必須符合 Codable 協定
- ⚠️ **let 屬性預設值**：`let` 屬性如果有預設值，無法從 memberwise initializer 覆蓋（Swift 語言限制）。如需覆蓋預設值，請使用 `var`

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