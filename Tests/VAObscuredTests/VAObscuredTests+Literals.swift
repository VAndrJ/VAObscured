#if canImport(VAObscuredMacros)
import Foundation
import SwiftParser
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import Testing
import VAObscured
import VAObscuredMacros

struct VAObscuredLiteralTests {
    @Test
    func escapedLiteral() {
        #expect(#Obscured("line\n\t\"quoted\"\\\r\0\u{1F600}") == "line\n\t\"quoted\"\\\r\0\u{1F600}")
    }

    @Test
    func rawLiteral() {
        #expect(#Obscured(#"literal \n and \#n\#u{1F600}"#) == "literal \\n and \n😀")
        #expect(#Obscured(##"literal \#n and \##n"##) == "literal \\#n and \n")
        #expect(#Obscured(#"literal \(value)"#) == "literal \\(value)")
    }

    @Test
    func multilineLiteral() {
        #expect(
            #Obscured(
                """
                first
                  second
                third\
                fourth
                """
            ) == "first\n  second\nthirdfourth"
        )
        #expect(
            #Obscured(
                #"""
                first\n
                second\#nthird
                """#
            ) == "first\\n\nsecond\nthird"
        )
    }

    @Test
    func emptyLiteral() {
        #expect(#Obscured("") == "")
    }

    @Test(arguments: [
        #"#Obscured("hello \(name)")"#,
        #"#Obscured("\(name)")"#,
        ##"#Obscured(#"hello \#(name)"#)"##,
        #"""
        #Obscured("""
            hello
            \(name)
            """)
        """#,
    ])
    func interpolationIsRejected(source: String) throws {
        let syntax = Parser.parse(source: source)
        let context = BasicMacroExpansionContext()
        let expanded = syntax.expand(macros: ["Obscured": ObscuredMacro.self], in: context)

        #expect(expanded.description.trimmingCharacters(in: .whitespacesAndNewlines) == #""""#)
        #expect(context.diagnostics.count == 1)

        let diagnostic = try #require(context.diagnostics.first)
        #expect(diagnostic.message == VAObscuredError.interpolationNotSupported.description)
        #expect(diagnostic.diagMessage.severity == .error)

        let location = diagnostic.location(converter: SourceLocationConverter(fileName: "test.swift", tree: syntax))
        #expect(location.line == 1)
        #expect(location.column == 1)
    }
}
#endif
