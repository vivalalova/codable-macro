# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 專案概述

這是一個 Swift Macro 專案，提供 `@Codable` macro 來自動產生 Codable 協定實作。使用 Swift 6.1+ 的 Macro 系統，基於 SwiftSyntax 進行程式碼生成。

## 常用指令

### 建置與測試

```bash
# 建置專案
swift build

# 執行所有測試
swift test

# 執行範例
swift run --package-path . Examples.swift --demo
```

## 架構說明

### 三層架構

1. **CodableMacro (Sources/CodableMacro/)**
   - 公開 API 層，定義 `@Codable` macro 介面
   - 使用 `@attached(member)` 和 `@attached(extension)` 屬性
   - 透過 `#externalMacro` 委派給實際實作

2. **CodableMacroMacros (Sources/CodableMacroMacros/)**
   - Macro 實作層，包含實際的程式碼生成邏輯
   - `CodableMacro.swift`: 實作 `MemberMacro` 和 `ExtensionMacro` 協定
   - `CodingKeyMacro.swift`: 實作 `PeerMacro` 協定，用於 @CodingKey 屬性標記
   - `CodableMacroPlugin.swift`: Compiler plugin 進入點
   - 核心邏輯：
     - `extractProperties()`: 從語法樹提取屬性資訊（名稱、型別、是否 Optional、自訂 key）
     - `generateCodingKeys()`: 產生 CodingKeys enum，支援自訂 key 映射
     - `generateInitFromDecoder()`: 產生 `init(from:)` 方法，Optional 屬性使用 `decodeIfPresent`
     - `generateEncodeMethod()`: 產生 `encode(to:)` 方法，Optional 屬性使用 `encodeIfPresent`
     - `generateFromDictMethod()`: 產生 `fromDict(_:)` 靜態方法，從字典轉換為實例
     - `generateFromDictArrayMethod()`: 產生 `fromDictArray(_:)` 靜態方法
     - `generateToDictMethod()`: 產生 `toDict()` 實例方法，將實例轉換為字典
     - `generateToDictArrayMethod()`: 產生 `toDictArray(_:)` 靜態方法

3. **Tests (Tests/CodableMacroTests/)**
   - 使用 Swift Testing 框架
   - `assertMacroExpansion()` 驗證 macro 展開結果
   - 測試涵蓋：基本型別、Optional、Collection、var/let 混合、class、邊界案例、錯誤案例

### 關鍵設計決策

- **支援 struct、class 和 enum**：actor 和 protocol 會拋出錯誤
- **@CodingKey 自訂映射和轉換**：
  - 使用 `@CodingKey("custom_key")` 自訂 JSON key 映射
  - 使用 `@CodingKey(transform: .url)` 自訂型別轉換（透過 `CodingTransformer` 靜態屬性）
  - 可同時使用：`@CodingKey("workspace", transform: .url)`
- **Enum 類型分類**：
  - Simple enum：無 raw value、無 associated values，使用 `singleValueContainer` 編碼為字串
  - Associated values enum：使用 `nestedContainer` 處理複雜結構
  - Raw value enum：偵測後產生 warning，不產生程式碼（已自動符合 Codable）
- **自動判斷 Optional**：透過型別字串結尾是否為 `?` 判斷，自動選用 `decodeIfPresent`/`encodeIfPresent`
- **屬性資訊提取**：使用 SwiftSyntax 的 `VariableDeclSyntax` 和 `IdentifierPatternSyntax` 解析，並檢查 @CodingKey attribute
- **程式碼生成方式**：使用字串模板而非 SwiftSyntaxBuilder DSL，提高可讀性
- **無標籤參數處理**：Associated values enum 的無標籤參數使用 `_0`, `_1`, `_2` 命名
- **字典轉換功能**：利用 JSONSerialization 作為橋接，重用現有 Codable 實作
- **型別轉換器**：使用 `CodingTransform` protocol 定義雙向轉換邏輯，支援內建和自訂轉換器

## 測試策略

### 撰寫測試時注意事項

- 測試檔案位置：`Tests/CodableMacroTests/CodableMacroTests.swift`
- 使用 `assertMacroExpansion()` 比對展開前後程式碼
- `expandedSource` 必須包含完整的展開結果（成員 + extension）
- Optional 型別測試需驗證使用 `decodeIfPresent`/`encodeIfPresent`
- 錯誤案例使用 `diagnostics` 參數驗證錯誤訊息

### 測試類別分類

1. **基本功能測試**：簡單 struct、基本型別
2. **型別變化測試**：Optional、Collection、巢狀型別
3. **屬性修飾詞測試**：let、var、混合
4. **宣告型別測試**：struct、class、enum
5. **Enum 測試**：Simple enum、Associated values enum（有/無標籤）、Raw value enum
6. **邊界案例測試**：空 struct、單一屬性、單一 case enum
7. **錯誤案例測試**：actor、protocol
8. **Dictionary 轉換測試**：Struct、Class、Enum 的字典轉換功能
9. **CodingKey 映射測試**：自訂 key 映射、混合預設與自訂 key

## 專案限制

- 只支援有型別標註的屬性（無法推斷型別）
- 不支援排除特定屬性（所有屬性都會被編碼）
- class 的 `init(from:)` 會自動加上 `required` 關鍵字
- Enum with raw value 無需使用 macro（Swift 已自動符合 Codable）
- Enum with associated values 的參數型別必須符合 Codable

## 功能特色

### @CodingKey 自訂 JSON Key 映射

使用 `@CodingKey` 屬性 macro 可以自訂屬性與 JSON key 的映射：

```swift
@Codable
struct APIRequest {
    @CodingKey("api_key")
    let apiKey: String

    @CodingKey("user_id")
    let userId: String

    let timestamp: Date  // 使用預設 key
}

// 產生的 CodingKeys：
// enum CodingKeys: String, CodingKey {
//     case apiKey = "api_key"
//     case userId = "user_id"
//     case timestamp
// }
```

### 型別轉換支援

使用 `@CodingKey(transform:)` 可以自訂型別在 JSON 和 Swift 之間的轉換：

```swift
@Codable
struct AgentMessage {
    @CodingKey("workspace", transform: .url)
    let workspace: URL  // JSON 中為 String

    @CodingKey("session_id", transform: .uuid)
    let sessionId: UUID  // JSON 中為 String

    @CodingKey(transform: .timestampDate)
    let createdAt: Date  // JSON 中為 Double (timestamp)

    let content: String  // 不需要轉換
}
```

#### 內建轉換器

透過 `CodingTransformer` 提供型別安全的 API，內建以下轉換器：

1. **`.url`**：`URL ↔ String`
2. **`.uuid`**：`UUID ↔ String`
3. **`.iso8601Date`**：`Date ↔ String`（ISO8601 格式）
4. **`.timestampDate`**：`Date ↔ Double`（Unix timestamp）
5. **`.boolInt`**：`Bool ↔ Int`（0/1 轉換）

#### 自訂轉換器

實作 `CodingTransform` protocol 並擴展 `CodingTransformer`：

```swift
import CodableMacro

// 1. 實作轉換器
struct ColorHexTransform: CodingTransform {
    typealias SwiftType = UIColor
    typealias JSONType = String

    func encode(_ value: UIColor) throws -> String {
        return value.toHexString()
    }

    func decode(_ value: String) throws -> UIColor {
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
}
```
