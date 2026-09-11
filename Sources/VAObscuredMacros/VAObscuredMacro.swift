import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ObscuredMacro: ExpressionMacro {
    static func generateKey(isAdding: Bool?, using generator: inout some RandomNumberGenerator) -> UInt8 {
        var key: UInt8
        repeat {
            key = .random(in: .min...UInt8.max, using: &generator)
        } while isAdding == nil && key == 0
        return key
    }

    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        var generator = SystemRandomNumberGenerator()
        return expansion(of: node, in: context, using: &generator)
    }

    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext,
        using generator: inout some RandomNumberGenerator
    ) -> ExprSyntax {
        do {
            if let closure = node.trailingClosure {
                throw ArgumentError(error: .invalidMacroArguments, node: ExprSyntax(closure))
            }
            let arguments = try node.argumentList.arguments
            guard let data = arguments.string.data(using: .utf8) else {
                let error = VAObscuredError.failedToGetData
                context.diagnose(error.getDiagnostic(node: node))

                return #""""#
            }

            return try ExprSyntax(
                FunctionCallExprSyntax(
                    calledExpression: ClosureExprSyntax(
                        statements: CodeBlockItemListSyntax(itemsBuilder: {
                            try getXORCodeBlockItemListSyntax(
                                data: data,
                                keysCount: arguments.keysCount,
                                isAdding: arguments.isAdding,
                                using: &generator
                            )
                            ReturnStmtSyntax(expression: ExprSyntax("String(decoding: result, as: UTF8.self)"))
                        })
                    ),
                    leftParen: .leftParenToken(),
                    arguments: LabeledExprListSyntax(),
                    rightParen: .rightParenToken()
                )
            )
        } catch {
            if let error = error as? ArgumentError {
                context.diagnose(error.error.getDiagnostic(node: error.node))
            } else if let error = error as? VAObscuredError {
                context.diagnose(error.getDiagnostic(node: node))
            } else {
                context.diagnose(VAObscuredError.unhandled.getDiagnostic(node: node))
            }

            return #""""#
        }
    }

    static func getXORCodeBlockItemListSyntax(data: Data, keysCount: Int, isAdding: Bool?, using generator: inout some RandomNumberGenerator) throws -> CodeBlockItemListSyntax {
        if keysCount == 1 {
            return try getXORCodeBlockItemListSyntax(data: data, isAdding: isAdding, using: &generator)
        } else {
            return try getXORMultipleKeysCodeBlockItemListSyntax(data: data, keysCount: keysCount, isAdding: isAdding, using: &generator)
        }
    }

    static func getXORMultipleKeysCodeBlockItemListSyntax(data: Data, keysCount: Int, isAdding: Bool?, using generator: inout some RandomNumberGenerator) throws -> CodeBlockItemListSyntax {
        guard Arguments.supportedKeysCount.contains(keysCount) else {
            throw VAObscuredError.invalidKeysCount
        }
        let keys: [UInt8] = (0..<keysCount).map { _ in generateKey(isAdding: isAdding, using: &generator) }
        let xorData: [UInt8] = Array(xor(data: data, keys: keys, isAdding: isAdding))

        guard getIsXORValid(result: xorData, keys: keys, isAdding: isAdding) else {
            throw VAObscuredError.obscuredIsNotValid
        }

        return CodeBlockItemListSyntax(
            """

                let data: [UInt8] = \(raw: xorData)

                var result: [UInt8] = []
                \(raw: (isAdding == nil ? "" : "let max = Int(UInt8.max)"))
                let keys: [UInt8] = \(raw: keys)
                for (index, byte) in zip(data.indices, data) {
                    let key = keys[index % keys.count]
                    result.append(byte ^ \(raw: (isAdding == true ? "(key &+ UInt8(index % max))" : isAdding == false ? "(key &- UInt8(index % max))" : "key")))
                }
            """
        )
    }

    static func getXORCodeBlockItemListSyntax(data: Data, isAdding: Bool?, using generator: inout some RandomNumberGenerator) throws -> CodeBlockItemListSyntax {
        let key = generateKey(isAdding: isAdding, using: &generator)
        let xorData: [UInt8] = Array(xor(data: data, key: key, isAdding: isAdding))

        guard getIsXORValid(result: xorData, key: key, isAdding: isAdding) else {
            throw VAObscuredError.obscuredIsNotValid
        }

        return CodeBlockItemListSyntax(
            """

                let data: [UInt8] = \(raw: xorData)

                var result: [UInt8] = []
                \(raw: (isAdding == nil ? "" : "let max = Int(UInt8.max)"))
                for \(raw: (isAdding == nil ? "byte in data" : "(index, byte) in zip(data.indices, data)")) {
                    result.append(byte ^ \(raw: (isAdding == true ? "(\(key) &+ UInt8(index % max))" : isAdding == false ? "(\(key) &- UInt8(index % max))" : "\(key)")))
                }
            """
        )
    }

    public static func getIsXORValid(result: [UInt8], key: UInt8, isAdding: Bool?) -> Bool {
        String(bytes: xor(data: Data(result), key: key, isAdding: isAdding), encoding: .utf8) != nil
    }

    public static func xor(data: Data, key: UInt8, isAdding: Bool?) -> Data {
        var result = Data()
        switch isAdding {
        case let .some(isAdding):
            let max = Int(UInt8.max)
            if isAdding {
                for (index, byte) in zip(data.indices, data) {
                    result.append(byte ^ (key &+ UInt8(index % max)))
                }
            } else {
                for (index, byte) in zip(data.indices, data) {
                    result.append(byte ^ (key &- UInt8(index % max)))
                }
            }
        case .none:
            for byte in data {
                result.append(byte ^ key)
            }
        }

        return result
    }

    public static func getIsXORValid(result: [UInt8], keys: [UInt8], isAdding: Bool?) -> Bool {
        String(bytes: xor(data: Data(result), keys: keys, isAdding: isAdding), encoding: .utf8) != nil
    }

    public static func xor(data: Data, keys: [UInt8], isAdding: Bool?) -> Data {
        var result = Data()
        switch isAdding {
        case let .some(isAdding):
            let max = Int(UInt8.max)
            if isAdding {
                for (index, byte) in zip(data.indices, data) {
                    let key = keys[index % keys.count]
                    result.append(byte ^ (key &+ UInt8(index % max)))
                }
            } else {
                for (index, byte) in zip(data.indices, data) {
                    let key = keys[index % keys.count]
                    result.append(byte ^ (key &- UInt8(index % max)))
                }
            }
        case .none:
            for (index, byte) in zip(data.indices, data) {
                let key = keys[index % keys.count]
                result.append(byte ^ key)
            }
        }

        return result
    }
}

@main
struct VAObscuredPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ObscuredMacro.self
    ]
}
