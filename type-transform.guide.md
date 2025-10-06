# 任務規範：@Codable Macro 型別轉換支援

## 一、功能需求

### 1.1 核心目標

為 `@Codable` macro 新增自定義型別轉換支援，允許開發者自訂屬性在編碼/解碼時的轉換邏輯，以處理 JSON 型別與 Swift 型別不一致的場景。

### 1.2 使用情境

**問題**：某些型別在 JSON 中以不同格式表示，例如：
- `URL` 在 JSON 中以 `String` 表示
- `UUID` 在 JSON 中以 `String` 表示
- `Date` 在 JSON 中可能以 `String`（ISO8601）、`Double`（timestamp）或自訂格式表示
- 自訂型別需要特殊轉換邏輯

**解決方案**：透過 `@CodingKey` macro 的擴展參數 `transform`，提供宣告式的型別轉換機制。

### 1.3 功能範例

```swift
// 基本使用
@Codable
struct AgentMessage {
    @CodingKey("workspace", transform: URLTransform())
    let workspace: URL

    @CodingKey("session_id", transform: UUIDTransform())
    let sessionId: UUID

    @CodingKey("created_at", transform: ISO8601DateTransform())
    let createdAt: Date

    @CodingKey("timestamp", transform: TimestampDateTransform())
    let timestamp: Date

    let content: String  // 不需轉換的屬性
}

// 只需要轉換，不需要自訂 key 名稱
@Codable
struct Config {
    @CodingKey(transform: URLTransform())
    let endpoint: URL
}

// Optional 型別支援
@Codable
struct Profile {
    @CodingKey("avatar_url", transform: URLTransform())
    let avatarUrl: URL?

    @CodingKey(transform: UUIDTransform())
    let deviceId: UUID?
}
```

### 1.4 內建轉換器

專案應提供以下內建轉換器：

1. **URLTransform**：`URL ↔ String`
2. **UUIDTransform**：`UUID ↔ String`
3. **ISO8601DateTransform**：`Date ↔ String`（ISO8601 格式）
4. **TimestampDateTransform**：`Date ↔ Double`（Unix timestamp）
5. **BoolIntTransform**：`Bool ↔ Int`（0/1 轉換）

### 1.5 自訂轉換器支援

開發者應能輕鬆實作自訂轉換器：

```swift
// 自訂轉換器範例
struct ColorHexTransform: CodingTransform {
    typealias SwiftType = UIColor
    typealias JSONType = String

    func encode(_ value: UIColor) throws -> String {
        // 將 UIColor 轉換為 hex string
        return value.toHexString()
    }

    func decode(_ value: String) throws -> UIColor {
        guard let color = UIColor(hexString: value) else {
            throw TransformError.invalidValue
        }
        return color
    }
}

// 使用
@Codable
struct Theme {
    @CodingKey("primary_color", transform: ColorHexTransform())
    let primaryColor: UIColor
}
```

## 二、技術規範

### 2.1 API 設計

#### 2.1.1 CodingTransform Protocol

定義轉換器介面：

```swift
/// 型別轉換器協定
///
/// 定義 Swift 型別與 JSON 型別之間的雙向轉換邏輯
public protocol CodingTransform {
    /// Swift 型別（屬性實際型別）
    associatedtype SwiftType

    /// JSON 型別（在 JSON 中的表示型別，必須符合 Codable）
    associatedtype JSONType: Codable

    /// 將 Swift 型別編碼為 JSON 型別
    /// - Parameter value: Swift 型別的值
    /// - Returns: 轉換後的 JSON 型別值
    /// - Throws: 轉換失敗時拋出錯誤
    func encode(_ value: SwiftType) throws -> JSONType

    /// 將 JSON 型別解碼為 Swift 型別
    /// - Parameter value: JSON 型別的值
    /// - Returns: 轉換後的 Swift 型別值
    /// - Throws: 轉換失敗時拋出錯誤
    func decode(_ value: JSONType) throws -> SwiftType
}
```

#### 2.1.2 @CodingKey Macro 擴展

擴展 `@CodingKey` macro 以支援 `transform` 參數：

