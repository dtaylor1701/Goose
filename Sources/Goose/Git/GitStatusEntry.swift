import Foundation

/// One entry from `git status --porcelain=v1 -z`.
public struct GitStatusEntry: Sendable, Equatable, Hashable, Identifiable {
    /// The kind of change, derived from the two-letter porcelain code.
    public enum Kind: Sendable, Equatable {
        case modified
        case added
        case deleted
        case renamed
        case copied
        case untracked
        case ignored
        case conflicted
        case typeChanged
    }

    /// Status in the index (staged), e.g. `M`, `A`, or a space.
    public let indexStatus: Character
    /// Status in the working tree (unstaged), e.g. `M`, `?`, or a space.
    public let worktreeStatus: Character
    /// Path relative to the repository root.
    public let path: String
    /// Source path for renames and copies.
    public let originalPath: String?

    public var id: String { path }

    /// The two-character porcelain code, e.g. `" M"`, `"A "`, `"??"`.
    public var code: String { "\(indexStatus)\(worktreeStatus)" }

    public var kind: Kind {
        switch (indexStatus, worktreeStatus) {
        case ("?", "?"): return .untracked
        case ("!", "!"): return .ignored
        case ("U", _), (_, "U"), ("A", "A"), ("D", "D"): return .conflicted
        case ("R", _), (_, "R"): return .renamed
        case ("C", _), (_, "C"): return .copied
        case ("A", _), (_, "A"): return .added
        case ("D", _), (_, "D"): return .deleted
        case ("T", _), (_, "T"): return .typeChanged
        default: return .modified
        }
    }

    public init(indexStatus: Character, worktreeStatus: Character, path: String, originalPath: String? = nil) {
        self.indexStatus = indexStatus
        self.worktreeStatus = worktreeStatus
        self.path = path
        self.originalPath = originalPath
    }

    /// Parses NUL-separated `git status --porcelain=v1 -z` output.
    ///
    /// `-z` output is never quoted, so paths with spaces or non-ASCII characters are preserved,
    /// and renames list the destination followed by the source as separate fields.
    public static func parse(porcelainZ output: String) -> [GitStatusEntry] {
        var fields = output.split(separator: "\0", omittingEmptySubsequences: true).map(String.init)[...]
        var entries: [GitStatusEntry] = []

        while let field = fields.popFirst() {
            let characters = Array(field)
            guard characters.count > 3, characters[2] == " " else { continue }
            let index = characters[0]
            let worktree = characters[1]
            let path = String(characters[3...])
            var original: String?
            if "RC".contains(index) || "RC".contains(worktree) {
                original = fields.popFirst()
            }
            entries.append(GitStatusEntry(indexStatus: index, worktreeStatus: worktree, path: path, originalPath: original))
        }
        return entries
    }
}
