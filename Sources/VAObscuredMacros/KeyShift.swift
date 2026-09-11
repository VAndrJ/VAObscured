enum KeyShift: String, CaseIterable, Sendable {
    case none
    case addition
    case subtraction

    func apply(to key: UInt8, at index: Int) -> UInt8 {
        // Preserve the existing shift period of 255 bytes.
        switch self {
        case .none: key
        case .addition: key &+ UInt8(index % Int(UInt8.max))
        case .subtraction: key &- UInt8(index % Int(UInt8.max))
        }
    }

    func expression(for key: String) -> String {
        switch self {
        case .none: key
        case .addition: "(\(key) &+ Swift.UInt8(index % max))"
        case .subtraction: "(\(key) &- Swift.UInt8(index % max))"
        }
    }
}