```swift
// 現有簽章
@attached(peer)
public macro CodingKey(_ key: String) = #externalMacro(...)

// 新增簽章（只有 transform）
@attached(peer)
public macro CodingKey<T: CodingTransform>(transform: T) = #externalMacro(...)

// 新增簽章（key + transform）
@attached(peer)
public macro CodingKey<T: CodingTransform>(_ key: String, transform: T) = #externalMacro(...)
```

**設計考量**：
- 使用泛型參數 `T: CodingTransform` 而非 `any CodingTransform`，在編譯期保留型別資訊
- 支援三種使用方式：
  1. 只指定 `key`：自訂 JSON key 名稱
  2. 只指定 `transform`：自訂轉換邏輯，使用預設 key 名稱
  3. 同時指定 `key` 和 `transform`：兩者皆自訂

### 2.2 屬性資訊擴展

#### 2.2.1 Property 結構擴展

```swift
struct Property {
    let name: String
    let type: String
    let isOptional: Bool
    let isLet: Bool
    let customKey: String?
    let keyPath: [String]?
    let isIgnored: Bool
    let defaultValue: String?

    // 新增：型別轉換資訊
    let transform: TransformInfo?
}

/// 轉換器資訊
struct TransformInfo {
    /// 轉換器型別名稱（例如 "URLTransform"）
    let transformerType: String

    /// JSON 型別（例如 "String"）
    let jsonType: String

    /// Swift 型別（例如 "URL"）
    let swiftType: String
}
```

#### 2.2.2 提取轉換器資訊

在 `extractProperties()` 中新增轉換器資訊提取邏輯：

```swift
extension CodableMacro {
    static func extractProperties(from declaration: some DeclGroupSyntax) throws -> [Property] {
        var properties: [Property] = []

        for member in declaration.memberBlock.members {
            // ... 現有邏輯 ...

            var transform: TransformInfo? = nil

            for attribute in variableDecl.attributes {
                guard let attributeSyntax = attribute.as(AttributeSyntax.self),
                      let identifierType = attributeSyntax.attributeName.as(IdentifierTypeSyntax.self) else {
                    continue
                }

                let attributeName = identifierType.name.text

                if attributeName == "CodingKey" {
                    // 解析 @CodingKey 參數
                    if let arguments = attributeSyntax.arguments,
                       let labeledExprList = arguments.as(LabeledExprListSyntax.self) {

                        for argument in labeledExprList {
                            // 提取 key 參數
                            if argument.label == nil,  // 無標籤的第一個參數
                               let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self) {
                                customKey = extractStringLiteral(stringLiteral)
                            }

                            // 提取 transform 參數
                            if argument.label?.text == "transform" {
                                transform = try extractTransformInfo(
                                    expression: argument.expression,
                                    propertyType: typeDescription
                                )
                            }
                        }
                    }
                }
            }

            // ... 建立 Property 物件 ...
        }

        return properties.filter { !$0.isIgnored }
    }

    /// 提取轉換器資訊
    /// - Parameters:
    ///   - expression: transform 參數的表達式
    ///   - propertyType: 屬性的型別字串
    /// - Returns: 轉換器資訊
    static func extractTransformInfo(
        expression: ExprSyntax,
        propertyType: String
    ) throws -> TransformInfo {
        // 解析 transform 參數（例如 "URLTransform()"）
        guard let functionCall = expression.as(FunctionCallExprSyntax.self),
              let calledExpression = functionCall.calledExpression.as(DeclReferenceExprSyntax.self) else {
            throw TransformExtractionError.invalidTransformSyntax
        }

        let transformerType = calledExpression.baseName.text

        // 從轉換器型別名稱推斷 JSON 型別
        // 注意：這裡需要實際執行轉換器的型別推斷
        // 由於 macro 在編譯期執行，無法直接訪問轉換器的 associatedtype
        // 因此需要透過命名慣例或額外資訊來推斷

        // 方案：使用反射或型別擦除的中介表示
        // 實際實作時需要在生成程式碼時動態處理

        let swiftType = propertyType.replacingOccurrences(of: "?", with: "")

        return TransformInfo(
            transformerType: transformerType,
            jsonType: "String",  // 暫時預設，實際應從轉換器推斷
            swiftType: swiftType
        )
    }
}
```

### 2.3 程式碼生成邏輯

#### 2.3.1 CodingKeys 生成調整

