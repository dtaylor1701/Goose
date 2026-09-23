import Foundation
import Testing
@testable import Goose

@Suite("GitRepository", .serialized)
struct GitRepositoryTests {
    private func makeRepository() async throws -> (GitRepository, URL) {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("GooseGit_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let git = GitRepository(directory: root)
        try await git.run(["init", "-q", "-b", "main"])
        try await git.run(["config", "user.name", "Test"])
        try await git.run(["config", "user.email", "test@example.com"])
        try "one\n".write(to: root.appendingPathComponent("a.txt"), atomically: true, encoding: .utf8)
        try await git.run(["add", "."])
        try await git.run(["commit", "-q", "-m", "init"])
        return (git, root)
    }

    @Test("Porcelain -z parsing keeps spaces, non-ASCII, and rename sources")
    func parse() {
        let output = " M a.txt\0?? dir/new file ü.md\0R  new.txt\0old.txt\0A  added.txt\0"
        #expect(GitStatusEntry.parse(porcelainZ: output) == [
            GitStatusEntry(indexStatus: " ", worktreeStatus: "M", path: "a.txt"),
            GitStatusEntry(indexStatus: "?", worktreeStatus: "?", path: "dir/new file ü.md"),
            GitStatusEntry(indexStatus: "R", worktreeStatus: " ", path: "new.txt", originalPath: "old.txt"),
            GitStatusEntry(indexStatus: "A", worktreeStatus: " ", path: "added.txt")
        ])
        #expect(GitStatusEntry.parse(porcelainZ: output).map(\.kind) == [.modified, .untracked, .renamed, .added])
        #expect(GitStatusEntry.parse(porcelainZ: "").isEmpty)
    }

    @Test("Status and diff reflect real working-tree changes")
    func statusAndDiff() async throws {
        let (git, root) = try await makeRepository()
        defer { try? FileManager.default.removeItem(at: root) }
        try "two\n".write(to: root.appendingPathComponent("a.txt"), atomically: true, encoding: .utf8)
        try "x\n".write(to: root.appendingPathComponent("with space.txt"), atomically: true, encoding: .utf8)

        let status = try await git.status()
        #expect(status.map(\.path) == ["a.txt", "with space.txt"])
        #expect(status.map(\.code) == [" M", "??"])
        let diff = try await git.diff()
        #expect(diff.contains("-one"))
        #expect(diff.contains("+two"))
    }

    @Test("Commit, worktree lifecycle, and prune")
    func worktrees() async throws {
        let (git, root) = try await makeRepository()
        defer { try? FileManager.default.removeItem(at: root) }
        let base = try #require(await git.head())
        let tree = root.appendingPathComponent("wt")

        try await git.addWorktree(at: tree, newBranch: "feature", startPoint: base)
        let worktree = GitRepository(directory: tree)
        #expect(try await worktree.commitAll(message: "nothing", fallbackName: "A", fallbackEmail: "a@b") == false)
        try "new\n".write(to: tree.appendingPathComponent("b.txt"), atomically: true, encoding: .utf8)
        #expect(try await worktree.commitAll(message: "work", fallbackName: "A", fallbackEmail: "a@b") == true)
        #expect(try await git.commitCount(from: base, to: "feature") == 1)

        try FileManager.default.removeItem(at: tree)
        await #expect(throws: GitError.self) { try await git.deleteBranch("feature") }
        try await git.pruneWorktrees()
        try await git.deleteBranch("feature")
        #expect(try await git.value(["branch", "--list", "feature"]).isEmpty)
    }

    @Test("Failures carry git's message; non-repositories have no top level")
    func failures() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("GooseNoGit_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let git = GitRepository(directory: folder)
        #expect(await git.topLevel() == nil)
        do {
            try await git.run(["status"])
            Issue.record("expected failure")
        } catch let error as GitError {
            guard case .commandFailed(let arguments, let code, let message) = error else { Issue.record("wrong case"); return }
            #expect(arguments == ["status"])
            #expect(code != 0)
            #expect(message.contains("not a git repository"))
        }
    }
}
