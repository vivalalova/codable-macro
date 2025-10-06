import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct CodableMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CodableMacro.self,
        CodingKeyMacro.self,
        CodingIgnoredMacro.self,
    ]
}