**規則**：有 `transform` 的屬性不在 `CodingKeys` 中出現，因為需要手動處理編碼/解碼。

```swift
static func generateCodingKeys(properties: [Property], isPublic: Bool) throws -> DeclSyntax {
    let publicModifier = isPublic ? "public " : ""

    // 過濾掉有 transform 或 keyPath 的屬性
    let simpleProperties = properties.filter {
        $0.keyPath == nil && $0.transform == nil
    }

    let cases = simpleProperties.map { property in
        if let customKey = property.customKey {
            return "case \(property.name) = \"\(customKey)\""
        } else {
            return "case \(property.name)"
        }
    }.joined(separator: "\n        ")

    let enumCode = """
    \(publicModifier)enum CodingKeys: String, CodingKey {
        \(cases)
    }
    """
    return DeclSyntax(stringLiteral: enumCode)
}
```

#### 2.3.2 init(from decoder:) 生成調整

```swift
static func generateInitFromDecoder(properties: [Property], isPublic: Bool) throws -> DeclSyntax {
    let publicModifier = isPublic ? "public " : ""
    var codeLines: [String] = []

    let (simpleProperties, nestedGroups, transformProperties) = categorizeProperties(properties)

    // 如果有簡單屬性，需要 container
    if !simpleProperties.isEmpty {
        codeLines.append("let container = try decoder.container(keyedBy: CodingKeys.self)")
    }

    // 處理簡單屬性（無 transform）
    for property in simpleProperties {
        // ... 現有邏輯 ...
    }

    // 處理有 transform 的屬性
    for property in transformProperties {
        let decodeCode = generateTransformDecoding(property: property)
        codeLines.append(decodeCode)
    }

    // 處理巢狀路徑屬性
    for group in nestedGroups {
        let nestedCode = generateNestedDecoding(group: group)
        codeLines.append(nestedCode)
    }

    let bodyCode = codeLines.joined(separator: "\n        ")
    let initMethodCode = """
    \(publicModifier)init(from decoder: Decoder) throws {
        \(bodyCode)
    }
    """

    return DeclSyntax(stringLiteral: initMethodCode)
}

/// 生成 transform 屬性的解碼邏輯
static func generateTransformDecoding(property: Property) -> String {
    guard let transform = property.transform else { return "" }

    let keyName = property.customKey ?? property.name
    let jsonType = transform.jsonType
    let swiftType = transform.swiftType
    let transformerType = transform.transformerType

    // 定義臨時 CodingKey
    let keyStructCode = """
    do {
        struct TransformKey: CodingKey {
            var stringValue: String
            var intValue: Int? { nil }
            init(stringValue: String) { self.stringValue = stringValue }
            init?(intValue: Int) { nil }
        }
        let transformContainer = try decoder.container(keyedBy: TransformKey.self)
    """

    if property.isOptional {
        // Optional 型別：jsonValue 可能不存在
        return """
        \(keyStructCode)
            let transformer = \(transformerType)
            if let jsonValue = try transformContainer.decodeIfPresent(\(jsonType).self, forKey: TransformKey(stringValue: "\(keyName)")) {
                self.\(property.name) = try transformer.decode(jsonValue)
            } else {
                self.\(property.name) = nil
            }
        }
        """
    } else {
        // 非 Optional 型別
        if let defaultValue = property.defaultValue {
            // 有預設值：jsonValue 不存在時使用預設值
            return """
            \(keyStructCode)
                let transformer = \(transformerType)
                if let jsonValue = try transformContainer.decodeIfPresent(\(jsonType).self, forKey: TransformKey(stringValue: "\(keyName)")) {
                    self.\(property.name) = try transformer.decode(jsonValue)
                } else {
                    self.\(property.name) = \(defaultValue)
                }
            }
            """
        } else {
            // 無預設值：jsonValue 必須存在
            return """
            \(keyStructCode)
                let transformer = \(transformerType)
                let jsonValue = try transformContainer.decode(\(jsonType).self, forKey: TransformKey(stringValue: "\(keyName)"))
                self.\(property.name) = try transformer.decode(jsonValue)
            }
            """
        }
    }
}
```

#### 2.3.3 encode(to encoder:) 生成調整

