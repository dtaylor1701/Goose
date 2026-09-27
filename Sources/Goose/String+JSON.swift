import Foundation

extension String {
    /// The string re-serialised as indented JSON with sorted keys, or `nil` if it isn't valid JSON.
    public var prettyPrintedJSON: String? {
        reserializedJSON(options: [.prettyPrinted])
    }

    /// The string re-serialised as compact JSON with sorted keys, or `nil` if it isn't valid JSON.
    ///
    /// Equal JSON values produce equal strings, whatever their key order or whitespace.
    public var canonicalJSON: String? {
        reserializedJSON(options: [])
    }

    private func reserializedJSON(options: JSONSerialization.WritingOptions) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: Data(utf8), options: [.fragmentsAllowed]),
              let data = try? JSONSerialization.data(
                withJSONObject: object,
                options: options.union([.sortedKeys, .withoutEscapingSlashes, .fragmentsAllowed])
              )
        else { return nil }
        return String(decoding: data, as: UTF8.self)
    }
}
