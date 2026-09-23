import Foundation
import Testing
@testable import Goose

@Suite("URL.canonicalFileURL")
struct URLCanonicalTests {
    private func realPath(_ url: URL) -> String {
        guard let real = realpath(url.path, nil) else { return url.path }
        defer { free(real) }
        return String(cString: real)
    }

    @Test("Resolves symlinks and dot-dot, keeps /private, and appends missing components")
    func resolves() throws {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent("GooseCanon_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: base.appendingPathComponent("real"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: base) }
        try FileManager.default.createSymbolicLink(at: base.appendingPathComponent("link"), withDestinationURL: base.appendingPathComponent("real"))

        let canonicalBase = realPath(base)
        #expect(canonicalBase.hasPrefix("/private/"))
        #expect(base.appendingPathComponent("link/new/file.txt").canonicalFileURL?.path == canonicalBase + "/real/new/file.txt")
        #expect(base.appendingPathComponent("real/../real").canonicalFileURL?.path == canonicalBase + "/real")
    }

    @Test("Dangling symlinks cannot be canonicalised")
    func dangling() throws {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent("GooseDangling_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: base) }
        try FileManager.default.createSymbolicLink(atPath: base.appendingPathComponent("evil").path, withDestinationPath: "/nonexistent-\(UUID().uuidString)/x")

        #expect(base.appendingPathComponent("evil").canonicalFileURL == nil)
        #expect(base.appendingPathComponent("evil/child").canonicalFileURL == nil)
        #expect(!base.appendingPathComponent("evil").isContained(in: base))
        #expect(base.appendingPathComponent("ok/new").isContained(in: base))
        #expect(!URL(fileURLWithPath: base.path + "-sibling").isContained(in: base))
    }
}

@Suite("String.prettyPrintedJSON and DeveloperEnvironment")
struct SmallHelperTests {
    @Test("Pretty-prints JSON with sorted keys and unescaped slashes")
    func prettyJSON() {
        #expect(#"{"b":1,"a":"x/y"}"#.prettyPrintedJSON == "{\n  \"a\" : \"x/y\",\n  \"b\" : 1\n}")
        #expect("not json".prettyPrintedJSON == nil)
    }

    @Test("PATH gains tool directories once, in front")
    func path() {
        let path = DeveloperEnvironment.augmentedPATH("/usr/bin:/opt/homebrew/bin", homeDirectory: "/Users/me")
        #expect(path == "/opt/homebrew/sbin:/usr/local/bin:/Users/me/.local/bin:/usr/bin:/opt/homebrew/bin")
        #expect(DeveloperEnvironment.augmentedPATH(nil, homeDirectory: "/h").hasSuffix("/usr/bin:/bin:/usr/sbin:/sbin"))
        #expect(DeveloperEnvironment.executablePath(named: "sh", searchPath: "/nope:/bin") == "/bin/sh")
    }
}
