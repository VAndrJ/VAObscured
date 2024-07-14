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