```swift
static func generateEncodeMethod(properties: [Property], isPublic: Bool) throws -> DeclSyntax {
    let publicModifier = isPublic ? "public " : ""
    var codeLines: [String] = []

    let (simpleProperties, nestedGroups, transformProperties) = categorizeProperties(properties)

    // 如果有簡單屬性，需要 container
    if !simpleProperties.isEmpty {
        codeLines.append("var container = encoder.container(keyedBy: CodingKeys.self)")
    }

    // 處理簡單屬性
    for property in simpleProperties {
        // ... 現有邏輯 ...
    }

    // 處理有 transform 的屬性
    for property in transformProperties {
        let encodeCode = generateTransformEncoding(property: property)
        codeLines.append(encodeCode)
    }

    // 處理巢狀路徑屬性
    for group in nestedGroups {
        let nestedCode = generateNestedEncoding(group: group)
        codeLines.append(nestedCode)
    }

    let bodyCode = codeLines.joined(separator: "\n        ")
    let encodeMethodCode = """
    \(publicModifier)func encode(to encoder: Encoder) throws {
        \(bodyCode)
    }
    """

    return DeclSyntax(stringLiteral: encodeMethodCode)
}

/// 生成 transform 屬性的編碼邏輯
static func generateTransformEncoding(property: Property) -> String {
    guard let transform = property.transform else { return "" }

    let keyName = property.customKey ?? property.name
    let jsonType = transform.jsonType
    let transformerType = transform.transformerType

    let keyStructCode = """
    do {
        struct TransformKey: CodingKey {
            var stringValue: String
            var intValue: Int? { nil }
            init(stringValue: String) { self.stringValue = stringValue }
            init?(intValue: Int) { nil }
        }
        var transformContainer = encoder.container(keyedBy: TransformKey.self)
        let transformer = \(transformerType)
    """

    if property.isOptional {
        // Optional 型別：值為 nil 時使用 encodeIfPresent
        return """
        \(keyStructCode)
            if let value = self.\(property.name) {
                let jsonValue = try transformer.encode(value)
                try transformContainer.encode(jsonValue, forKey: TransformKey(stringValue: "\(keyName)"))
            }
        }
        """
    } else {
        // 非 Optional 型別
        return """
        \(keyStructCode)
            let jsonValue = try transformer.encode(self.\(property.name))
            try transformContainer.encode(jsonValue, forKey: TransformKey(stringValue: "\(keyName)"))
        }
        """
    }
}

/// 將屬性分類
/// - Returns: (簡單屬性, 巢狀路徑屬性組, 需要 transform 的屬性)
static func categorizeProperties(_ properties: [Property]) -> ([Property], [[Property]], [Property]) {
    let simpleProperties = properties.filter {
        $0.keyPath == nil && $0.transform == nil
    }
    let transformProperties = properties.filter {
        $0.keyPath == nil && $0.transform != nil
    }
    let nestedProperties = properties.filter {
        $0.keyPath != nil
    }

    // 巢狀屬性分組邏輯（現有）
    let nestedGroups = groupNestedProperties(nestedProperties)

    return (simpleProperties, nestedGroups, transformProperties)
}
```

### 2.4 內建轉換器實作

在 `Sources/CodableMacro/Transforms/` 建立內建轉換器：

