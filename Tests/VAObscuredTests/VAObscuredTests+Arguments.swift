#if canImport(VAObscuredMacros)
import Foundation
import SwiftParser
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import Testing
import VAObscured
@testable import VAObscuredMacros

struct VAObscuredArgumentTests {
    @Test(
        arguments: [
            ".xor",
            ".xor()",
            "ObscuredEncoding.xor",
            "VAObscured.ObscuredEncoding.xor()",
        ]
    )
    func defaultEncoding(expression: String) throws {
        let arguments = try parse("#Obscured(\"test\", encoding: \(expression))")
        #expect(arguments.keysCount == 1)
        #expect(arguments.isAdding == nil)
    }

    @Test(
        arguments: [
            "",
            "ObscuredEncoding.",
            "VAObscured.ObscuredEncoding.",
        ],
        [
            "none",
            "addition",
            "substraction",
        ]
    )
    func encodingAndShiftMembers(qualifier: String, shift: String) throws {
        let encoding = qualifier.isEmpty ? ".xor" : "\(qualifier)xor"
        let shiftExpression = qualifier.isEmpty ? ".\(shift)" : "\(qualifier)KeyShift.\(shift)"
        let arguments = try parse("#Obscured(\"test\", encoding: \(encoding)(keysCount: 4, keyShift: \(shiftExpression)))")
        #expect(arguments.keysCount == 4)
        #expect(arguments.isAdding == (shift == "none" ? nil : shift == "addition"))
    }

    @Test
    func omittedArgumentsAndTrivia() throws {
        let defaults = try parse(#"#Obscured("test")"#)
        #expect(defaults.keysCount == 1)
        #expect(defaults.isAdding == nil)
        let shiftOnly = try parse(#"#Obscured("test", encoding: .xor(keyShift: .addition))"#)
        #expect(shiftOnly.keysCount == 1)
        #expect(shiftOnly.isAdding == true)
        let withComments = try parse(#"#Obscured("test", encoding: ObscuredEncoding /* comment */ .xor(keysCount: 4))"#)
        #expect(withComments.keysCount == 4)
    }

    @Test(
        arguments: [
            "encoding",
            "xorEncoding",
            "makeXor()",
            "makeEncoding()",
            ".notxor()",
            ".xorOther()",
            "Other.xor()",
            "object.xor",
            "ObscuredEncoding.xor(keysCount:keyShift:)",
            "(.xor())",
            "true ? .xor() : .xor()",
            ".xor() { 1 }",
            ".xor /* comment */ + .xor",
        ]
    )
    func unsupportedEncodingIsRejected(expression: String) throws {
        try checkDiagnostic(
            source: "#Obscured(\"test\", encoding: \(expression))",
            expression: expression,
            error: .invalidEncoding
        )
    }

    @Test(
        arguments: [
            "shift",
            "makeShift()",
            ".unknown",
            "Other.addition",
            ".addition()",
            "(.none)",
            "true ? .addition : .none",
        ]
    )
    func unsupportedShiftIsRejected(expression: String) throws {
        try checkDiagnostic(
            source: "#Obscured(\"test\", encoding: .xor(keyShift: \(expression)))",
            expression: expression,
            error: .invalidKeyShift
        )
    }

    @Test(arguments: [
        (".xor(4)", "4"),
        (".xor(count: 4)", "4"),
        (".xor(keysCount: 1, keysCount: 4)", "4"),
        (".xor(keyShift: .none, keyShift: .addition)", ".addition"),
        (".xor(keyShift: .none, keysCount: 4)", "4"),
        (".xor(keysCount: 1, unexpected: 4)", "4"),
    ])
    func unsupportedCallArgumentsAreRejected(expression: String, offending: String) throws {
        try checkDiagnostic(
            source: "#Obscured(\"test\", encoding: \(expression))",
            expression: offending,
            error: .invalidEncodingArguments
        )
    }

    @Test(arguments: [
        (#"#Obscured(string: "test")"#, #""test""#),
        (#"#Obscured("test", .xor())"#, ".xor()"),
        (#"#Obscured("test", option: .xor())"#, ".xor()"),
        (#"#Obscured("test", encoding: .xor, encoding: .xor())"#, ".xor()"),
        (#"#Obscured("test") { 1 }"#, "{ 1 }"),
    ])
    func unsupportedMacroArgumentsAreRejected(source: String, offending: String) throws {
        try checkDiagnostic(source: source, expression: offending, error: .invalidMacroArguments)
    }

    @Test
    func qualifiedFormsDecodeCorrectly() {
        #expect(#Obscured("test", encoding: ObscuredEncoding.xor) == "test")
        #expect(#Obscured("test", encoding: VAObscured.ObscuredEncoding.xor(keysCount: 4, keyShift: VAObscured.ObscuredEncoding.KeyShift.addition)) == "test")
    }

    private func parse(_ source: String) throws -> Arguments {
        let syntax = Parser.parse(source: source)
        let macro = try #require(syntax.statements.first?.item.as(MacroExpansionExprSyntax.self))
        return try macro.arguments.arguments
    }

    private func checkDiagnostic(source: String, expression: String, error: VAObscuredError) throws {
        let syntax = Parser.parse(source: source)
        let context = BasicMacroExpansionContext()
        let expanded = syntax.expand(macros: ["Obscured": ObscuredMacro.self], in: context)
        #expect(expanded.description.trimmingCharacters(in: .whitespacesAndNewlines) == #""""#)
        #expect(context.diagnostics.count == 1)
        let diagnostic = try #require(context.diagnostics.first)
        #expect(diagnostic.message == error.description)
        #expect(diagnostic.diagMessage.severity == .error)
        #expect(diagnostic.node.trimmedDescription == expression)
        let range = try #require(source.range(of: expression, options: .backwards))
        let location = diagnostic.location(converter: SourceLocationConverter(fileName: "test.swift", tree: syntax))
        #expect(location.line == 1)
        #expect(location.column == source[..<range.lowerBound].utf8.count + 1)
    }
}
#endif
