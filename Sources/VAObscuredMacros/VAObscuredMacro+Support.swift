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

            guard first?.label == nil else {
                throw ArgumentError(error: .invalidMacroArguments, node: first!.expression)
            }
            var keysCount = 1
            var isAdding: Bool? = nil
            for (index, argument) in dropFirst().enumerated() {
                guard index == 0, argument.label?.text == "encoding" else {
                    throw ArgumentError(error: .invalidMacroArguments, node: argument.expression)
                }
                (keysCount, isAdding) = try parseEncoding(argument.expression)
            }

            return .init(
                string: string,
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

private func parseEncoding(_ expression: ExprSyntax) throws -> (Int, Bool?) {
    let call = expression.as(FunctionCallExprSyntax.self)
    let memberExpression = call?.calledExpression ?? expression
    guard
        isMember(
            memberExpression,
            named: "xor",
            qualifiers: [
                ["ObscuredEncoding"], ["VAObscured", "ObscuredEncoding"],
            ]
        ), call?.trailingClosure == nil, call?.additionalTrailingClosures.isEmpty != false
    else {
        throw ArgumentError(error: .invalidEncoding, node: expression)
    }

    var keysCount = 1
    var isAdding: Bool? = nil
    var labels = Set<String>()
    for argument in call?.arguments ?? LabeledExprListSyntax() {
        guard let label = argument.label?.text,
            ["keysCount", "keyShift"].contains(label), labels.insert(label).inserted,
            !(label == "keysCount" && labels.contains("keyShift"))
        else {
            throw ArgumentError(error: .invalidEncodingArguments, node: argument.expression)
        }
        switch label {
        case "keysCount": keysCount = try parseKeysCount(argument.expression)
        default: isAdding = try parseKeyShift(argument.expression)
        }
    }
    return (keysCount, isAdding)
}

private func parseKeyShift(_ expression: ExprSyntax) throws -> Bool? {
    for (name, shift): (String, Bool?) in [("none", nil), ("addition", true), ("subtraction", false)] {
        if isMember(
            expression,
            named: name,
            qualifiers: [
                ["ObscuredEncoding", "KeyShift"], ["VAObscured", "ObscuredEncoding", "KeyShift"],
            ]
        ) {
            return shift
        }
    }
    throw ArgumentError(error: .invalidKeyShift, node: expression)
}

private func isMember(_ expression: ExprSyntax, named name: String, qualifiers: [[String]]) -> Bool {
    guard let member = expression.as(MemberAccessExprSyntax.self),
        member.declName.baseName.text == name, member.declName.argumentNames == nil
    else { return false }
    guard let base = member.base else { return true }
    guard let path = qualifiedName(base) else { return false }
    return qualifiers.contains(path)
}

private func qualifiedName(_ expression: ExprSyntax) -> [String]? {
    if let reference = expression.as(DeclReferenceExprSyntax.self), reference.argumentNames == nil {
        return [reference.baseName.text]
    }
    guard let member = expression.as(MemberAccessExprSyntax.self), member.declName.argumentNames == nil,
        let base = member.base, let path = qualifiedName(base)
    else { return nil }
    return path + [member.declName.baseName.text]
}
