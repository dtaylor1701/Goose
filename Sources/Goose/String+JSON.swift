import Foundation

extension String {
    /// The string re-serialised as indented JSON with sorted keys, or `nil` if it isn't valid JSON.
    public var prettyPrintedJSON: String? {
        guard let object = try? JSONSerialization.jsonObject(with: Data(utf8), options: [.fragmentsAllowed]),
              let data = try? JSONSerialization.data(
                withJSONObject: object,
                options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes, .fragmentsAllowed]
              )
        else { return nil }
        return String(decoding: data, as: UTF8.self)
    }
}
