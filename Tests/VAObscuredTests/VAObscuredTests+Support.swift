//
//  VAObscuredTests+Support.swift
//  VAObscured
//
//  Created by VAndrJ on 14.07.2024.
//

import Foundation

struct MockGenerator: RandomNumberGenerator {
    var key: UInt64 = 42

    func next() -> UInt64 {
        key
    }
}

#if canImport(VAObscuredMacros)
import SwiftSyntax
import SwiftSyntaxMacros
@testable import VAObscuredMacros

struct DeterministicObscuredMacro: ExpressionMacro {
    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        var generator = MockGenerator()
        return ObscuredMacro.expansion(of: node, in: context, using: &generator)
    }
}
#endif