```swift
// Sources/CodableMacro/Transforms/URLTransform.swift
import Foundation

/// URL ↔ String 轉換器
public struct URLTransform: CodingTransform {
    public typealias SwiftType = URL
    public typealias JSONType = String

    public init() {}

    public func encode(_ value: URL) throws -> String {
        return value.absoluteString
    }

    public func decode(_ value: String) throws -> URL {
        guard let url = URL(string: value) else {
            throw TransformError.invalidURL(value)
        }
        return url
    }
}

// Sources/CodableMacro/Transforms/UUIDTransform.swift
import Foundation

/// UUID ↔ String 轉換器
public struct UUIDTransform: CodingTransform {
    public typealias SwiftType = UUID
    public typealias JSONType = String

    public init() {}

    public func encode(_ value: UUID) throws -> String {
        return value.uuidString
    }

    public func decode(_ value: String) throws -> UUID {
        guard let uuid = UUID(uuidString: value) else {
            throw TransformError.invalidUUID(value)
        }
        return uuid
    }
}

// Sources/CodableMacro/Transforms/ISO8601DateTransform.swift
import Foundation

/// Date ↔ ISO8601 String 轉換器
public struct ISO8601DateTransform: CodingTransform {
    public typealias SwiftType = Date
    public typealias JSONType = String

    private let formatter: ISO8601DateFormatter

    public init() {
        self.formatter = ISO8601DateFormatter()
    }

    public func encode(_ value: Date) throws -> String {
        return formatter.string(from: value)
    }

    public func decode(_ value: String) throws -> Date {
        guard let date = formatter.date(from: value) else {
            throw TransformError.invalidISO8601Date(value)
        }
        return date
    }
}

// Sources/CodableMacro/Transforms/TimestampDateTransform.swift
import Foundation

/// Date ↔ Unix Timestamp (Double) 轉換器
public struct TimestampDateTransform: CodingTransform {
    public typealias SwiftType = Date
    public typealias JSONType = Double

    public init() {}

    public func encode(_ value: Date) throws -> Double {
        return value.timeIntervalSince1970
    }

    public func decode(_ value: Double) throws -> Date {
        return Date(timeIntervalSince1970: value)
    }
}

// Sources/CodableMacro/Transforms/BoolIntTransform.swift
import Foundation

/// Bool ↔ Int (0/1) 轉換器
public struct BoolIntTransform: CodingTransform {
    public typealias SwiftType = Bool
    public typealias JSONType = Int

    public init() {}

    public func encode(_ value: Bool) throws -> Int {
        return value ? 1 : 0
    }

    public func decode(_ value: Int) throws -> Bool {
        guard value == 0 || value == 1 else {
            throw TransformError.invalidBoolInt(value)
        }
        return value == 1
    }
}

// Sources/CodableMacro/Transforms/TransformError.swift
import Foundation

/// 轉換錯誤
public enum TransformError: Error, CustomStringConvertible {
    case invalidURL(String)
    case invalidUUID(String)
    case invalidISO8601Date(String)
    case invalidBoolInt(Int)
    case invalidValue
    case encodingFailed(Error)
    case decodingFailed(Error)

    public var description: String {
        switch self {
        case .invalidURL(let value):
            return "Invalid URL string: \(value)"
        case .invalidUUID(let value):
            return "Invalid UUID string: \(value)"
        case .invalidISO8601Date(let value):
            return "Invalid ISO8601 date string: \(value)"
        case .invalidBoolInt(let value):
            return "Invalid Bool Int value (expected 0 or 1): \(value)"
        case .invalidValue:
            return "Invalid value for transformation"
        case .encodingFailed(let error):
            return "Encoding failed: \(error)"
        case .decodingFailed(let error):
            return "Decoding failed: \(error)"
        }
    }
}
```

## 三、實作細節

### 3.1 技術挑戰與解決方案

#### 挑戰 1：Macro 編譯期無法訪問 associatedtype

**問題**：Swift Macro 在編譯期執行，無法透過反射獲取轉換器的 `associatedtype JSONType`。

**解決方案**：
1. **約定優於配置**：透過轉換器型別名稱推斷 JSON 型別
   - 例如 `URLTransform` → `String`
   - 建立內建映射表
2. **顯式參數**：在 `@CodingKey` 中明確指定 JSON 型別（進階用法）
   ```swift
   @CodingKey(transform: MyTransform(), jsonType: String.self)
   ```
3. **程式碼生成時動態推斷**：在生成的程式碼中使用型別推斷，讓編譯器自動處理

**建議採用方案 1 + 3**：內建轉換器使用映射表，自訂轉換器依賴編譯器型別推斷。

#### 挑戰 2：與巢狀路徑功能衝突

**問題**：同一屬性可能同時有 `keyPath` 和 `transform`。

**解決方案**：
- 支援兩者共存
- 在生成巢狀解碼時，檢查屬性是否有 `transform`
- 有 `transform` 時使用轉換邏輯，無則使用直接 decode

```swift
// 支援同時使用
@Codable
struct User {
    @CodingKey("profile.avatar", transform: URLTransform())
    let avatarUrl: URL
}
```

#### 挑戰 3：Optional 型別處理

**問題**：`URL?` 的轉換需要處理多層 Optional（JSON 值可能不存在 + 轉換可能失敗）。

