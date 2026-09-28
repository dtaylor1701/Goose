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
        canonicalFileURL.flatMap { $0.relativePath(from: root) } != nil
    }

    /// This file URL's path relative to `root`, using `/`: `"."` for `root` itself, `nil` when
    /// it lies outside. Both are made canonical first, so `..`, symlinks, and `/private`
    /// prefixes can't make a path look inside (or outside) when it isn't.
    public func relativePath(from root: URL) -> String? {
        guard let path = canonicalFileURL?.path, let rootPath = root.canonicalFileURL?.path else { return nil }
        if path == rootPath { return "." }
        let prefix = rootPath.hasSuffix("/") ? rootPath : rootPath + "/"
        return path.hasPrefix(prefix) ? String(path.dropFirst(prefix.count)) : nil
    }
}
