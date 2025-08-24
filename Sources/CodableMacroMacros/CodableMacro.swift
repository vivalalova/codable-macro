import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation

/// CodableMacro 實作，提供自動 Codable 生成功能
public struct CodableMacro: MemberMacro, ExtensionMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        // 確保 declaration 是 struct 或 class
        guard declaration.is(StructDeclSyntax.self) || declaration.is(ClassDeclSyntax.self) else {
            throw CodableMacroError.onlyApplicableToStructsAndClasses
        }
        
        // 解析屬性
        let properties = try extractProperties(from: declaration)
        
        // 生成所需的成員
        var members: [DeclSyntax] = []
        
        // 1. 生成 CodingKeys enum
        members.append(try generateCodingKeys(properties: properties))
        
        // 2. 生成 init(from decoder:) 初始化方法
        members.append(try generateInitFromDecoder(properties: properties))
        
        // 3. 生成 encode(to:) 方法
        members.append(try generateEncodeMethod(properties: properties))
        
        return members
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
}

// MARK: - 錯誤處理

enum CodableMacroError: CustomStringConvertible, Error {
    case onlyApplicableToStructsAndClasses
    
    var description: String {
        switch self {
        case .onlyApplicableToStructsAndClasses:
            return "@Codable 只能應用於 struct 或 class"
        }
    }
}