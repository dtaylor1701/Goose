import Foundation

/// The patterns of a `.gitignore`-style file, matched against paths relative to that file's
/// folder.
///
/// Supports the usual syntax: comments, `!` negation, a trailing `/` for folders only, a leading
/// or inner `/` to anchor a pattern to the file's folder, `*`, `?`, `[…]` classes, `**`, and `\`
/// escapes. As in git, the last pattern that matches decides.
public struct IgnoreRules: Sendable {
    private struct Rule: Sendable {
        let regex: NSRegularExpression
        let isNegated: Bool
        let isDirectoryOnly: Bool
    }

    private let rules: [Rule]

    /// Parses the contents of an ignore file. Lines that aren't valid patterns are skipped.
    public init(contents: String) {
        rules = contents.split(whereSeparator: \.isNewline).compactMap { Self.rule(from: String($0)) }
    }

    /// Whether `relativePath` (using `/` separators) is ignored: `true` or `false` when a pattern
    /// decides, `nil` when none matches, so a caller can fall back to other ignore files.
    public func decision(for relativePath: String, isDirectory: Bool) -> Bool? {
        let range = NSRange(relativePath.startIndex..., in: relativePath)
        for rule in rules.reversed() {
            if rule.isDirectoryOnly && !isDirectory { continue }
            if rule.regex.firstMatch(in: relativePath, range: range) != nil {
                return !rule.isNegated
            }
        }
        return nil
    }

    private static func rule(from line: String) -> Rule? {
        var pattern = trimmingUnescapedTrailingSpaces(line)
        guard !pattern.isEmpty, !pattern.hasPrefix("#") else { return nil }

        var isNegated = false
        if pattern.hasPrefix("!") {
            isNegated = true
            pattern.removeFirst()
        } else if pattern.hasPrefix("\\!") || pattern.hasPrefix("\\#") {
            pattern.removeFirst()
        }

        var isDirectoryOnly = false
        if pattern.hasSuffix("/") {
            isDirectoryOnly = true
            pattern.removeLast()
        }
        // A slash anywhere but the end ties the pattern to the ignore file's folder.
        let isAnchored = pattern.contains("/")
        if pattern.hasPrefix("/") { pattern.removeFirst() }
        guard !pattern.isEmpty else { return nil }

        let body = regexBody(for: pattern)
        let source = isAnchored ? "^\(body)$" : "^(?:.*/)?\(body)$"
        guard let regex = try? NSRegularExpression(pattern: source) else { return nil }
        return Rule(regex: regex, isNegated: isNegated, isDirectoryOnly: isDirectoryOnly)
    }

    /// Trailing spaces are dropped unless escaped with `\`.
    private static func trimmingUnescapedTrailingSpaces(_ line: String) -> String {
        var characters = Array(line)
        while characters.last == " " {
            if characters.count >= 2, characters[characters.count - 2] == "\\" {
                characters.remove(at: characters.count - 2)
                break
            }
            characters.removeLast()
        }
        return String(characters)
    }

    /// Translates glob syntax into a regular expression body.
    private static func regexBody(for pattern: String) -> String {
        let characters = Array(pattern)
        var body = ""
        var index = 0
        while index < characters.count {
            let character = characters[index]
            switch character {
            case "*":
                let isDouble = index + 1 < characters.count && characters[index + 1] == "*"
                guard isDouble else {
                    body += "[^/]*"
                    index += 1
                    continue
                }
                let atStart = index == 0
                let followedBySlash = index + 2 < characters.count && characters[index + 2] == "/"
                let atEnd = index + 2 == characters.count
                if atStart && followedBySlash {
                    body += "(?:.*/)?"      // `**/x`: x in any folder
                    index += 3
                } else if followedBySlash {
                    body += "(?:.*/)?"      // `a/**/z`: zero or more folders between
                    index += 3
                } else if atEnd {
                    body += ".+"            // `a/**`: everything inside
                    index += 2
                } else {
                    body += ".*"
                    index += 2
                }
            case "?":
                body += "[^/]"
                index += 1
            case "[":
                if let close = characters[(index + 1)...].firstIndex(of: "]"), close > index + 1 {
                    var set = String(characters[(index + 1)..<close])
                    if set.hasPrefix("!") { set = "^" + set.dropFirst() }
                    body += "[" + set.replacingOccurrences(of: "\\", with: "\\\\") + "]"
                    index = close + 1
                } else {
                    body += "\\["
                    index += 1
                }
            case "\\" where index + 1 < characters.count:
                body += NSRegularExpression.escapedPattern(for: String(characters[index + 1]))
                index += 2
            default:
                body += NSRegularExpression.escapedPattern(for: String(character))
                index += 1
            }
        }
        return body
    }
}
