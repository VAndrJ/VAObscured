#if canImport(VAObscuredMacros)
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import VAObscuredMacros

let testMacros: [String: Macro.Type] = [
    "Obscured": ObscuredMacro.self,
]

final class VAObscuredTests: XCTestCase {
    let key: UInt8 = 42
    
    override class func setUp() {
        ObscuredMacro.generator = MockGenerator()
    }

    func test_ObscuredMacro_Success() throws {
        assertMacroExpansion(
            """
            let string = #Obscured("test")
            """,
            expandedSource: """
            let string = {
                let data = Data([94, 79, 89, 94])

                var result = Data()
                for byte in data {
                    result.append(byte ^ 42)
                }
                return String(bytes: result, encoding: .utf8)!
            }()
            """,
            macros: testMacros
        )
    }

    func test_ObscuredMacro_Failure_Variable() throws {
        assertMacroExpansion(
            """
            let string = "test"
            let obscuredString = #Obscured(string)
            """,
            expandedSource: """
            let string = "test"
            let obscuredString = ""
            """,
            diagnostics: [.init(message: VAObscuredError.notStringLiteral.description, line: 2, column: 22)],
            macros: testMacros
        )
    }
}
#endif
