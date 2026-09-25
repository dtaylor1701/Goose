import Foundation

/// Decodes UTF-8 text that arrives in arbitrary chunks, such as process output.
///
/// A multi-byte character split across two chunks is held back until the rest of it arrives,
/// instead of being decoded as replacement characters.
///
/// ```swift
/// var decoder = UTF8StreamDecoder()
/// let text = decoder.decode(chunk) + decoder.flush()
/// ```
public struct UTF8StreamDecoder: Sendable {
    private var pending = Data()

    public init() {}

    /// Decodes as much of `data`, plus any bytes held back from earlier chunks, as forms whole characters.
    public mutating func decode(_ data: Data) -> String {
        pending.append(data)
        let complete = Self.completePrefixLength(of: pending)
        let text = String(decoding: pending.prefix(complete), as: UTF8.self)
        pending = Data(pending.dropFirst(complete))
        return text
    }

    /// Decodes any held-back bytes, replacing an incomplete trailing character.
    public mutating func flush() -> String {
        defer { pending = Data() }
        return String(decoding: pending, as: UTF8.self)
    }

    /// The length of `data` without a trailing, incomplete multi-byte sequence.
    private static func completePrefixLength(of data: Data) -> Int {
        let bytes = [UInt8](data.suffix(4))
        // Walk back over continuation bytes (10xxxxxx) to the lead byte of the last character.
        var index = bytes.count - 1
        while index >= 0, bytes[index] & 0b1100_0000 == 0b1000_0000 {
            index -= 1
        }
        guard index >= 0 else { return data.count }

        let lead = bytes[index]
        let expected: Int
        switch lead {
        case 0b1111_0000...0b1111_0111: expected = 4
        case 0b1110_0000...0b1110_1111: expected = 3
        case 0b1100_0000...0b1101_1111: expected = 2
        default: return data.count
        }
        let available = bytes.count - index
        return available < expected ? data.count - available : data.count
    }
}
