import VAObscured
import Foundation

let string = "String"

assert(string == #Obscured("String"))
assert(string == #Obscured("String", encoding: .xor(keyShift: .none)))
assert(string == #Obscured("String", encoding: .xor(keyShift: .addition)))
assert(string == #Obscured("String", encoding: .xor(keyShift: .substraction)))
assert(string == #Obscured("String", encoding: .xor(keysCount: 1)))
assert(string == #Obscured("String", encoding: .xor(keysCount: 1, keyShift: .none)))
assert(string == #Obscured("String", encoding: .xor(keysCount: 1, keyShift: .addition)))
assert(string == #Obscured("String", encoding: .xor(keysCount: 1, keyShift: .substraction)))
assert(string == #Obscured("String", encoding: .xor(keysCount: 10)))
assert(string == #Obscured("String", encoding: .xor(keysCount: 10, keyShift: .none)))
assert(string == #Obscured("String", encoding: .xor(keysCount: 10, keyShift: .addition)))
assert(string == #Obscured("String", encoding: .xor(keysCount: 10, keyShift: .substraction)))

