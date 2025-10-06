import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

/// CodableMacro 實作，提供自動 Codable 生成功能
public struct CodableMacro: MemberMacro, ExtensionMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        // 確保 declaration 是 struct、class 或 enum
        guard declaration.is(StructDeclSyntax.self) ||
              declaration.is(ClassDeclSyntax.self) ||
              declaration.is(EnumDeclSyntax.self) else {
            throw CodableMacroError.unsupportedType
        }

        // 判斷型別並分發到不同處理函式
        if let enumDecl = declaration.as(EnumDeclSyntax.self) {
            return try handleEnum(enumDecl, in: context)
        } else if let structDecl = declaration.as(StructDeclSyntax.self) {
            return try handleStruct(structDecl)
        } else if let classDecl = declaration.as(ClassDeclSyntax.self) {
            return try handleClass(classDecl)
        }

        return []
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {

        // 如果已經符合 Codable，則不需要添加擴展
        if let inheritanceClause = declaration.inheritanceClause {
            for inheritedType in inheritanceClause.inheritedTypes {
                let typeName = inheritedType.type.trimmedDescription
                if typeName == "Codable" || typeName == "Encodable" || typeName == "Decodable" {
                    return []
                }
            }
        }

        // 建立符合 Codable 的擴展
        let codableExtension = try ExtensionDeclSyntax("extension \(type.trimmed): Codable {}")
        return [codableExtension]
    }

    // MARK: - 型別處理函式

    static func handleStruct(_ declaration: StructDeclSyntax) throws -> [DeclSyntax] {
        let properties = try extractProperties(from: declaration)
        let isPublic = isPublicType(declaration)
        var members: [DeclSyntax] = []

        // 只有當有簡單屬性時才生成 CodingKeys
        let (simpleProperties, _, _) = categorizeProperties(properties)
        if !simpleProperties.isEmpty {
            members.append(try generateCodingKeys(properties: properties, isPublic: isPublic))
        }

        // 生成 memberwise initializer
        members.append(try generateMemberwiseInit(properties: properties, isPublic: isPublic))

        members.append(try generateInitFromDecoder(properties: properties, isPublic: isPublic))
        members.append(try generateEncodeMethod(properties: properties, isPublic: isPublic))
        members.append(try generateFromDictMethod(isPublic: isPublic))
        members.append(try generateFromDictArrayMethod(isPublic: isPublic))
        members.append(try generateToDictMethod(isPublic: isPublic))
        members.append(try generateToDictArrayMethod(isPublic: isPublic))

        return members
    }

    static func handleClass(_ declaration: ClassDeclSyntax) throws -> [DeclSyntax] {
        let properties = try extractProperties(from: declaration)
        let isPublic = isPublicType(declaration)
        var members: [DeclSyntax] = []

        // 只有當有簡單屬性時才生成 CodingKeys
        let (simpleProperties, _, _) = categorizeProperties(properties)
        if !simpleProperties.isEmpty {
            members.append(try generateCodingKeys(properties: properties, isPublic: isPublic))
        }

        members.append(try generateInitFromDecoderForClass(properties: properties, isPublic: isPublic))
        members.append(try generateEncodeMethod(properties: properties, isPublic: isPublic))
        members.append(try generateFromDictMethod(isPublic: isPublic))
        members.append(try generateFromDictArrayMethod(isPublic: isPublic))
        members.append(try generateToDictMethod(isPublic: isPublic))
        members.append(try generateToDictArrayMethod(isPublic: isPublic))

        return members
    }

    static func handleEnum(_ declaration: EnumDeclSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        let enumType = analyzeEnum(declaration)
        let isPublic = isPublicType(declaration)

        switch enumType {
        case .rawValue:
            let diagnostic = Diagnostic(
                node: declaration.root,
                message: CodableMacroDiagnostic.enumWithRawValueDoesNotNeedMacro
            )
            context.diagnose(diagnostic)
            return []
        case .simple:
            var members = try generateSimpleEnumCodable(declaration, isPublic: isPublic)
            members.append(try generateFromDictMethod(isPublic: isPublic))
            members.append(try generateFromDictArrayMethod(isPublic: isPublic))
            members.append(try generateToDictMethod(isPublic: isPublic))
            members.append(try generateToDictArrayMethod(isPublic: isPublic))
            return members
        case .associatedValues:
            var members = try generateAssociatedValuesEnumCodable(declaration, isPublic: isPublic)
            members.append(try generateFromDictMethod(isPublic: isPublic))
            members.append(try generateFromDictArrayMethod(isPublic: isPublic))
            members.append(try generateToDictMethod(isPublic: isPublic))
            members.append(try generateToDictArrayMethod(isPublic: isPublic))
            return members
        }
    }
}

