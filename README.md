# VAObscured


[![StandWithUkraine](https://raw.githubusercontent.com/vshymanskyy/StandWithUkraine/main/badges/StandWithUkraine.svg)](https://github.com/vshymanskyy/StandWithUkraine/blob/main/docs/README.md)
[![Support Ukraine](https://img.shields.io/badge/Support-Ukraine-FFD500?style=flat&labelColor=005BBB)](https://opensource.fb.com/support-ukraine)


[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://www.swift.org)
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-brightgreen.svg)](https://www.swift.org/documentation/package-manager/)
[![Tests](https://github.com/VAndrJ/VAObscured/actions/workflows/tests.yml/badge.svg)](https://github.com/VAndrJ/VAObscured/actions/workflows/tests.yml)


A Swift macro that makes string literals a little harder to find in a compiled app.


```swift
import VAObscured

let message = #Obscured("Hello, world!")
print(message) // Hello, world!
```

`#Obscured` replaces a string literal with encoded bytes and a small decoder at compile time. At runtime, the expression returns an ordinary Swift `String`.

**This is reversible obfuscation, not encryption.** The executable contains the keys and decoding logic, and the decoded string exists in memory. Use it to make casual string searches less useful.

## Installation

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/VAndrJ/VAObscured.git", from: "2.0.0")
]
```

Then add the library product to the target that uses the macro:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "VAObscured", package: "VAObscured")
    ]
)
```


### Xcode

Add [the repository](https://github.com/VAndrJ/VAObscured) as a package dependency, and add the **VAObscured** product to your app target.

## Compatibility

### Toolchains

| Toolchain | Support in this checkout |
| --- | --- |
| Swift 5.9 | Declared minimum for the package |
| Xcode 16.2 | Configured in CI for tests |
| Xcode 26.3 | Configured in CI for tests |

The package declares Swift tools version **5.9** and a SwiftSyntax dependency in the **509.x** series.

### Deployment targets

| Platform | Minimum version |
| --- | --- |
| iOS | 15 |
| macOS | 12 |
| tvOS | 15 |
| watchOS | 8 |
| Mac Catalyst | 15 |

## Usage

Start with the default:

```swift
let message = #Obscured("Welcome back")
```

Choose multiple keys or a key shift when you want a different encoding pattern:

```swift
let title = #Obscured("Welcome back", encoding: .xor(keysCount: 4))
let subtitle = #Obscured("Good to see you", encoding: .xor(keyShift: .addition))
let footer = #Obscured(
    "See you soon",
    encoding: .xor(keysCount: 4, keyShift: .subtraction)
)
```

### Parameters

| Parameter | Default | Accepted values |
| --- | --- | --- |
| First, unlabeled argument | Required | A string literal without interpolation |
| `encoding` | `.xor()` | `.xor`, `.xor()`, or `.xor(keysCount: ..., keyShift: ...)` |
| `keysCount` | `1` | An integer literal in `1...1024` |
| `keyShift` | `.none` | `.none`, `.addition`, or `.subtraction` |

Both XOR arguments are optional.

`keysCount` accepts decimal, hexadecimal, octal, and binary literals, including digit separators: `4`, `0x04`, `0o4`, `0b100`, and `1_024` are all valid. Zero, negative numbers, values above `1024`, variables, and arithmetic expressions produce a compile-time diagnostic.

Qualified members are also supported:

```swift
let message = #Obscured(
    "Welcome back",
    encoding: ObscuredEncoding.xor(
        keysCount: 4,
        keyShift: ObscuredEncoding.KeyShift.addition
    )
)
```


### Choosing a key count

- **Start with `1`.** It produces the simplest decoder and uses one random byte key for the entire string.
- **Use a small count, such as `4`, for a repeating sequence.** Each UTF-8 byte uses the next key, cycling back to the first when needed. Generated key values can repeat.
- **Avoid large counts without a reason.** The macro emits every requested key. A count larger than the string's UTF-8 byte length leaves some keys unused while adding generated source and compilation work. More keys do not turn XOR into encryption.

The shift mode is independent of the key count:

| Mode | How it changes the selected key |
| --- | --- |
| `.none` | Uses the key unchanged |
| `.addition` | Adds the byte-index offset with wrapping arithmetic |
| `.subtraction` | Subtracts the byte-index offset with wrapping arithmetic |

The offset is `index % 255`: it resets at byte index 255. This operates on **UTF-8 bytes**, not characters. In `.none` mode, generated keys are always nonzero. Shifted modes allow zero base keys, and an effective key can be zero at some positions, leaving those bytes unchanged.

### Supported strings

Empty strings, Unicode, escapes, raw literals, and multiline literals are supported:

```swift
let empty = #Obscured("")
let greeting = #Obscured("Hello, 🌍!")
let escaped = #Obscured("First line\n\"Second line\"")
let raw = #Obscured(#"A literal \n stays as written"#)
let multiline = #Obscured("""
    First line
    Second line
    """)
```

Variables and interpolation are not supported, even when their values seem obvious:

```swift
// These do not compile:
let source = "Hello"
let fromVariable = #Obscured(source)
let fromInterpolation = #Obscured("Hello, \(name)")
let fromExpression = #Obscured("Hello", encoding: .xor(keysCount: 2 + 2))
```

If you need dynamic content, combine it with the decoded value afterward:

```swift
let name = "Sam"
let greeting = #Obscured("Hello, ") + name
```

Only the literal passed to the macro is obscured.

## What happens at build time and runtime?

During macro expansion, VAObscured reads the literal's UTF-8 bytes, generates random keys, and emits encoded bytes plus a decoding closure. Keys are randomized **during expansion**, not every time the app reads the string. Fresh expansions can produce different encoded output for the same source; incremental builds may reuse previously compiled output.

For example, `#Obscured("test")` with a generated key of `42` expands to code like this:

```swift
{
    let data: [Swift.UInt8] = [94, 79, 89, 94]
    var result: [Swift.UInt8] = []
    for byte in data {
        result.append(byte ^ 42)
    }
    return Swift.String(decoding: result, as: Swift.UTF8.self)
}()
```

Each evaluation of the generated expression performs decoding again; the macro does not add a cache.
Compiler optimizations may change the final machine code.

## Development and verification

From a checkout, using a full Xcode toolchain:

```sh
swift test
swift run VAObscuredClient
```

The tests cover macro expansions and diagnostics, literal handling, Unicode, all six single-key/multiple-key and shift combinations, shift boundaries, random-generator isolation, and consumers that shadow standard-library names.

To check an optimized executable:

```sh
python3 Scripts/check-optimized-binary.py
```

The script builds and runs a release consumer, checks all six decoding modes, and scans its executable for complete plaintext probes in UTF-8 and UTF-16. It also requires an ordinary plaintext control to be present so a failed scan cannot silently look successful. Build failures, incorrect output, a missing control, or a discoverable probe fail the check.

Pass additional SwiftPM options after `--`:

```sh
python3 Scripts/check-optimized-binary.py -- --scratch-path /tmp/obscured-check
```

A pass describes **that build only**. It does not rule out plaintext fragments, debug information, runtime inspection, or recovery using the embedded keys. The binary scan is a separate check; the current CI workflow builds the release example but does not run this scanner.

## Author and license

Created by [Volodymyr Andriienko](https://github.com/VAndrJ) · [vandrjios@gmail.com](mailto:vandrjios@gmail.com)

Available under the [MIT license](LICENSE).