**解決方案**：
- 使用 `decodeIfPresent` 獲取 JSON 值
- 轉換失敗時拋出錯誤（不靜默轉為 nil）
- 只有 JSON 值不存在時才設為 nil

### 3.2 型別推斷策略

建立內建轉換器的型別映射表：

```swift
// Sources/CodableMacroMacros/TransformTypeRegistry.swift
struct TransformTypeRegistry {
    static let builtinTransforms: [String: String] = [
        "URLTransform": "String",
        "UUIDTransform": "String",
        "ISO8601DateTransform": "String",
        "TimestampDateTransform": "Double",
        "BoolIntTransform": "Int"
    ]

    static func jsonType(for transformerType: String) -> String? {
        return builtinTransforms[transformerType]
    }
}
```

在 `extractTransformInfo` 中使用：

```swift
static func extractTransformInfo(
    expression: ExprSyntax,
    propertyType: String
) throws -> TransformInfo {
    // ... 提取 transformerType ...

    // 從註冊表查詢 JSON 型別
    let jsonType = TransformTypeRegistry.jsonType(for: transformerType) ?? "String"

    return TransformInfo(
        transformerType: transformerType,
        jsonType: jsonType,
        swiftType: swiftType
    )
}
```

### 3.3 檔案結構

```
Sources/
├── CodableMacro/
│   ├── CodableMacro.swift              # 公開 API
│   ├── Transforms/
│   │   ├── CodingTransform.swift       # Protocol 定義
│   │   ├── TransformError.swift        # 錯誤型別
│   │   ├── URLTransform.swift          # 內建轉換器
│   │   ├── UUIDTransform.swift
│   │   ├── ISO8601DateTransform.swift
│   │   ├── TimestampDateTransform.swift
│   │   └── BoolIntTransform.swift
│   └── ...
├── CodableMacroMacros/
│   ├── CodableMacro.swift              # Macro 實作（修改）
│   ├── CodingKeyMacro.swift            # @CodingKey 實作（修改）
│   ├── TransformTypeRegistry.swift     # 型別映射表（新增）
│   └── ...
└── ...
```

## 四、品質標準

### 4.1 程式碼品質要求

1. **型別安全**
   - 所有轉換器必須正確實作 `CodingTransform` protocol
   - 使用泛型而非型別擦除（`T: CodingTransform` 而非 `any CodingTransform`）
   - 編譯期型別檢查，不依賴執行期反射

2. **錯誤處理**
   - 轉換失敗必須拋出明確的錯誤，不使用預設值或 nil 掩蓋問題
   - 錯誤訊息包含具體的失敗資訊（如無效的 URL 字串）
   - 區分「JSON 值不存在」與「轉換失敗」

3. **效能要求**
   - 轉換器物件輕量化，避免重複建立（例如 DateFormatter 快取）
   - 生成的程式碼避免不必要的中間變數
   - 不使用反射或動態型別檢查

4. **程式碼風格**
   - 遵循既有專案的命名慣例
   - 函數簽章簡潔（≤3 參數）
   - 避免超過 500 行的檔案，適當拆分
   - 不使用底線開頭的變數命名

### 4.2 相容性要求

1. **向後相容**
   - 現有不使用 `transform` 的 `@CodingKey` 功能不受影響
   - 現有測試全部通過
   - 不破壞現有 API

2. **功能組合**
   - `transform` 可以與 `customKey` 同時使用
   - `transform` 可以與 `keyPath` 同時使用
   - `transform` 可以應用於 Optional 屬性
   - `transform` 可以應用於有 `defaultValue` 的屬性

3. **限制**
   - `transform` 不能與 `@CodingIgnored` 同時使用（編譯期檢查）
   - 轉換器的 `JSONType` 必須符合 `Codable`
   - 不支援 computed property（既有限制）

## 五、驗收條件

### 5.1 功能驗收

#### 5.1.1 基本功能

- [ ] `URLTransform` 正確轉換 `URL ↔ String`
- [ ] `UUIDTransform` 正確轉換 `UUID ↔ String`
- [ ] `ISO8601DateTransform` 正確轉換 `Date ↔ String`
- [ ] `TimestampDateTransform` 正確轉換 `Date ↔ Double`
- [ ] `BoolIntTransform` 正確轉換 `Bool ↔ Int`

