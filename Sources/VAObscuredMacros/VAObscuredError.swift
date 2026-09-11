//
//  VAObscuredError.swift
//  VAObscured
//
//  Created by VAndrJ on 14.07.2024.
//

import SwiftDiagnostics
import SwiftSyntax

public enum VAObscuredError: Error, CustomStringConvertible, DiagnosticMessage {
    case notStringLiteral
    case interpolationNotSupported
    case invalidKeysCount
    case failedToGetData
    case obscuredIsNotValid
    case unhandled

    public var description: String {
        switch self {
        case .notStringLiteral: "Should be a String literal, not a variable or expression."
        case .interpolationNotSupported: "String interpolation is not supported. Use a String literal without interpolation."
        case .invalidKeysCount: "keysCount must be an integer literal between \(Arguments.supportedKeysCount.lowerBound) and \(Arguments.supportedKeysCount.upperBound)."
        case .failedToGetData: "Failed to get `.utf8` Data from String literal."
        case .obscuredIsNotValid: "Obscured string is not valid."
        case .unhandled: "Unhandled error."
        }
    }

    public var message: String { description }
    public var diagnosticID: MessageID { .init(domain: "ObscuredMacro", id: .init(describing: self)) }
    public var severity: DiagnosticSeverity { .error }

    public func getDiagnostic(
        node: some SyntaxProtocol,
        position: AbsolutePosition? = nil,
        highlights: [Syntax]? = nil,
        notes: [Note] = [],
        fixIts: [FixIt] = []
    ) -> Diagnostic {
        .init(
            node: node,
            position: position,
            message: self,
            highlights: highlights,
            notes: notes,
            fixIts: fixIts
        )
    }
}

struct ArgumentError: Error {
    let error: VAObscuredError
    let node: ExprSyntax
}
