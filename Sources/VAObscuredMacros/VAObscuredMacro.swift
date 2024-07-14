import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation

public struct ObscuredMacro: ExpressionMacro {
    public static var generator: RandomNumberGenerator = SystemRandomNumberGenerator()

    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.argumentList.first?.expression else {
            let error = VAObscuredError.noArguments
            context.diagnose(error.getDiagnostic(node: node))

            return #""""#
        }
        guard let string = argument.as(StringLiteralExprSyntax.self)?.segments.first?.as(StringSegmentSyntax.self)?.content.text else {
            let error = VAObscuredError.notStringLiteral
            context.diagnose(error.getDiagnostic(node: node))

            return #""""#
        }
        guard let data = string.data(using: .utf8) else {
            let error = VAObscuredError.failedToGetData
            context.diagnose(error.getDiagnostic(node: node))

            return #""""#
        }

        let key: UInt8 = .random(in: .min...UInt8.max, using: &generator)
        let xorData: [UInt8] = Array(xor(data: data, key: key))

        guard getIsXORValid(result: xorData, key: key) else {
            let error = VAObscuredError.obscuredIsNotValid
            context.diagnose(error.getDiagnostic(node: node))

            return #""""#
        }

        return ExprSyntax(
            FunctionCallExprSyntax(
                calledExpression: ClosureExprSyntax(
                    statements: CodeBlockItemListSyntax(
                        itemsBuilder: {
                            CodeBlockItemListSyntax("""
                            
                                let data = Data(\(raw: xorData))
                            
                                var result = Data()
                                for byte in data {
                                    result.append(byte ^ \(raw: key))
                                }
                            """)
                            ReturnStmtSyntax(
                                expression: ForceUnwrapExprSyntax(
                                    expression: FunctionCallExprSyntax(
                                        calledExpression: DeclReferenceExprSyntax(baseName: .identifier("String")),
                                        leftParen: .leftParenToken(),
                                        arguments: LabeledExprListSyntax {
                                            LabeledExprSyntax(
                                                label: "bytes",
                                                expression: DeclReferenceExprSyntax(baseName: .identifier("result"))
                                            )
                                            LabeledExprSyntax(
                                                label: "encoding",
                                                expression: MemberAccessExprSyntax(declName: DeclReferenceExprSyntax(baseName: .identifier("utf8")))
                                            )
                                        },
                                        rightParen: .rightParenToken()
                                    )
                                )
                            )
                        })
                ),
                leftParen: .leftParenToken(),
                arguments: LabeledExprListSyntax(),
                rightParen: .rightParenToken()
            )
        )
    }

    public static func getIsXORValid(result: [UInt8], key: UInt8) -> Bool {
        let data = Data(result)

        var result = Data()
        for byte in data {
            result.append(byte ^ key)
        }

        return String(bytes: result, encoding: .utf8) != nil
    }

    public static func xor(data: Data, key: UInt8) -> Data {
        var result = Data()
        for byte in data {
            result.append(byte ^ key)
        }

        return result
    }
}

@main
struct VAObscuredPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ObscuredMacro.self,
    ]
}
