#if canImport(VAObscuredMacros)
import SwiftParser
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import Testing
@testable import VAObscuredMacros

struct VAObscuredRandomIsolationTests {
    @Test
    func expansionUsesInjectedKeySequence() throws {
        let source = #"#Obscured("0123456789", encoding: .xor(keysCount: 4))"#
        let syntax = try macro(in: source)
        var generator = SequenceGenerator(values: [0, 1, 42, 255, 128])
        let context = BasicMacroExpansionContext()
        let expanded = ObscuredMacro.expansion(of: syntax, in: context, using: &generator).formatted().description

        #expect(context.diagnostics.isEmpty)
        #expect(generator.calls == 5)
        #expect(expanded.contains("let keys: [Swift.UInt8] = [1, 42, 255, 128]"))
        #expect(expanded.contains("let data: [Swift.UInt8] = [49, 27, 205, 179, 53, 31, 201, 183, 57, 19]"))
    }

    @Test
    func injectedStateAdvancesOnlyForItsCaller() throws {
        let syntax = try macro(in: #"#Obscured("test")"#)
        var generator = SequenceGenerator(values: [1, 42])
        let first = ObscuredMacro.expansion(of: syntax, in: BasicMacroExpansionContext(), using: &generator).description
        let independent = try Self.render(key: 255)
        let second = ObscuredMacro.expansion(of: syntax, in: BasicMacroExpansionContext(), using: &generator).description

        #expect(first.contains("byte ^ 1"))
        #expect(second.contains("byte ^ 42"))
        #expect(independent.contains("byte ^ 255"))
        #expect(generator.calls == 2)
        #expect(try Self.render(key: 255) == independent)
    }

    @Test
    func concurrentExpansionsKeepIndependentGenerators() async throws {
        let keys: [UInt64] = [1, 42, 128, 255]
        let expected = try Dictionary(uniqueKeysWithValues: keys.map { ($0, try Self.render(key: $0)) })
        try await withThrowingTaskGroup(of: (UInt64, String).self) { group in
            for index in 0..<32 {
                let key = keys[index % keys.count]
                group.addTask { (key, try Self.render(key: key)) }
            }
            var count = 0
            for try await (key, expansion) in group {
                #expect(expansion == expected[key])
                count += 1
            }
            #expect(count == 32)
        }
    }

    private static func render(key: UInt64) throws -> String {
        let tree = Parser.parse(source: #"#Obscured("test")"#)
        let syntax = try #require(tree.statements.first?.item.as(MacroExpansionExprSyntax.self))
        var generator = MockGenerator(key: key)
        let context = BasicMacroExpansionContext()
        let expanded = ObscuredMacro.expansion(of: syntax, in: context, using: &generator)
        #expect(context.diagnostics.isEmpty)
        return expanded.description
    }

    private func macro(in source: String) throws -> MacroExpansionExprSyntax {
        let tree = Parser.parse(source: source)
        return try #require(tree.statements.first?.item.as(MacroExpansionExprSyntax.self))
    }

    private struct SequenceGenerator: RandomNumberGenerator {
        let values: [UInt64]
        var calls = 0

        mutating func next() -> UInt64 {
            defer { calls += 1 }
            return calls < values.count ? values[calls] : 42
        }
    }
}
#endif