#### 5.1.2 Macro 展開測試

- [ ] 只有 `transform` 的屬性正確生成程式碼
- [ ] 同時有 `customKey` 和 `transform` 的屬性正確生成程式碼
- [ ] Optional 屬性 + `transform` 正確處理
- [ ] 非 Optional 屬性 + `transform` 正確處理
- [ ] 有 `defaultValue` + `transform` 正確處理
- [ ] `keyPath` + `transform` 同時使用正確處理

#### 5.1.3 執行期測試

- [ ] 編碼：Swift 型別正確轉換為 JSON 型別
- [ ] 解碼：JSON 型別正確轉換為 Swift 型別
- [ ] Optional 屬性：JSON 值不存在時解碼為 nil
- [ ] 轉換失敗：拋出明確錯誤而非 crash
- [ ] 錯誤訊息：包含具體失敗資訊

#### 5.1.4 錯誤處理測試

- [ ] 無效 URL 字串拋出 `TransformError.invalidURL`
- [ ] 無效 UUID 字串拋出 `TransformError.invalidUUID`
- [ ] 無效日期字串拋出 `TransformError.invalidISO8601Date`
- [ ] 無效 Bool Int 值拋出 `TransformError.invalidBoolInt`
- [ ] 錯誤包含詳細的 debug 資訊

### 5.2 相容性驗收

- [ ] 現有所有測試通過（BasicCodableTests、EnumCodableTests 等）
- [ ] 不使用 `transform` 的程式碼功能不受影響
- [ ] `@CodingKey("custom_key")` 現有語法繼續正常運作
- [ ] 專案成功建置（`swift build` 無錯誤）

### 5.3 程式碼品質驗收

- [ ] 所有新增程式碼符合 Swift 6.1 標準
- [ ] 無編譯器警告
- [ ] 遵循專案現有命名慣例
- [ ] 檔案行數不超過 500 行
- [ ] 無底線開頭的變數命名
- [ ] 錯誤處理遵循「拋出錯誤」原則，不使用預設值掩蓋問題

### 5.4 文件驗收

- [ ] `CodingTransform` protocol 有完整的文件註解
- [ ] 每個內建轉換器有使用範例
- [ ] `@CodingKey` macro 的文件更新，包含 `transform` 參數說明
- [ ] README 或 CLAUDE.md 更新，說明新功能

## 六、注意事項

### 6.1 技術風險

1. **Macro 限制**
   - Swift Macro 無法執行任意程式碼或訪問外部型別資訊
   - 必須依賴語法分析和字串模板生成程式碼
   - 無法在編譯期驗證轉換器的 `associatedtype` 正確性

2. **型別推斷限制**
   - 自訂轉換器的 `JSONType` 需要透過映射表或命名慣例推斷
   - 錯誤的型別推斷會導致編譯失敗（這是好事，編譯期捕獲錯誤）

3. **效能考量**
   - 每個有 `transform` 的屬性會生成額外的轉換邏輯
   - 轉換器物件的建立成本（需要輕量化設計）

### 6.2 設計取捨

1. **使用 protocol 而非 closure**
   - ✅ 優點：型別安全、可重用、易於測試
   - ❌ 缺點：需要定義額外的 struct

2. **編譯期推斷而非執行期反射**
   - ✅ 優點：效能更好、型別安全、編譯期錯誤檢查
   - ❌ 缺點：Macro 實作較複雜

3. **不支援泛型轉換器**
   - 例如 `ArrayTransform<T>` 用於 `[String] ↔ String`（逗號分隔）
   - 原因：Macro 語法分析困難，且需求較少
   - 替代方案：使用者可定義具體型別的轉換器

### 6.3 未來擴展方向

1. **轉換器組合**
   ```swift
   @CodingKey(transform: OptionalTransform(URLTransform()))
   let url: URL?  // 雙層 Optional 處理
   ```

2. **泛型轉換器支援**
   ```swift
   @CodingKey(transform: ArrayTransform(separator: ","))
   let tags: [String]  // "tag1,tag2,tag3" ↔ ["tag1", "tag2", "tag3"]
   ```

3. **全域轉換器設定**
   ```swift
   @Codable(dateTransform: ISO8601DateTransform())
   struct Model {
       let createdAt: Date  // 自動使用全域設定的轉換器
   }
   ```

