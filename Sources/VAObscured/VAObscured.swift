// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that produces obscured data to get String.
@freestanding(expression)
public macro Obscured(
    _ string: String,
    encoding: ObscuredEncoding = .xor()
) -> String = #externalMacro(module: "VAObscuredMacros", type: "ObscuredMacro")

public enum ObscuredEncoding {
    public enum KeyShift: Equatable, CaseIterable {
        case addition
        case substraction
        case none
    }

    /// When used with `#Obscured`, `keysCount` must be an integer literal in `1...1024`.
    case xor(keysCount: Int = 1, keyShift: KeyShift = .none)

    public static let xor: ObscuredEncoding = .xor(keysCount: 1, keyShift: .none)
}
