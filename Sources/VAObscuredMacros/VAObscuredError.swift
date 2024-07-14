//
//  VAObscuredError.swift
//  VAObscured
//
//  Created by VAndrJ on 14.07.2024.
//

import SwiftSyntax
import SwiftDiagnostics

public enum VAObscuredError: Error, CustomStringConvertible, DiagnosticMessage {
    case noArguments
    case notStringLiteral
    case failedToGetData
    case obscuredIsNotValid

    public var description: String {
        switch self {
        case .noArguments: "No arguments"
        case .notStringLiteral: "Should be a String literal, not a variable or expression"
        case .failedToGetData: "Failed to get `.utf8` Data from String literal"
        case .obscuredIsNotValid: "Obscured string is not valid."
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
        fixIt: FixIt
    ) -> Diagnostic {
        .init(
            node: node,
            position: position,
            message: self,
            highlights: highlights,
            notes: notes,
            fixIt: fixIt
        )
    }

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
