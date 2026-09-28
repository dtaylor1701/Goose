import Foundation

#if os(macOS) || os(Linux)

/// Runs `git` commands against a working directory.
///
/// Commands run through ``ProcessRunner``, so they never block cooperative threads, drain
/// large output safely, and stop when the calling task is cancelled.
public struct GitRepository: Sendable {
    /// The directory commands run in; any path inside a repository or worktree.
    public let directory: URL
    /// Path to the `git` executable.
    public let executablePath: String

    public init(directory: URL, executablePath: String = "/usr/bin/git") {
        self.directory = directory
        self.executablePath = executablePath
    }

    /// Runs `git` with `arguments` and returns standard output unmodified.
    ///
    /// - Parameter extraArguments: Arguments placed before the subcommand, e.g. `["-c", "k=v"]`.
    /// - Throws: ``GitError/commandFailed(arguments:exitCode:message:)`` on a non-zero exit.
    @discardableResult
    public func run(_ arguments: [String], timeout: TimeInterval? = nil) async throws -> String {
        let result = try await ProcessRunner.run(
            executablePath: executablePath,
            arguments: ["-C", directory.path] + arguments,
            timeout: timeout
        )
        guard result.termination == .exited else {
            throw GitError.interrupted(arguments: arguments)
        }
        guard result.exitCode == 0 else {
            let message = result.errorOutput.isEmpty ? result.output : result.errorOutput
            throw GitError.commandFailed(arguments: arguments, exitCode: result.exitCode, message: message)
        }
        return result.output
    }

    /// Runs `git` and returns its output with surrounding whitespace removed.
    public func value(_ arguments: [String]) async throws -> String {
        try await run(arguments).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The repository's top-level directory, or `nil` if `directory` is not inside a repository.
    public func topLevel() async -> URL? {
        guard let path = try? await value(["rev-parse", "--show-toplevel"]), !path.isEmpty else { return nil }
        return URL(fileURLWithPath: path, isDirectory: true)
    }

    /// The commit `HEAD` points to, or `nil` for a repository without commits.
    public func head() async -> String? {
        try? await value(["rev-parse", "--verify", "HEAD"])
    }

    /// The branch checked out, or `nil` on a detached `HEAD` or outside a repository.
    public func currentBranch() async -> String? {
        guard let name = try? await value(["symbolic-ref", "--quiet", "--short", "HEAD"]), !name.isEmpty else { return nil }
        return name
    }

    /// Working-tree status parsed from `git status --porcelain=v1 -z`.
    ///
    /// - Parameter pathspec: Limits the status to these pathspecs (e.g. `[".", ":(exclude).ant"]`).
    ///   Returned paths are always relative to the repository root.
    public func status(pathspec: [String] = [], includeUntracked: Bool = true) async throws -> [GitStatusEntry] {
        var arguments = ["status", "--porcelain=v1", "-z", includeUntracked ? "--untracked-files=all" : "--untracked-files=no"]
        if !pathspec.isEmpty { arguments += ["--"] + pathspec }
        return GitStatusEntry.parse(porcelainZ: try await run(arguments))
    }

    /// A unified diff of tracked changes against `HEAD` (or the index for repositories without commits).
    public func diff(pathspec: [String] = []) async throws -> String {
        var arguments = ["diff", "--no-color", "--no-ext-diff"]
        if await head() != nil { arguments.append("HEAD") }
        if !pathspec.isEmpty { arguments += ["--"] + pathspec }
        return try await run(arguments)
    }

    /// Creates a worktree at `path` on a new branch starting at `startPoint`.
    public func addWorktree(at path: URL, newBranch: String, startPoint: String) async throws {
        try await run(["worktree", "add", "-b", newBranch, path.path, startPoint])
    }

    /// Removes the worktree at `path`, discarding uncommitted changes.
    public func removeWorktree(at path: URL) async throws {
        try await run(["worktree", "remove", "--force", path.path])
    }

    /// Forgets worktrees whose directories no longer exist.
    public func pruneWorktrees() async throws {
        try await run(["worktree", "prune"])
    }

    /// Stages everything and commits it, skipping hooks and signing so unattended commits cannot
    /// block on prompts. Supplies a fallback identity only when none is configured.
    /// - Returns: `true` if a commit was created, `false` if there was nothing to commit.
    @discardableResult
    public func commitAll(message: String, fallbackName: String, fallbackEmail: String) async throws -> Bool {
        guard try await !status().isEmpty else { return false }
        try await run(["add", "-A"])
        let email = (try? await value(["config", "user.email"])) ?? ""
        let identity = email.isEmpty ? ["-c", "user.name=\(fallbackName)", "-c", "user.email=\(fallbackEmail)"] : []
        try await run(identity + ["-c", "commit.gpgsign=false", "commit", "--no-verify", "-q", "-m", message])
        return true
    }

    /// Number of commits reachable from `revision` but not from `base`.
    public func commitCount(from base: String, to revision: String) async throws -> Int {
        Int(try await value(["rev-list", "--count", "\(base)..\(revision)"])) ?? 0
    }

    /// Deletes a local branch regardless of merge state.
    public func deleteBranch(_ name: String) async throws {
        try await run(["branch", "-D", name])
    }
}

#endif
