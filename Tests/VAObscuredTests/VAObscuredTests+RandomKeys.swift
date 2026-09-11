#if canImport(VAObscuredMacros)
import Testing
@testable import VAObscuredMacros

struct VAObscuredRandomKeyTests {
    @Test(arguments: [UInt8(1), 42, 255])
    func unshiftedKeysSkipZero(value: UInt8) {
        var generator = KeyGenerator(values: [0, 0, UInt64(value)])
        let key = ObscuredMacro.generateKey(isAdding: nil, using: &generator)
        #expect(key == value)
        #expect(generator.calls == 3)
    }

    @Test(arguments: [true, false])
    func shiftedKeysCanUseZero(isAdding: Bool) {
        var generator = KeyGenerator(values: [0])
        #expect(ObscuredMacro.generateKey(isAdding: isAdding, using: &generator) == 0)
        #expect(generator.calls == 1)
    }

    @Test
    func everyUnshiftedKeyIsNonzero() {
        var generator = KeyGenerator(values: [0, 1, 0, 42, 0, 255])
        let keys = (0..<3).map { _ in ObscuredMacro.generateKey(isAdding: nil, using: &generator) }
        #expect(keys == [1, 42, 255])
        #expect(generator.calls == 6)
    }

    private struct KeyGenerator: RandomNumberGenerator {
        let values: [UInt64]
        var calls = 0

        mutating func next() -> UInt64 {
            defer { calls += 1 }
            return calls < values.count ? values[calls] : 42
        }
    }
}
#endif
