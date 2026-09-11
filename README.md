# VAObscured


[![StandWithUkraine](https://raw.githubusercontent.com/vshymanskyy/StandWithUkraine/main/badges/StandWithUkraine.svg)](https://github.com/vshymanskyy/StandWithUkraine/blob/main/docs/README.md)
[![Support Ukraine](https://img.shields.io/badge/Support-Ukraine-FFD500?style=flat&labelColor=005BBB)](https://opensource.fb.com/support-ukraine)


[![Language](https://img.shields.io/badge/language-Swift%205.9-orangered.svg?style=flat)](https://www.swift.org)
[![SPM](https://img.shields.io/badge/SPM-compatible-limegreen.svg?style=flat)](https://github.com/apple/swift-package-manager)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20macOS%20%7C%20macCatalyst-lightgray.svg?style=flat)](https://developer.apple.com/discover)


### @Obscured


Encodes String literals to make them a little harder to find.

Use `import VAObscured` to access the macro. Generated code uses Swift byte arrays and
UTF-8 decoding, so consumers do not need to import Foundation.

This is reversible obfuscation: the encoded bytes, keys, and decoding logic are embedded
in the executable, and the decoded string exists in memory at runtime. It is not encryption
or a way to protect secrets. When `keyShift` is `.none` (the default), every generated key
is nonzero so XOR cannot leave a byte unchanged through a zero key. Shifted modes may use
zero base keys; their effective keys vary with the byte index.

Run `python3 Scripts/check-optimized-binary.py` to build a release consumer, verify that
all six encoding modes decode correctly, and scan the executable for complete plaintext
probes in UTF-8 and UTF-16. An ordinary plaintext control must also be found. The check
fails if a probe is discoverable or a control fails. It assesses that compiler/build only:
optimizations can change the output, and absence of a complete probe does not establish
resistance to reverse engineering or rule out plaintext fragments, debug files, or runtime inspection.
Additional SwiftPM options can follow `--`, such as `--scratch-path /tmp/obscured-check`.

`keysCount` defaults to `1` and must be an integer literal in `1...1024`.
Decimal, hexadecimal, octal, and binary literals (including digit separators) are supported.
Zero, negative values, values above `1024`, variables, and expressions produce a compile-time diagnostic.

`encoding` accepts `.xor`, `.xor()`, or `.xor(keysCount: ..., keyShift: ...)`, with either
argument optional. Each label may appear once, with `keysCount` before `keyShift` when both
are supplied. `keyShift` accepts `.none`, `.addition`, or `.subtraction`.
Encoding members may be qualified with `ObscuredEncoding` or `VAObscured.ObscuredEncoding`;
shift members may use the corresponding `KeyShift` type. Variables, type aliases, helper
calls, and other expressions are not evaluated by the macro and are diagnosed instead.


Example 1:


```swift
let string = #Obscured("test")

// expands to

let string = {
    let data: [Swift.UInt8] = [94, 79, 89, 94]

    var result: [Swift.UInt8] = []
    for byte in data {
        result.append(byte ^ 42) // 42 is a random number.
    }

    return Swift.String(decoding: result, as: Swift.UTF8.self)
}()
```


Example 2:


```swift
let string = #Obscured("test", encoding: .xor(keysCount: 4, keyShift: .addition))

// expands to

let string = {
    let data: [Swift.UInt8] = [94, 78, 95, 89]

    var result: [Swift.UInt8] = []
    let max = Swift.Int(Swift.UInt8.max)
    let keys: [Swift.UInt8] = [42, 42, 42, 42] // Random numbers here.
    for (index, byte) in Swift.zip(data.indices, data) {
        let key = keys[index % keys.count]
        result.append(byte ^ (key &+ Swift.UInt8(index % max)))
    }
    return Swift.String(decoding: result, as: Swift.UTF8.self)
}()
```


## Author


Volodymyr Andriienko, vandrjios@gmail.com


## License


VAObscured is available under the MIT license. See the LICENSE file for more info.