4. **條件轉換**
   ```swift
   @CodingKey(transform: ConditionalTransform { value in
       // 自訂轉換邏輯
   })
   ```

### 6.4 測試策略

1. **單元測試層級**
   - 每個內建轉換器獨立測試（encode + decode）
   - 測試正常流程和錯誤流程

2. **Macro 展開測試層級**
   - 使用 `assertMacroExpansion()` 驗證生成的程式碼
   - 涵蓋各種參數組合（只 transform、transform + key、transform + keyPath）

3. **執行期整合測試層級**
   - 實際建立型別實例，執行 `JSONEncoder`/`JSONDecoder`
   - 驗證往返轉換（roundtrip）的正確性
   - 測試錯誤處理路徑

4. **相容性測試**
   - 確保現有測試全部通過
   - 回歸測試檢查是否破壞現有功能

### 6.5 實作順序建議

1. **第一階段：基礎設施**
   - 定義 `CodingTransform` protocol
   - 定義 `TransformError`
   - 建立 `TransformTypeRegistry`
   - 擴展 `Property` 結構

2. **第二階段：內建轉換器**
   - 實作 `URLTransform`
   - 實作 `UUIDTransform`
   - 實作 `ISO8601DateTransform`
   - 實作 `TimestampDateTransform`
   - 實作 `BoolIntTransform`
   - 為每個轉換器撰寫單元測試

3. **第三階段：Macro 擴展**
   - 擴展 `@CodingKey` macro 簽章
   - 修改 `extractProperties()` 以提取 `transform` 資訊
   - 修改 `categorizeProperties()` 以分類屬性
   - 撰寫 Macro 展開測試

4. **第四階段：程式碼生成**
   - 修改 `generateCodingKeys()` 排除 transform 屬性
   - 實作 `generateTransformDecoding()`
   - 實作 `generateTransformEncoding()`
   - 修改 `generateInitFromDecoder()` 和 `generateEncodeMethod()`
   - 撰寫 Macro 展開測試

5. **第五階段：整合與測試**
   - 撰寫執行期整合測試
   - 測試各種參數組合
   - 測試錯誤處理
   - 相容性測試
   - 文件更新

6. **第六階段：優化與擴展**
   - 效能優化（如有需要）
   - 支援 `keyPath` + `transform` 組合
   - 文件完善

### 6.6 關鍵檢查點

在每個階段完成後，執行以下檢查：

1. **建置檢查**
   ```bash
   swift build
   ```
   - 無錯誤
   - 無警告

2. **測試檢查**
   ```bash
   swift test
   ```
   - 所有測試通過
   - 新增測試覆蓋新功能

3. **程式碼品質檢查**
   - 檔案行數 ≤ 500 行
   - 無底線開頭變數
   - 錯誤處理使用 throw 而非預設值
   - 遵循專案命名慣例

4. **功能驗證**
   - 手動測試範例程式碼
   - 驗證生成的程式碼格式正確
   - 驗證錯誤訊息清晰明確

## 七、參考資料

### 7.1 相關專案檔案

- `Sources/CodableMacroMacros/CodableMacro.swift`：主要 Macro 實作
- `Sources/CodableMacroMacros/CodingKeyMacro.swift`：@CodingKey 實作
- `Sources/CodableMacro/CodableMacro.swift`：公開 API 定義
- `Tests/CodableMacroTests/CodingKeyMappingTests.swift`：@CodingKey 測試範例

### 7.2 技術文件

- Swift Macro 官方文件：https://docs.swift.org/swift-book/documentation/the-swift-programming-language/macros/
- SwiftSyntax 文件：https://github.com/apple/swift-syntax
- Codable 文件：https://developer.apple.com/documentation/swift/codable

### 7.3 設計參考

本設計參考以下專案的轉換器設計：
- **ObjectMapper**（iOS）：`Transform` protocol 設計
- **Moshi**（Android）：`JsonAdapter` 設計
- **Serde**（Rust）：編譯期型別轉換設計

本規範提供的設計結合了：
- Swift 的型別安全特性
- Macro 的編譯期生成能力
- Protocol 的抽象能力
- 符合專案現有的架構風格
