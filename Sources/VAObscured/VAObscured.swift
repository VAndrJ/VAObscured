// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that produces obscured data to get String.
@freestanding(expression)
public macro Obscured(_ string: String) -> String = #externalMacro(module: "VAObscuredMacros", type: "ObscuredMacro")