// MARK: - 屬性解析

struct Property {
    let name: String
    let type: String
    let isOptional: Bool
    let isLet: Bool
    let customKey: String?
    let keyPath: [String]?  // 新增：巢狀路徑陣列，例如 ["user", "profile", "name"]
    let isIgnored: Bool
    let defaultValue: String?
    let transform: TransformInfo?  // 新增：型別轉換資訊
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

extension CodableMacro {
    
    /// 從 declaration 中提取所有屬性
    static func extractProperties(from declaration: some DeclGroupSyntax) throws -> [Property] {
        var properties: [Property] = []

        for member in declaration.memberBlock.members {
            guard let variableDecl = member.decl.as(VariableDeclSyntax.self) else {
                continue
            }

            for binding in variableDecl.bindings {
                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
                    continue
                }

                // 檢查是否為 computed property（有 accessor block 但無 initializer）
                let isComputedProperty = binding.accessorBlock != nil && binding.initializer == nil
                if isComputedProperty {
                    continue
                }

                guard let typeAnnotation = binding.typeAnnotation else {
                    continue
                }

                let name = pattern.identifier.text
                let typeDescription = typeAnnotation.type.trimmedDescription
                let isOptional = typeDescription.hasSuffix("?")
                let isLet = variableDecl.bindingSpecifier.text == "let"

                // 解析 @CodingKey 和 @CodingIgnored attributes
                var customKey: String? = nil
                var isIgnored = false
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
                                // 提取 key 參數（無標籤的第一個參數）
                                if argument.label == nil,
                                   let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self),
                                   let segment = stringLiteral.segments.first,
                                   let stringSegment = segment.as(StringSegmentSyntax.self) {
                                    customKey = stringSegment.content.text
                                }

                                // 提取 transform 參數
                                if argument.label?.text == "transform" {
                                    // 方案 1: Member access 語法（如 .url 或 CodingTransformer.url）
                                    if let memberAccess = argument.expression.as(MemberAccessExprSyntax.self) {
                                        // 提取成員名稱，如 "url"
                                        let memberName = memberAccess.declName.baseName.text
                                        // 需要從 CodingTransformer 的定義查找對應的類型名稱
                                        // 使用內建映射表
                                        let transformType = transformerNameToType(memberName)
                                        transform = extractTransformInfo(
                                            transformType: transformType,
                                            propertyType: typeDescription
                                        )
                                    }
                                    // 方案 2: 函數呼叫語法（如 CodingTransformer("CustomTransform")）
                                    else if let functionCall = argument.expression.as(FunctionCallExprSyntax.self),
                                            let arguments = functionCall.arguments.first,
                                            let stringLiteral = arguments.expression.as(StringLiteralExprSyntax.self),
                                            let segment = stringLiteral.segments.first,
                                            let stringSegment = segment.as(StringSegmentSyntax.self) {
                                        let transformType = stringSegment.content.text
                                        transform = extractTransformInfo(
                                            transformType: transformType,
                                            propertyType: typeDescription
                                        )
                                    }
                                }
                            }
                        }
                    }

                    if attributeName == "CodingIgnored" {
                        isIgnored = true
                    }
                }

                // 提取預設值
                var defaultValue: String? = nil
                if let initializer = binding.initializer {
                    defaultValue = initializer.value.trimmedDescription
                }

                // 解析巢狀路徑
                var keyPath: [String]? = nil
                if let customKey = customKey, customKey.contains(".") {
                    keyPath = customKey.split(separator: ".").map(String.init)
                }

                let property = Property(
                    name: name,
                    type: typeDescription,
                    isOptional: isOptional,
                    isLet: isLet,
                    customKey: customKey,
                    keyPath: keyPath,
                    isIgnored: isIgnored,
                    defaultValue: defaultValue,
                    transform: transform
                )
                properties.append(property)
            }
        }

        // 過濾掉被標記為忽略的屬性
        return properties.filter { !$0.isIgnored }
    }

    /// 將 CodingTransformer 的靜態屬性名稱映射到實際的轉換器類型名稱
    /// - Parameter memberName: 靜態屬性名稱（如 "url"）
    /// - Returns: 轉換器類型名稱（如 "URLTransform"）
    static func transformerNameToType(_ memberName: String) -> String {
        let mapping: [String: String] = [
            "url": "URLTransform",
            "uuid": "UUIDTransform",
            "iso8601Date": "ISO8601DateTransform",
            "timestampDate": "TimestampDateTransform",
            "boolInt": "BoolIntTransform"
        ]
        return mapping[memberName] ?? memberName.capitalized + "Transform"
    }

    /// 提取轉換器資訊
    /// - Parameters:
    ///   - transformType: 轉換器類型名稱
    ///   - propertyType: 屬性的型別字串
    /// - Returns: 轉換器資訊
    static func extractTransformInfo(
        transformType: String,
        propertyType: String
    ) -> TransformInfo {
        // 從轉換器型別名稱推斷 JSON 型別
        let jsonType = TransformTypeRegistry.jsonType(for: transformType) ?? "String"

        // 移除 Optional 標記獲取 Swift 型別
        let swiftType = propertyType.replacingOccurrences(of: "?", with: "")

        return TransformInfo(
            transformerType: transformType,
            jsonType: jsonType,
            swiftType: swiftType
        )
    }

    /// 檢查型別是否為 public
    static func isPublicType(_ declaration: some DeclGroupSyntax) -> Bool {
        for modifier in declaration.modifiers {
            if modifier.name.tokenKind == .keyword(.public) {
                return true
            }
        }
        return false
    }

    /// 將屬性按照路徑分組，用於生成巢狀 container
    /// 返回：(簡單屬性, 巢狀路徑屬性分組)
    static func groupProperties(_ properties: [Property]) -> ([Property], [[Property]]) {
        let simpleProperties = properties.filter { $0.keyPath == nil }
        let nestedProperties = properties.filter { $0.keyPath != nil }

        // 將巢狀屬性按路徑前綴分組
        var pathGroups: [[Property]] = []
        var processedIndices: Set<Int> = []

        for (index, property) in nestedProperties.enumerated() {
            if processedIndices.contains(index) { continue }

            var group = [property]
            processedIndices.insert(index)

            // 查找其他具有相同路徑前綴的屬性
            for (otherIndex, otherProperty) in nestedProperties.enumerated() {
                if otherIndex == index || processedIndices.contains(otherIndex) { continue }

                // 檢查是否共享路徑前綴
                if let path1 = property.keyPath, let path2 = otherProperty.keyPath {
                    let minLength = min(path1.count, path2.count) - 1  // 至少共享到倒數第二層
                    if minLength > 0 && path1.prefix(minLength) == path2.prefix(minLength) {
                        group.append(otherProperty)
                        processedIndices.insert(otherIndex)
                    }
                }
            }

            pathGroups.append(group)
        }

        return (simpleProperties, pathGroups)
    }

    /// 將屬性分類為簡單、巢狀和需要轉換的屬性
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

        // 巢狀屬性分組邏輯（重用現有邏輯）
        var pathGroups: [[Property]] = []
        var processedIndices: Set<Int> = []

        for (index, property) in nestedProperties.enumerated() {
            if processedIndices.contains(index) { continue }

            var group = [property]
            processedIndices.insert(index)

            for (otherIndex, otherProperty) in nestedProperties.enumerated() {
                if otherIndex == index || processedIndices.contains(otherIndex) { continue }

                if let path1 = property.keyPath, let path2 = otherProperty.keyPath {
                    let minLength = min(path1.count, path2.count) - 1
                    if minLength > 0 && path1.prefix(minLength) == path2.prefix(minLength) {
                        group.append(otherProperty)
                        processedIndices.insert(otherIndex)
                    }
                }
            }

            pathGroups.append(group)
        }

        return (simpleProperties, pathGroups, transformProperties)
    }
}

