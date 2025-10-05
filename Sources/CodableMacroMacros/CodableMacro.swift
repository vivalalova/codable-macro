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
        var members: [DeclSyntax] = []

        members.append(try generateCodingKeys(properties: properties))
        members.append(try generateInitFromDecoder(properties: properties))
        members.append(try generateEncodeMethod(properties: properties))
        members.append(try generateFromDictMethod())
        members.append(try generateFromDictArrayMethod())
        members.append(try generateToDictMethod())
        members.append(try generateToDictArrayMethod())

        return members
    }

    static func handleClass(_ declaration: ClassDeclSyntax) throws -> [DeclSyntax] {
        let properties = try extractProperties(from: declaration)
        var members: [DeclSyntax] = []

        members.append(try generateCodingKeys(properties: properties))
        members.append(try generateInitFromDecoderForClass(properties: properties))
        members.append(try generateEncodeMethod(properties: properties))
        members.append(try generateFromDictMethod())
        members.append(try generateFromDictArrayMethod())
        members.append(try generateToDictMethod())
        members.append(try generateToDictArrayMethod())

        return members
    }

    static func handleEnum(_ declaration: EnumDeclSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        let enumType = analyzeEnum(declaration)

        switch enumType {
        case .rawValue:
            let diagnostic = Diagnostic(
                node: declaration.root,
                message: CodableMacroDiagnostic.enumWithRawValueDoesNotNeedMacro
            )
            context.diagnose(diagnostic)
            return []
        case .simple:
            var members = try generateSimpleEnumCodable(declaration)
            members.append(try generateFromDictMethod())
            members.append(try generateFromDictArrayMethod())
            members.append(try generateToDictMethod())
            members.append(try generateToDictArrayMethod())
            return members
        case .associatedValues:
            var members = try generateAssociatedValuesEnumCodable(declaration)
            members.append(try generateFromDictMethod())
            members.append(try generateFromDictArrayMethod())
            members.append(try generateToDictMethod())
            members.append(try generateToDictArrayMethod())
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
}

extension CodableMacro {
    
    /// 從 declaration 中提取所有屬性
    static func extractProperties(from declaration: some DeclGroupSyntax) throws -> [Property] {
        var properties: [Property] = []
        
        for member in declaration.memberBlock.members {
            if let variableDecl = member.decl.as(VariableDeclSyntax.self) {
                for binding in variableDecl.bindings {
                    if let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                       let typeAnnotation = binding.typeAnnotation {
                        
                        let name = pattern.identifier.text
                        let typeDescription = typeAnnotation.type.trimmedDescription
                        let isOptional = typeDescription.hasSuffix("?")
                        let isLet = variableDecl.bindingSpecifier.text == "let"
                        
                        let property = Property(
                            name: name,
                            type: typeDescription,
                            isOptional: isOptional,
                            isLet: isLet
                        )
                        properties.append(property)
                    }
                }
            }
        }
        
        return properties
    }
}

// MARK: - 程式碼生成器

extension CodableMacro {
    
    /// 生成 CodingKeys enum
    static func generateCodingKeys(properties: [Property]) throws -> DeclSyntax {
        let cases = properties.map { "case \($0.name)" }.joined(separator: "\n        ")
        let enumCode = """
        enum CodingKeys: String, CodingKey {
            \(cases)
        }
        """
        return DeclSyntax(stringLiteral: enumCode)
    }
    
    /// 生成 init(from decoder:) 初始化方法
    static func generateInitFromDecoder(properties: [Property]) throws -> DeclSyntax {
        var codeLines: [String] = []
        codeLines.append("let container = try decoder.container(keyedBy: CodingKeys.self)")

        for property in properties {
            if property.isOptional {
                let optionalType = property.type.replacingOccurrences(of: "?", with: "")
                codeLines.append("self.\(property.name) = try container.decodeIfPresent(\(optionalType).self, forKey: .\(property.name))")
            } else {
                codeLines.append("self.\(property.name) = try container.decode(\(property.type).self, forKey: .\(property.name))")
            }
        }

        let bodyCode = codeLines.joined(separator: "\n        ")
        let initMethodCode = """
        init(from decoder: Decoder) throws {
            \(bodyCode)
        }
        """

        return DeclSyntax(stringLiteral: initMethodCode)
    }

    /// 生成 class 的 required init(from decoder:) 初始化方法
    static func generateInitFromDecoderForClass(properties: [Property]) throws -> DeclSyntax {
        var codeLines: [String] = []
        codeLines.append("let container = try decoder.container(keyedBy: CodingKeys.self)")

        for property in properties {
            if property.isOptional {
                let optionalType = property.type.replacingOccurrences(of: "?", with: "")
                codeLines.append("self.\(property.name) = try container.decodeIfPresent(\(optionalType).self, forKey: .\(property.name))")
            } else {
                codeLines.append("self.\(property.name) = try container.decode(\(property.type).self, forKey: .\(property.name))")
            }
        }

        let bodyCode = codeLines.joined(separator: "\n        ")
        let initMethodCode = """
        required init(from decoder: Decoder) throws {
            \(bodyCode)
        }
        """

        return DeclSyntax(stringLiteral: initMethodCode)
    }
    
    /// 生成 encode(to:) 方法
    static func generateEncodeMethod(properties: [Property]) throws -> DeclSyntax {
        var codeLines: [String] = []
        codeLines.append("var container = encoder.container(keyedBy: CodingKeys.self)")
        
        for property in properties {
            if property.isOptional {
                codeLines.append("try container.encodeIfPresent(\(property.name), forKey: .\(property.name))")
            } else {
                codeLines.append("try container.encode(\(property.name), forKey: .\(property.name))")
            }
        }
        
        let bodyCode = codeLines.joined(separator: "\n        ")
        let encodeMethodCode = """
        func encode(to encoder: Encoder) throws {
            \(bodyCode)
        }
        """
        
        return DeclSyntax(stringLiteral: encodeMethodCode)
    }

    /// 生成 fromDict(_:) 靜態方法
    static func generateFromDictMethod() throws -> DeclSyntax {
        let code = """
        static func fromDict(_ dict: [String: Any]) throws -> Self {
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
            let decoder = JSONDecoder()
            return try decoder.decode(Self.self, from: jsonData)
        }
        """
        return DeclSyntax(stringLiteral: code)
    }

    /// 生成 fromDictArray(_:) 靜態方法
    static func generateFromDictArrayMethod() throws -> DeclSyntax {
        let code = """
        static func fromDictArray(_ array: [[String: Any]]) throws -> [Self] {
            try array.map { dict in
                try fromDict(dict)
            }
        }
        """
        return DeclSyntax(stringLiteral: code)
    }

    /// 生成 toDict() 實例方法
    static func generateToDictMethod() throws -> DeclSyntax {
        let code = """
        func toDict() throws -> [String: Any] {
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
    static func generateToDictArrayMethod() throws -> DeclSyntax {
        let code = """
        static func toDictArray(_ array: [Self]) throws -> [[String: Any]] {
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

    static func generateSimpleEnumCodable(_ declaration: EnumDeclSyntax) throws -> [DeclSyntax] {
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
        init(from decoder: Decoder) throws {
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
        func encode(to encoder: Encoder) throws {
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

    static func generateAssociatedValuesEnumCodable(_ declaration: EnumDeclSyntax) throws -> [DeclSyntax] {
        let cases = try extractEnumCases(from: declaration)
        var members: [DeclSyntax] = []

        let mainCodingKeys = cases.map { "case \($0.name)" }.joined(separator: "\n        ")
        let mainCodingKeysEnum = """
        enum CodingKeys: String, CodingKey {
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
            enum \(caseName)CodingKeys: String, CodingKey {
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
        init(from decoder: Decoder) throws {
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
        func encode(to encoder: Encoder) throws {
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