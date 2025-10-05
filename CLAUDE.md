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
   - `CodableMacroPlugin.swift`: Compiler plugin 進入點
   - 核心邏輯：
     - `extractProperties()`: 從語法樹提取屬性資訊（名稱、型別、是否 Optional）
     - `generateCodingKeys()`: 產生 CodingKeys enum
     - `generateInitFromDecoder()`: 產生 `init(from:)` 方法，Optional 屬性使用 `decodeIfPresent`
     - `generateEncodeMethod()`: 產生 `encode(to:)` 方法，Optional 屬性使用 `encodeIfPresent`

3. **Tests (Tests/CodableMacroTests/)**
   - 使用 Swift Testing 框架
   - `assertMacroExpansion()` 驗證 macro 展開結果
   - 測試涵蓋：基本型別、Optional、Collection、var/let 混合、class、邊界案例、錯誤案例

### 關鍵設計決策

- **只支援 struct 和 class**：其他型別（enum、actor、protocol）會拋出 `CodableMacroError.onlyApplicableToStructsAndClasses`
- **自動判斷 Optional**：透過型別字串結尾是否為 `?` 判斷，自動選用 `decodeIfPresent`/`encodeIfPresent`
- **屬性資訊提取**：使用 SwiftSyntax 的 `VariableDeclSyntax` 和 `IdentifierPatternSyntax` 解析
- **程式碼生成方式**：使用字串模板而非 SwiftSyntaxBuilder DSL，提高可讀性

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
4. **宣告型別測試**：struct、class
5. **邊界案例測試**：空 struct、單一屬性
6. **錯誤案例測試**：enum、actor、protocol

## 專案限制

- 只支援有型別標註的屬性（無法推斷型別）
- 不支援自訂 CodingKeys 映射
- 不支援排除特定屬性
- class 的 `init(from:)` 會自動加上 `required` 關鍵字
