import VAObscured

// Each probe occurs only inside a macro. Printing keeps decoding observable under -O.
print(#Obscured("VAObscured_probe_default_53A7F219"))
print(#Obscured("VAObscured_probe_addition_6C82E130", encoding: .xor(keyShift: .addition)))
print(#Obscured("VAObscured_probe_subtraction_794DB520", encoding: .xor(keyShift: .subtraction)))
print(#Obscured("VAObscured_probe_multiple_8EF06341", encoding: .xor(keysCount: 4)))
print(#Obscured("VAObscured_probe_multi_add_90AB7425", encoding: .xor(keysCount: 4, keyShift: .addition)))
print(#Obscured("VAObscured_probe_multi_sub_A1BC8536", encoding: .xor(keysCount: 4, keyShift: .subtraction)))
// Positive control proves the scan can find an ordinary literal in this executable.
print("VAObscured_plaintext_control_B2CD9647")
