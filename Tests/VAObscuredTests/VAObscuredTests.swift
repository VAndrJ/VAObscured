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

    func test_ObscuredMacro_Variable_Failure() throws {
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

    func test_ObscuredMacro_XOR_ExplicitDefaultEncoding_Success() throws {
        assertMacroExpansion(
        """
        let string = #Obscured("test", encoding: .xor())
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

    func test_ObscuredMacro_XOR_ExplicitDefaultEncodingConstant_Success() throws {
        assertMacroExpansion(
        """
        let string = #Obscured("test", encoding: .xor)
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

    func test_ObscuredMacro_XOR_ExplicitKeys_Success() throws {
        assertMacroExpansion(
            """
            let string = #Obscured("test", encoding: .xor(keysCount: 1, keyShift: .none))
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

    func test_ObscuredMacro_XOR_ExplicitCountKeys_Success() throws {
        assertMacroExpansion(
            """
            let string = #Obscured("test", encoding: .xor(keysCount: 1))
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

    func test_ObscuredMacro_XOR_ExplicitShiftKeysAddition_Success() throws {
        assertMacroExpansion(
            """
            let string = #Obscured("test", encoding: .xor(keysCount: 1, keyShift: .addition))
            """,
            expandedSource: """
            let string = {
                let data = Data([94, 78, 95, 89])
            
                var result = Data()
                let max = Int(UInt8.max)
                for (index, byte) in zip(data.indices, data) {
                    result.append(byte ^ (42 &+ UInt8(index % max)))
                }
                return String(bytes: result, encoding: .utf8)!
            }()
            """,
            macros: testMacros
        )
    }

    func test_ObscuredMacro_XOR_ExplicitShiftKeysSubstraction_Success() throws {
        assertMacroExpansion(
            """
            let string = #Obscured("test", encoding: .xor(keysCount: 1, keyShift: .substraction))
            """,
            expandedSource: """
            let string = {
                let data = Data([94, 76, 91, 83])
            
                var result = Data()
                let max = Int(UInt8.max)
                for (index, byte) in zip(data.indices, data) {
                    result.append(byte ^ (42 &- UInt8(index % max)))
                }
                return String(bytes: result, encoding: .utf8)!
            }()
            """,
            macros: testMacros
        )
    }

    func test_ObscuredMacro_XOR_MultipleKeysCount_Success() throws {
        assertMacroExpansion(
            """
            let string = #Obscured("test", encoding: .xor(keysCount: 4))
            """,
            expandedSource: """
            let string = {
                let data = Data([94, 79, 89, 94])
            
                var result = Data()
            
                let keys: [UInt8] = [42, 42, 42, 42]
                for (index, byte) in zip(data.indices, data) {
                    let key = keys[index % keys.count]
                    result.append(byte ^ key)
                }
                return String(bytes: result, encoding: .utf8)!
            }()
            """,
            macros: testMacros
        )
    }

    func test_ObscuredMacro_XOR_MultipleKeysCountAddition_Success() throws {
        assertMacroExpansion(
            """
            let string = #Obscured("test", encoding: .xor(keysCount: 4, keyShift: .addition))
            """,
            expandedSource: """
            let string = {
                let data = Data([94, 78, 95, 89])
            
                var result = Data()
                let max = Int(UInt8.max)
                let keys: [UInt8] = [42, 42, 42, 42]
                for (index, byte) in zip(data.indices, data) {
                    let key = keys[index % keys.count]
                    result.append(byte ^ (key &+ UInt8(index % max)))
                }
                return String(bytes: result, encoding: .utf8)!
            }()
            """,
            macros: testMacros
        )
    }

    func test_ObscuredMacro_XOR_MultipleKeysCountSubstraction_Success() throws {
        assertMacroExpansion(
            """
            let string = #Obscured("test", encoding: .xor(keysCount: 4, keyShift: .substraction))
            """,
            expandedSource: """
            let string = {
                let data = Data([94, 76, 91, 83])
            
                var result = Data()
                let max = Int(UInt8.max)
                let keys: [UInt8] = [42, 42, 42, 42]
                for (index, byte) in zip(data.indices, data) {
                    let key = keys[index % keys.count]
                    result.append(byte ^ (key &- UInt8(index % max)))
                }
                return String(bytes: result, encoding: .utf8)!
            }()
            """,
            macros: testMacros
        )
    }
}
#endif