// MARK: - 程式碼生成器

extension CodableMacro {

    /// 生成 memberwise initializer
    static func generateMemberwiseInit(properties: [Property], isPublic: Bool) throws -> DeclSyntax {
        let publicModifier = isPublic ? "public " : ""

        // 過濾掉被忽略的屬性和 let 屬性有預設值的情況
        let includedProperties = properties.filter { property in
            // 跳過被忽略的屬性
            if property.isIgnored {
                return false
            }
            // let 屬性有預設值時，不包含在參數列表中（因為無法覆蓋）
            if property.isLet && property.defaultValue != nil {
                return false
            }
            return true
        }

        // 生成參數列表
        let parameters = includedProperties.map { property -> String in
            var param = "\(property.name): \(property.type)"

            // Optional 屬性預設值為 nil
            if property.isOptional {
                param += " = nil"
            }
            // var 屬性如果有預設值，加上預設值（var 可以被覆蓋）
            else if !property.isLet && property.defaultValue != nil {
                param += " = \(property.defaultValue!)"
            }

            return param
        }.joined(separator: ",\n    ")

        // 生成賦值語句
        let assignments = includedProperties.map { property -> String in
            return "self.\(property.name) = \(property.name)"
        }

        // 加上被忽略的屬性的初始化
        let ignoredAssignments = properties.filter { $0.isIgnored }.compactMap { property -> String? in
            if let defaultValue = property.defaultValue {
                return "self.\(property.name) = \(defaultValue)"
            }
            return nil
        }

        let allAssignments = (assignments + ignoredAssignments).joined(separator: "\n    ")

        let initCode = """
        \(publicModifier)init(
            \(parameters)
        ) {
            \(allAssignments)
        }
        """

        return DeclSyntax(stringLiteral: initCode)
    }

