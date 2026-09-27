import Foundation
import Testing
@testable import Goose

@Suite("String.addingQueryValueEncoding")
struct QueryValueEncodingTests {
    @Test("Reserved query characters are always escaped")
    func reserved() {
        #expect("a+b=c&d#e?f".addingQueryValueEncoding() == "a%2Bb%3Dc%26d%23e%3Ff")
        #expect("100% done".addingQueryValueEncoding() == "100%25%20done")
        #expect("line\nbreak".addingQueryValueEncoding() == "line%0Abreak")
    }

    @Test("Unreserved and safe characters are left alone")
    func unreserved() {
        let safe = "AZaz09-._~/:@!$'()*,;"
        #expect(safe.addingQueryValueEncoding() == safe)
        #expect("".addingQueryValueEncoding() == "")
    }

    @Test("Values round-trip through URLComponents")
    func roundTrip() throws {
        for value in ["c++ & rust", "a+b=c?#1", "🐜 naïve עברית e\u{301}", "/tmp/a+b & c#1 100%/Ωmé"] {
            let url = try #require(URL(string: "app://x?v=\(value.addingQueryValueEncoding())"))
            let decoded = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first?.value
            #expect(decoded == value)
        }
    }
}
