import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// @CodingIgnored macro 用於標記不參與 Codable 編碼/解碼的屬性
public struct CodingIgnoredMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // PeerMacro 不生成程式碼，只用於標記
        return []
    }
}
