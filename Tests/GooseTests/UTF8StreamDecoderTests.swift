import Foundation
import Testing
import Goose

@Suite("UTF8StreamDecoder")
struct UTF8StreamDecoderTests {
    @Test("A character split across chunks decodes once complete")
    func splitCharacter() {
        let bytes = Array("a€b🐜".utf8)
        var decoder = UTF8StreamDecoder()
        var text = ""
        for byte in bytes {
            text += decoder.decode(Data([byte]))
        }
        text += decoder.flush()
        #expect(text == "a€b🐜")
    }

    @Test("Held-back bytes are not emitted early")
    func holdsBack() {
        var decoder = UTF8StreamDecoder()
        let euro = Array("€".utf8)
        #expect(decoder.decode(Data([0x61] + euro.prefix(2))) == "a")
        #expect(decoder.decode(Data(euro.suffix(1))) == "€")
    }

    @Test("Flushing an incomplete character yields a replacement character")
    func flushIncomplete() {
        var decoder = UTF8StreamDecoder()
        _ = decoder.decode(Data(Array("€".utf8).prefix(1)))
        #expect(decoder.flush() == "\u{FFFD}")
        #expect(decoder.flush().isEmpty)
    }
}
