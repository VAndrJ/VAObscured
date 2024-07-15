# VAObscured


[![StandWithUkraine](https://raw.githubusercontent.com/vshymanskyy/StandWithUkraine/main/badges/StandWithUkraine.svg)](https://github.com/vshymanskyy/StandWithUkraine/blob/main/docs/README.md)
[![Support Ukraine](https://img.shields.io/badge/Support-Ukraine-FFD500?style=flat&labelColor=005BBB)](https://opensource.fb.com/support-ukraine)


[![Language](https://img.shields.io/badge/language-Swift%205.9-orangered.svg?style=flat)](https://www.swift.org)
[![SPM](https://img.shields.io/badge/SPM-compatible-limegreen.svg?style=flat)](https://github.com/apple/swift-package-manager)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20macOS%20%7C%20macCatalyst-lightgray.svg?style=flat)](https://developer.apple.com/discover)


### @Obscured


Encodes String literals to make them a little harder to find.


Example 1:


```swift
let string = #Obscured("test")

// expands to

let string = {
    let data = Data([94, 79, 89, 94])

    var result = Data()
    for byte in data {
        result.append(byte ^ 42) // 42 is a random number.
    }

    return String(bytes: result, encoding: .utf8)!
}()
```


Example 2:


```swift
let string = #Obscured("test", encoding: .xor(keysCount: 4, keyShift: .addition))

// expands to

let string = {
    let data = Data([94, 78, 95, 89])

    var result = Data()
    let max = Int(UInt8.max)
    let keys: [UInt8] = [42, 42, 42, 42] // Random numbers here.
    for (index, byte) in zip(data.indices, data) {
        let key = keys[index % keys.count]
        result.append(byte ^ (key &+ UInt8(index % max)))
    }
    return String(bytes: result, encoding: .utf8)!
}()
```


## Author


Volodymyr Andriienko, vandrjios@gmail.com


## License


VAObscured is available under the MIT license. See the LICENSE file for more info.
