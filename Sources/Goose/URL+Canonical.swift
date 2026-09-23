import Foundation

extension URL {
    /// The file URL with `..` removed and every symlink resolved, via `realpath(3)`.
    ///
    /// Unlike `resolvingSymlinksInPath()`, this keeps `/private` prefixes (e.g. `/private/var`),
    /// so canonical paths compare consistently. Trailing components that don't exist yet are
    /// appended to the resolved existing prefix, which makes it usable for files about to be
    /// created.
    ///
    /// - Returns: `nil` when an existing component is a symlink that cannot be resolved
    ///   (dangling or looping), because its eventual target is unknowable.
    public var canonicalFileURL: URL? {
        var existing = standardizedFileURL
        var missing: [String] = []
        // lstat (not fileExists, which follows links) so a dangling symlink counts as present.
        var info = stat()
        while lstat(existing.path, &info) != 0 {
            guard existing.path != "/" else { break }
            missing.insert(existing.lastPathComponent, at: 0)
            existing.deleteLastPathComponent()
        }

        guard let real = realpath(existing.path, nil) else { return nil }
        defer { free(real) }
        var resolved = URL(fileURLWithPath: String(cString: real))
        for component in missing {
            resolved.appendPathComponent(component)
        }
        return resolved
    }

    /// Whether this file URL is `root` or lies inside it, comparing canonical paths.
    public func isContained(in root: URL) -> Bool {
        guard let path = canonicalFileURL?.path, let rootPath = root.canonicalFileURL?.path else { return false }
        return path == rootPath || path.hasPrefix(rootPath.hasSuffix("/") ? rootPath : rootPath + "/")
    }
}
