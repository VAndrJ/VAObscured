import VAObscured

// Deliberately shadow every standard-library name referenced by generated decoders.
public func decodedShadowingConsumerStrings() -> [(actual: Swift.String, expected: Swift.String)] {
    enum String {}
    enum UInt8 {}
    enum Int {}
    enum UTF8 {}
    enum zip {}

    let expected = "Hello, 🌍!\n\"Swift\"\\\0"
    return [
        (#Obscured("Hello, 🌍!\n\"Swift\"\\\0"), expected),
        (#Obscured("Hello, 🌍!\n\"Swift\"\\\0", encoding: .xor(keyShift: .addition)), expected),
        (#Obscured("Hello, 🌍!\n\"Swift\"\\\0", encoding: .xor(keyShift: .subtraction)), expected),
        (#Obscured("Hello, 🌍!\n\"Swift\"\\\0", encoding: .xor(keysCount: 4)), expected),
        (#Obscured("Hello, 🌍!\n\"Swift\"\\\0", encoding: .xor(keysCount: 4, keyShift: .addition)), expected),
        (#Obscured("Hello, 🌍!\n\"Swift\"\\\0", encoding: .xor(keysCount: 4, keyShift: .subtraction)), expected),
        (#Obscured(""), ""),
        (#Obscured("", encoding: .xor(keyShift: .addition)), ""),
        (#Obscured("", encoding: .xor(keyShift: .subtraction)), ""),
        (#Obscured("", encoding: .xor(keysCount: 4)), ""),
        (#Obscured("", encoding: .xor(keysCount: 4, keyShift: .addition)), ""),
        (#Obscured("", encoding: .xor(keysCount: 4, keyShift: .subtraction)), ""),
    ]
}
