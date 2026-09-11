//
//  VAObscuredTests+Helpers.swift
//  VAObscured
//
//  Created by VAndrJ on 14.07.2024.
//

#if canImport(VAObscuredMacros)
import XCTest
@testable import VAObscuredMacros

extension VAObscuredTests {

    func test_Obscured_XOR() throws {
        let expected = "Hello, World!"
        for keyShift in KeyShift.allCases {
            let xored = ObscuredMacro.xor(data: expected.data(using: .utf8)!, key: key, keyShift: keyShift)
            let deXored = ObscuredMacro.xor(data: xored, key: key, keyShift: keyShift)

            XCTAssertEqual(expected, String(data: deXored, encoding: .utf8))
        }
    }

    func test_Obscured_XOR_Validation() throws {
        let data: [UInt8] = [94, 79, 89, 94]

        XCTAssertTrue(ObscuredMacro.getIsXORValid(result: data, key: key, keyShift: .none))
    }

    func test_Obscured_XOR_Validation_Failed() throws {
        let data: [UInt8] = [0xD8, 0x00]

        XCTAssertFalse(ObscuredMacro.getIsXORValid(result: data, key: key, keyShift: .none))
    }
}
#endif
