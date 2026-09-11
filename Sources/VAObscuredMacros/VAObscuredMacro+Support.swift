//
//  VAObscuredMacro+Support.swift
//  VAObscured
//
//  Created by VAndrJ on 14.07.2024.
//

import SwiftParser
import SwiftSyntax

struct Arguments {
    static let supportedKeysCount = 1...1024

    let string: String
    let encoding: String
    let keysCount: Int
    let isAdding: Bool?
}

extension LabeledExprListSyntax {
    var arguments: Arguments {
        get throws {
            guard let literal = first?.expression.as(StringLiteralExprSyntax.self) else {
                throw VAObscuredError.notStringLiteral
            }
            guard !literal.segments.contains(where: { $0.is(ExpressionSegmentSyntax.self) }) else {
                throw VAObscuredError.interpolationNotSupported
            }
            guard let string = literal.representedLiteralValue else {
                throw VAObscuredError.notStringLiteral
            }

            let encoding: String = .xor
            var keysCount = 1
            var isAdding: Bool? = nil

            for expr in self.dropFirst() {
                if let labeledExpr = expr.as(LabeledExprSyntax.self) {
                    if labeledExpr.label?.text == "encoding" {
                        if labeledExpr.expression.description.contains("xor") {
                            if let arguments = labeledExpr.expression.as(FunctionCallExprSyntax.self)?.arguments {
                                for argument in arguments {
                                    if argument.label?.text == "keysCount" {
                                        keysCount = try parseKeysCount(argument.expression)
                                    }
                                    if argument.label?.text == "keyShift",
                                        let value = argument.expression.as(MemberAccessExprSyntax.self)?.declName.baseName.text
                                    {
                                        switch value {
                                        case "addition": isAdding = true
                                        case "substraction": isAdding = false
                                        default: break
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            return .init(
                string: string,
                encoding: encoding,
                keysCount: keysCount,
                isAdding: isAdding
            )
        }
    }
}

private func parseKeysCount(_ expression: ExprSyntax) throws -> Int {
    guard let literal = expression.as(IntegerLiteralExprSyntax.self) else {
        throw ArgumentError(error: .invalidKeysCount, node: expression)
    }

    var digits = literal.literal.text.filter { $0 != "_" }
    let radix: Int
    if digits.hasPrefix("0x") {
        radix = 16
        digits.removeFirst(2)
    } else if digits.hasPrefix("0o") {
        radix = 8
        digits.removeFirst(2)
    } else if digits.hasPrefix("0b") {
        radix = 2
        digits.removeFirst(2)
    } else {
        radix = 10
    }
    guard let count = Int(digits, radix: radix), Arguments.supportedKeysCount.contains(count) else {
        throw ArgumentError(error: .invalidKeysCount, node: expression)
    }

    return count
}

extension String {
    static let xor = "xor"
}
