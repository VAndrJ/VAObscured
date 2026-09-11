import Testing
import VAObscuredConsumer

struct VAObscuredConsumerTests {
    @Test
    func decodesWithShadowedStandardLibraryNames() {
        let strings = decodedShadowingConsumerStrings()
        #expect(strings.count == 12)
        for (actual, expected) in strings {
            #expect(actual == expected)
        }
    }

    @Test
    func decodesWithOnlyLibraryImported() {
        let strings = decodedConsumerStrings()
        #expect(strings.count == 12)
        for (actual, expected) in strings {
            #expect(actual == expected)
        }
    }
}
