import VAObscured
import Foundation

let string = "String"
let obscuredString = #Obscured("String")
assert(string == obscuredString)

