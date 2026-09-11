#if canImport(VAObscuredMacros)
import Foundation
import Testing
import VAObscured
import VAObscuredMacros

struct VAObscuredBoundaryTests {
    // Distinct fixed keys reveal errors that identical mock keys cannot expose.
    private let keys: [UInt8] = [1, 42, 255, 128]

    @Test(arguments: [
        (nil as Bool?, [UInt8(49), 27, 205, 179, 53, 31, 201, 183, 57, 19]),
        (true as Bool?, [UInt8(49), 26, 51, 176, 49, 26, 51, 176, 49, 10]),
        (false as Bool?, [UInt8(49), 24, 207, 78, 201, 16, 207, 78, 193, 24]),
    ])
    func cyclesDistinctKeys(isAdding: Bool?, expected: [UInt8]) {
        let plaintext = Data("0123456789".utf8)
        let encoded = ObscuredMacro.xor(data: plaintext, keys: keys, isAdding: isAdding)
        #expect(Array(encoded) == expected)
        #expect(ObscuredMacro.xor(data: encoded, keys: keys, isAdding: isAdding) == plaintext)
    }

    // The current format resets the shift at index 255 (UInt8.max), not 256.
    // Fixed vectors check the encoding itself, rather than only its inverse.
    @Test(arguments: [
        (nil as Bool?, [UInt8(42), 42, 42, 42, 42]),
        (true as Bool?, [UInt8(38), 39, 40, 42, 43]),
        (false as Bool?, [UInt8(46), 45, 44, 42, 41]),
    ], [254, 255, 256, 257])
    func singleKeyShiftBoundary(vector: (Bool?, [UInt8]), length: Int) {
        let (isAdding, expected) = vector
        let plaintext = Data(repeating: 0, count: length)
        let encoded = ObscuredMacro.xor(data: plaintext, key: 42, isAdding: isAdding)
        #expect(encoded.count == length)
        #expect(Array(encoded.dropFirst(252)) == Array(expected.prefix(length - 252)))
        #expect(ObscuredMacro.xor(data: encoded, key: 42, isAdding: isAdding) == plaintext)
    }

    @Test(arguments: [
        (nil as Bool?, [UInt8(1), 42, 255, 128, 1]),
        (true as Bool?, [UInt8(253), 39, 253, 128, 2]),
        (false as Bool?, [UInt8(5), 45, 1, 128, 0]),
    ], [254, 255, 256, 257])
    func multipleKeyShiftBoundary(vector: (Bool?, [UInt8]), length: Int) {
        let (isAdding, expected) = vector
        let plaintext = Data(repeating: 0, count: length)
        let encoded = ObscuredMacro.xor(data: plaintext, keys: keys, isAdding: isAdding)
        #expect(encoded.count == length)
        #expect(Array(encoded.dropFirst(252)) == Array(expected.prefix(length - 252)))
        #expect(ObscuredMacro.xor(data: encoded, keys: keys, isAdding: isAdding) == plaintext)
    }

    @Test(arguments: [nil as Bool?, true, false])
    func emptyBytesRemainEmpty(isAdding: Bool?) {
        #expect(ObscuredMacro.xor(data: Data(), key: 42, isAdding: isAdding).isEmpty)
        #expect(ObscuredMacro.xor(data: Data(), keys: keys, isAdding: isAdding).isEmpty)
    }

    @Test
    func generatedDecoderCrossesMultibyteBoundary() {
        let expected = String(repeating: "A", count: 252) + "😀Z"
        #expect(expected.utf8.count == 257)
        let actual = [
            #Obscured("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA😀Z"),
            #Obscured("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA😀Z", encoding: .xor(keyShift: .addition)),
            #Obscured("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA😀Z", encoding: .xor(keyShift: .substraction)),
            #Obscured("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA😀Z", encoding: .xor(keysCount: 4)),
            #Obscured("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA😀Z", encoding: .xor(keysCount: 4, keyShift: .addition)),
            #Obscured("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA😀Z", encoding: .xor(keysCount: 4, keyShift: .substraction)),
        ]
        #expect(actual == Array(repeating: expected, count: 6))
    }
}
#endif
