import Foundation

extension CharacterSet {
    /// Characters left unescaped in a URL query value: RFC 3986 unreserved plus a few safe
    /// sub-delimiters. Unlike `.urlQueryAllowed`, this excludes `+`, `&`, `=`, `#`, and `?`.
    public static let urlQueryValueAllowed = CharacterSet(charactersIn:
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~/:@!$'()*,;")
}

extension String {
    /// The string percent-encoded for use as one URL query value.
    ///
    /// `+`, `&`, `=`, `#`, and `?` are always escaped, so both Foundation and form-style
    /// (`URLSearchParams`) decoders read the value back exactly.
    public func addingQueryValueEncoding() -> String {
        // Only fails for strings that aren't valid UTF-16 (lone surrogates), which Swift strings can't hold.
        addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? self
    }
}
