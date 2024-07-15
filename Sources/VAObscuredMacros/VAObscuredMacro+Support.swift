//
//  VAObscuredMacro+Support.swift
//  VAObscured
//
//  Created by VAndrJ on 14.07.2024.
//

import SwiftSyntax

struct Arguments {
    let string: String
    let encoding: String
    let keysCount: Int
    let isAdding: Bool?
}

extension LabeledExprListSyntax {
    var arguments: Arguments {
        get throws {
            guard let string = first?.expression.as(StringLiteralExprSyntax.self)?.segments.first?.as(StringSegmentSyntax.self)?.content.text else {
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
                                    if argument.label?.text == "keysCount", let count = argument.expression.as(IntegerLiteralExprSyntax.self)?.literal.text, let keys = Int(count), keys != 1 {
                                        keysCount = keys
                                    }
                                    if argument.label?.text == "keyShift", let value = argument.expression.as(MemberAccessExprSyntax.self)?.declName.baseName.text {
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

extension String {
    static let xor = "xor"
}
