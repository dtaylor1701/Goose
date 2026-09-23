import Foundation

/// Helpers for tools launched from Finder, which receive a minimal `PATH` instead of the
/// user's shell environment.
public enum DeveloperEnvironment {
    /// Common locations for developer tools that GUI apps don't inherit.
    public static let toolDirectories = ["/opt/homebrew/bin", "/opt/homebrew/sbin", "/usr/local/bin"]

    /// `path` with the Homebrew, `/usr/local`, and `~/.local/bin` directories prepended when missing.
    public static func augmentedPATH(
        _ path: String? = ProcessInfo.processInfo.environment["PATH"],
        homeDirectory: String = NSHomeDirectory()
    ) -> String {
        let fallback = "/usr/bin:/bin:/usr/sbin:/sbin"
        let current = ((path?.isEmpty ?? true) ? fallback : path ?? fallback)
            .split(separator: ":").map(String.init)
        let extra = toolDirectories + ["\(homeDirectory)/.local/bin"]
        return (extra.filter { !current.contains($0) } + current).joined(separator: ":")
    }

    /// Updates this process's `PATH` so child processes find developer tools.
    public static func prepareProcessPATH() {
        setenv("PATH", augmentedPATH(), 1)
    }

    /// Finds an executable by name in the augmented `PATH`.
    public static func executablePath(named name: String, searchPath: String = augmentedPATH()) -> String? {
        searchPath.split(separator: ":")
            .map { "\($0)/\(name)" }
            .first { FileManager.default.isExecutableFile(atPath: $0) }
    }
}
