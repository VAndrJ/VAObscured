#if canImport(VAObscuredMacros)
import Foundation
import SwiftParser
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import Testing
import VAObscured
@testable import VAObscuredMacros

struct VAObscuredKeysCountTests {
    @Test(arguments: [
        "0", "-1", "-1024", "1025", "1_025", "0x401", "0o2001", "0b10000000001",
        "9999999999999999999999999999999999999999", "count", "1 + 1", "1.5",
    ], ["test", ""])
    func invalidCountIsDiagnosedAtArgument(count: String, literal: String) throws {
        let source = """
        #Obscured("\(literal)", encoding: .xor(
            keysCount: \(count)
        ))
        """
        let syntax = Parser.parse(source: source)
        let context = BasicMacroExpansionContext()
        let expanded = syntax.expand(macros: ["Obscured": ObscuredMacro.self], in: context)

        #expect(expanded.description.trimmingCharacters(in: .whitespacesAndNewlines) == #""""#)
        #expect(context.diagnostics.count == 1)
        let diagnostic = try #require(context.diagnostics.first)
        #expect(diagnostic.message == "keysCount must be an integer literal between 1 and 1024.")
        #expect(diagnostic.diagMessage.severity == .error)
        #expect(diagnostic.node.trimmedDescription == count)
        let location = diagnostic.location(converter: SourceLocationConverter(fileName: "test.swift", tree: syntax))
        #expect(location.line == 2)
        #expect(location.column == 16)
    }

    @Test(arguments: ["1", "1024", "1_024", "0x400", "0o2000", "0b100_0000_0000"])
    func validIntegerLiteralIsParsed(count: String) throws {
        let syntax = Parser.parse(source: "#Obscured(\"test\", encoding: .xor(keysCount: \(count)))")
        let macro = try #require(syntax.statements.first?.item.as(MacroExpansionExprSyntax.self))
        let arguments = try macro.arguments.arguments
        #expect(arguments.keysCount == (count == "1" ? 1 : 1024))
    }

    @Test(arguments: [0, -1, 1025, Int.max])
    func generationHelpersRejectInvalidCount(count: Int) {
        for keyShift in KeyShift.allCases {
            #expect(throws: VAObscuredError.self) {
                var generator = MockGenerator()
                _ = try ObscuredMacro.getXORCodeBlockItemListSyntax(data: Data("test".utf8), keysCount: count, keyShift: keyShift, using: &generator)
            }
            #expect(throws: VAObscuredError.self) {
                var generator = MockGenerator()
                _ = try ObscuredMacro.getXORMultipleKeysCodeBlockItemListSyntax(data: Data(), keysCount: count, keyShift: keyShift, using: &generator)
            }
        }
    }

    @Test
    func boundaryCountsDecodeCorrectly() {
        #expect(#Obscured("test", encoding: .xor(keysCount: 1)) == "test")
        #expect(#Obscured("test", encoding: .xor(keysCount: 1024)) == "test")
        #expect(#Obscured("test", encoding: .xor(keysCount: 1_024, keyShift: .addition)) == "test")
        #expect(#Obscured("test", encoding: .xor(keysCount: 0x400, keyShift: .subtraction)) == "test")
    }
}
#endif
