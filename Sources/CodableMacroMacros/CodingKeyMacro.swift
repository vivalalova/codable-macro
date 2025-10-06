import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

/// CodingKeyMacro 實作，用於自訂 CodingKeys 映射
public struct CodingKeyMacro: PeerMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // PeerMacro 不產生額外程式碼，只用於標記屬性
        // 實際的 key mapping 會在 CodableMacro 的 extractProperties 中處理
        return []
    }
}