    /// 生成 CodingKeys enum
    static func generateCodingKeys(properties: [Property], isPublic: Bool) throws -> DeclSyntax {
        let publicModifier = isPublic ? "public " : ""
        // 過濾掉有巢狀路徑或 transform 的屬性，它們不會出現在 CodingKeys 中
        let simpleProperties = properties.filter { $0.keyPath == nil && $0.transform == nil }
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
    
    /// 生成 init(from decoder:) 初始化方法
    static func generateInitFromDecoder(properties: [Property], isPublic: Bool) throws -> DeclSyntax {
        let publicModifier = isPublic ? "public " : ""
        var codeLines: [String] = []

        let (simpleProperties, nestedGroups, transformProperties) = categorizeProperties(properties)

        // 如果有簡單屬性，需要 container
        if !simpleProperties.isEmpty {
            codeLines.append("let container = try decoder.container(keyedBy: CodingKeys.self)")
        }

        // 處理簡單屬性
        for property in simpleProperties {
            // let 屬性有預設值時，跳過初始化（使用成員預設值）
            if property.isLet && property.defaultValue != nil {
                continue
            }

            if property.isOptional {
                let optionalType = property.type.replacingOccurrences(of: "?", with: "")
                if let defaultValue = property.defaultValue {
                    codeLines.append("self.\(property.name) = try container.decodeIfPresent(\(optionalType).self, forKey: .\(property.name)) ?? \(defaultValue)")
                } else {
                    codeLines.append("self.\(property.name) = try container.decodeIfPresent(\(optionalType).self, forKey: .\(property.name))")
                }
            } else {
                // 非 Optional 屬性有預設值時，使用 decodeIfPresent + 預設值
                if let defaultValue = property.defaultValue {
                    codeLines.append("self.\(property.name) = try container.decodeIfPresent(\(property.type).self, forKey: .\(property.name)) ?? \(defaultValue)")
                } else {
                    codeLines.append("self.\(property.name) = try container.decode(\(property.type).self, forKey: .\(property.name))")
                }
            }
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

    /// 生成巢狀路徑的解碼邏輯
    static func generateNestedDecoding(group: [Property]) -> String {
        guard let firstProperty = group.first, let keyPath = firstProperty.keyPath else {
            return ""
        }

        var lines: [String] = []
        lines.append("do {")
        lines.append("    struct DynamicKey: CodingKey {")
        lines.append("        var stringValue: String")
        lines.append("        var intValue: Int? { nil }")
        lines.append("        init(stringValue: String) { self.stringValue = stringValue }")
        lines.append("        init?(intValue: Int) { nil }")
        lines.append("    }")
        lines.append("    let rootContainer = try decoder.container(keyedBy: DynamicKey.self)")

        // 生成巢狀 container 鏈
        for (level, key) in keyPath.dropLast().enumerated() {
            let containerName = "container\(level + 1)"
            let prevContainer = level == 0 ? "rootContainer" : "container\(level)"
            lines.append("    let \(containerName) = try \(prevContainer).nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: \"\(key)\"))")
        }

        // 解碼每個屬性
        for property in group {
            guard let path = property.keyPath, let lastKey = path.last else { continue }

            // let 屬性有預設值時，跳過初始化（使用成員預設值）
            if property.isLet && property.defaultValue != nil {
                continue
            }

            let containerName = path.count > 1 ? "container\(path.count - 1)" : "rootContainer"

            if property.isOptional {
                let optionalType = property.type.replacingOccurrences(of: "?", with: "")
                if let defaultValue = property.defaultValue {
                    lines.append("    self.\(property.name) = try \(containerName).decodeIfPresent(\(optionalType).self, forKey: DynamicKey(stringValue: \"\(lastKey)\")) ?? \(defaultValue)")
                } else {
                    lines.append("    self.\(property.name) = try \(containerName).decodeIfPresent(\(optionalType).self, forKey: DynamicKey(stringValue: \"\(lastKey)\"))")
                }
            } else {
                // 非 Optional 屬性有預設值時，使用 decodeIfPresent + 預設值
                if let defaultValue = property.defaultValue {
                    lines.append("    self.\(property.name) = try \(containerName).decodeIfPresent(\(property.type).self, forKey: DynamicKey(stringValue: \"\(lastKey)\")) ?? \(defaultValue)")
                } else {
                    lines.append("    self.\(property.name) = try \(containerName).decode(\(property.type).self, forKey: DynamicKey(stringValue: \"\(lastKey)\"))")
                }
            }
        }

        lines.append("}")

        return lines.joined(separator: "\n        ")
    }

    /// 生成 transform 屬性的解碼邏輯
    static func generateTransformDecoding(property: Property) -> String {
        guard let transform = property.transform else { return "" }

        let keyName = property.customKey ?? property.name
        let jsonType = transform.jsonType
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
            let transformer = \(transformerType)()
        """

        if property.isOptional {
            // Optional 型別：jsonValue 可能不存在
            return """
            \(keyStructCode)
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
                    let jsonValue = try transformContainer.decode(\(jsonType).self, forKey: TransformKey(stringValue: "\(keyName)"))
                    self.\(property.name) = try transformer.decode(jsonValue)
                }
                """
            }
        }
    }

    /// 生成 class 的 required init(from decoder:) 初始化方法
    static func generateInitFromDecoderForClass(properties: [Property], isPublic: Bool) throws -> DeclSyntax {
        let publicModifier = isPublic ? "public " : ""
        var codeLines: [String] = []

        let (simpleProperties, nestedGroups, transformProperties) = categorizeProperties(properties)

        // 如果有簡單屬性，需要 container
        if !simpleProperties.isEmpty {
            codeLines.append("let container = try decoder.container(keyedBy: CodingKeys.self)")
        }

        // 處理簡單屬性
        for property in simpleProperties {
            // let 屬性有預設值時，跳過初始化（使用成員預設值）
            if property.isLet && property.defaultValue != nil {
                continue
            }

            if property.isOptional {
                let optionalType = property.type.replacingOccurrences(of: "?", with: "")
                if let defaultValue = property.defaultValue {
                    codeLines.append("self.\(property.name) = try container.decodeIfPresent(\(optionalType).self, forKey: .\(property.name)) ?? \(defaultValue)")
                } else {
                    codeLines.append("self.\(property.name) = try container.decodeIfPresent(\(optionalType).self, forKey: .\(property.name))")
                }
            } else {
                // 非 Optional 屬性有預設值時，使用 decodeIfPresent + 預設值
                if let defaultValue = property.defaultValue {
                    codeLines.append("self.\(property.name) = try container.decodeIfPresent(\(property.type).self, forKey: .\(property.name)) ?? \(defaultValue)")
                } else {
                    codeLines.append("self.\(property.name) = try container.decode(\(property.type).self, forKey: .\(property.name))")
                }
            }
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
        \(publicModifier)required init(from decoder: Decoder) throws {
            \(bodyCode)
        }
        """

        return DeclSyntax(stringLiteral: initMethodCode)
    }
    
    /// 生成 encode(to:) 方法
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
            if property.isOptional {
                codeLines.append("try container.encodeIfPresent(\(property.name), forKey: .\(property.name))")
            } else {
                codeLines.append("try container.encode(\(property.name), forKey: .\(property.name))")
            }
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

    /// 生成巢狀路徑的編碼邏輯
    static func generateNestedEncoding(group: [Property]) -> String {
        guard let firstProperty = group.first, let keyPath = firstProperty.keyPath else {
            return ""
        }

        var lines: [String] = []
        lines.append("do {")
        lines.append("    struct DynamicKey: CodingKey {")
        lines.append("        var stringValue: String")
        lines.append("        var intValue: Int? { nil }")
        lines.append("        init(stringValue: String) { self.stringValue = stringValue }")
        lines.append("        init?(intValue: Int) { nil }")
        lines.append("    }")
        lines.append("    var rootContainer = encoder.container(keyedBy: DynamicKey.self)")

        // 生成巢狀 container 鏈
        for (level, key) in keyPath.dropLast().enumerated() {
            let containerName = "container\(level + 1)"
            let prevContainer = level == 0 ? "rootContainer" : "container\(level)"
            lines.append("    var \(containerName) = \(prevContainer).nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: \"\(key)\"))")
        }

        // 編碼每個屬性
        for property in group {
            guard let path = property.keyPath, let lastKey = path.last else { continue }
            let containerName = path.count > 1 ? "container\(path.count - 1)" : "rootContainer"

            if property.isOptional {
                lines.append("    try \(containerName).encodeIfPresent(\(property.name), forKey: DynamicKey(stringValue: \"\(lastKey)\"))")
            } else {
                lines.append("    try \(containerName).encode(\(property.name), forKey: DynamicKey(stringValue: \"\(lastKey)\"))")
            }
        }

        lines.append("}")

        return lines.joined(separator: "\n        ")
    }

    /// 生成 transform 屬性的編碼邏輯
    static func generateTransformEncoding(property: Property) -> String {
        guard let transform = property.transform else { return "" }

        let keyName = property.customKey ?? property.name
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
            let transformer = \(transformerType)()
        """

        if property.isOptional {
            // Optional 型別：值為 nil 時不編碼
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

    /// 生成 fromDict(_:) 靜態方法
    static func generateFromDictMethod(isPublic: Bool) throws -> DeclSyntax {
        let publicModifier = isPublic ? "public " : ""
        let code = """
        \(publicModifier)static func fromDict(_ dict: [String: Any]) throws -> Self {
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
            let decoder = JSONDecoder()
            return try decoder.decode(Self.self, from: jsonData)
        }
        """
        return DeclSyntax(stringLiteral: code)
    }

    /// 生成 fromDictArray(_:) 靜態方法
    static func generateFromDictArrayMethod(isPublic: Bool) throws -> DeclSyntax {
        let publicModifier = isPublic ? "public " : ""
        let code = """
        \(publicModifier)static func fromDictArray(_ array: [[String: Any]]) throws -> [Self] {
            try array.map { dict in
                try fromDict(dict)
            }
        }
        """
        return DeclSyntax(stringLiteral: code)
    }

    /// 生成 toDict() 實例方法
    static func generateToDictMethod(isPublic: Bool) throws -> DeclSyntax {
        let publicModifier = isPublic ? "public " : ""
        let code = """
        \(publicModifier)func toDict() throws -> [String: Any] {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(self)
            guard let dict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
                throw CodableMacro.DictConversionError.invalidDictionaryStructure
            }
            return dict
        }
        """
        return DeclSyntax(stringLiteral: code)
    }

    /// 生成 toDictArray(_:) 靜態方法
    static func generateToDictArrayMethod(isPublic: Bool) throws -> DeclSyntax {
        let publicModifier = isPublic ? "public " : ""
        let code = """
        \(publicModifier)static func toDictArray(_ array: [Self]) throws -> [[String: Any]] {
            try array.map { instance in
                try instance.toDict()
            }
        }
        """
        return DeclSyntax(stringLiteral: code)
    }
}

// MARK: - 錯誤處理

enum CodableMacroError: CustomStringConvertible, Error {
    case unsupportedType
    case onlyApplicableToStructsAndClasses

    var description: String {
        switch self {
        case .unsupportedType:
            return "@Codable can only be applied to struct, class, or enum"
        case .onlyApplicableToStructsAndClasses:
            return "@Codable 只能應用於 struct 或 class"
        }
    }
}

// MARK: - 診斷訊息

enum CodableMacroDiagnostic: String, DiagnosticMessage {
    case enumWithRawValueDoesNotNeedMacro

    var message: String {
        switch self {
        case .enumWithRawValueDoesNotNeedMacro:
            return "Enum with raw value already conforms to Codable"
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "CodableMacro", id: rawValue)
    }

    var severity: DiagnosticSeverity {
        .warning
    }
}

// MARK: - Enum 處理

enum EnumType {
    case simple
    case rawValue
    case associatedValues
}

struct EnumCaseInfo {
    let name: String
    let parameters: [EnumParameterInfo]
}

struct EnumParameterInfo {
    let label: String?
    let type: String
}

extension CodableMacro {

    static func analyzeEnum(_ declaration: EnumDeclSyntax) -> EnumType {
        if declaration.inheritanceClause != nil {
            return .rawValue
        }

        for member in declaration.memberBlock.members {
            if let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) {
                for element in caseDecl.elements {
                    if element.parameterClause != nil {
                        return .associatedValues
                    }
                }
            }
        }

        return .simple
    }

    static func extractEnumCases(from declaration: EnumDeclSyntax) throws -> [EnumCaseInfo] {
        var cases: [EnumCaseInfo] = []

        for member in declaration.memberBlock.members {
            if let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) {
                for element in caseDecl.elements {
                    let caseName = element.name.text
                    var parameters: [EnumParameterInfo] = []

                    if let parameterClause = element.parameterClause {
                        for parameter in parameterClause.parameters {
                            let label = parameter.firstName?.text
                            let type = parameter.type.trimmedDescription

                            let paramInfo = EnumParameterInfo(
                                label: (label == "_" || label == nil) ? nil : label,
                                type: type
                            )
                            parameters.append(paramInfo)
                        }
                    }

                    cases.append(EnumCaseInfo(name: caseName, parameters: parameters))
                }
            }
        }

        return cases
    }

    static func generateSimpleEnumCodable(_ declaration: EnumDeclSyntax, isPublic: Bool) throws -> [DeclSyntax] {
        let publicModifier = isPublic ? "public " : ""
        let cases = try extractEnumCases(from: declaration)

        let decodeSwitchCases = cases.map { caseInfo in
            """
                    case "\(caseInfo.name)":
                        self = .\(caseInfo.name)
            """
        }.joined(separator: "\n")

        let encodeSwitchCases = cases.map { caseInfo in
            """
                    case .\(caseInfo.name):
                        try container.encode("\(caseInfo.name)")
            """
        }.joined(separator: "\n")

        let initMethod = """
        \(publicModifier)init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            switch value {
        \(decodeSwitchCases)
            default:
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Invalid enum case: \\(value)"
                    )
                )
            }
        }
        """

        let encodeMethod = """
        \(publicModifier)func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()

            switch self {
        \(encodeSwitchCases)
            }
        }
        """

        return [
            DeclSyntax(stringLiteral: initMethod),
            DeclSyntax(stringLiteral: encodeMethod)
        ]
    }

    static func generateAssociatedValuesEnumCodable(_ declaration: EnumDeclSyntax, isPublic: Bool) throws -> [DeclSyntax] {
        let publicModifier = isPublic ? "public " : ""
        let cases = try extractEnumCases(from: declaration)
        var members: [DeclSyntax] = []

        let mainCodingKeys = cases.map { "case \($0.name)" }.joined(separator: "\n        ")
        let mainCodingKeysEnum = """
        \(publicModifier)enum CodingKeys: String, CodingKey {
            \(mainCodingKeys)
        }
        """
        members.append(DeclSyntax(stringLiteral: mainCodingKeysEnum))

        for caseInfo in cases where !caseInfo.parameters.isEmpty {
            let caseName = caseInfo.name.prefix(1).uppercased() + caseInfo.name.dropFirst()
            let keys = caseInfo.parameters.enumerated().map { index, param in
                if let label = param.label {
                    return "case \(label)"
                } else {
                    return "case _\(index)"
                }
            }.joined(separator: "\n            ")

            let keysEnum = """
            \(publicModifier)enum \(caseName)CodingKeys: String, CodingKey {
                \(keys)
            }
            """
            members.append(DeclSyntax(stringLiteral: keysEnum))
        }

        var decodeCases: [String] = []
        for caseInfo in cases {
            if caseInfo.parameters.isEmpty {
                decodeCases.append("""
                        case .\(caseInfo.name):
                            self = .\(caseInfo.name)
                """)
            } else {
                let caseName = caseInfo.name.prefix(1).uppercased() + caseInfo.name.dropFirst()
                let decodeStatements = caseInfo.parameters.enumerated().map { index, param in
                    let keyName = param.label ?? "_\(index)"
                    let varName = param.label ?? "_\(index)"
                    return "let \(varName) = try nestedContainer.decode(\(param.type).self, forKey: .\(keyName))"
                }.joined(separator: "\n                    ")

                let constructorParams = caseInfo.parameters.enumerated().map { index, param in
                    let varName = param.label ?? "_\(index)"
                    if let label = param.label {
                        return "\(label): \(varName)"
                    } else {
                        return varName
                    }
                }.joined(separator: ", ")

                decodeCases.append("""
                        case .\(caseInfo.name):
                            let nestedContainer = try container.nestedContainer(keyedBy: \(caseName)CodingKeys.self, forKey: .\(caseInfo.name))
                            \(decodeStatements)
                            self = .\(caseInfo.name)(\(constructorParams))
                """)
            }
        }

        let initMethod = """
        \(publicModifier)init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            if container.allKeys.count != 1 {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Expected exactly one key"
                    )
                )
            }

            let key = container.allKeys.first!

            switch key {
        \(decodeCases.joined(separator: "\n"))
            }
        }
        """
        members.append(DeclSyntax(stringLiteral: initMethod))

        var encodeCases: [String] = []
        for caseInfo in cases {
            if caseInfo.parameters.isEmpty {
                encodeCases.append("""
                        case .\(caseInfo.name):
                            _ = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .\(caseInfo.name))
                """)
            } else {
                let caseName = caseInfo.name.prefix(1).uppercased() + caseInfo.name.dropFirst()
                let letBindings = caseInfo.parameters.enumerated().map { index, param in
                    "let \(param.label ?? "_\(index)")"
                }.joined(separator: ", ")

                let encodeStatements = caseInfo.parameters.enumerated().map { index, param in
                    let keyName = param.label ?? "_\(index)"
                    let varName = param.label ?? "_\(index)"
                    return "try nestedContainer.encode(\(varName), forKey: .\(keyName))"
                }.joined(separator: "\n                    ")

                encodeCases.append("""
                        case .\(caseInfo.name)(\(letBindings)):
                            var nestedContainer = container.nestedContainer(keyedBy: \(caseName)CodingKeys.self, forKey: .\(caseInfo.name))
                            \(encodeStatements)
                """)
            }
        }

        let encodeMethod = """
        \(publicModifier)func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
        \(encodeCases.joined(separator: "\n"))
            }
        }
        """
        members.append(DeclSyntax(stringLiteral: encodeMethod))

        return members
    }
}