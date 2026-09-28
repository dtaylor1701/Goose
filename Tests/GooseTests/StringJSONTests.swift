import Foundation
import Testing
@testable import Goose

@Suite("String JSON")
struct StringJSONTests {
    @Test("Canonical JSON ignores key order and whitespace")
    func canonical() {
        let first = #"{"path":"a/b","options":{"z":1,"a":[true,null]}}"#
        let second = "{ \"options\": { \"a\": [ true, null ], \"z\": 1 },\n  \"path\": \"a/b\" }"
        #expect(first.canonicalJSON == #"{"options":{"a":[true,null],"z":1},"path":"a/b"}"#)
        #expect(first.canonicalJSON == second.canonicalJSON)
        #expect("42".canonicalJSON == "42")
        #expect(#"{"path":"#.canonicalJSON == nil)
    }

    @Test("Pretty-printed JSON is indented with sorted keys")
    func prettyPrinted() {
        #expect(#"{"b":1,"a":"x/y"}"#.prettyPrintedJSON == "{\n  \"a\" : \"x/y\",\n  \"b\" : 1\n}")
        #expect("not json".prettyPrintedJSON == nil)
    }
}

@Suite("URL relative paths")
struct URLRelativePathTests {
    @Test("Paths inside a root are relative to it, after resolving .. and symlinks")
    func relativePaths() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("GooseRel_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root.appendingPathComponent("notes"), withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: root.appendingPathComponent("notes/up"), withDestinationURL: root)
        defer { try? FileManager.default.removeItem(at: root) }

        #expect(root.appendingPathComponent("notes/a.md").relativePath(from: root) == "notes/a.md")
        #expect(root.relativePath(from: root) == ".")
        #expect(root.appendingPathComponent("notes/../Package.swift").relativePath(from: root) == "Package.swift")
        #expect(root.appendingPathComponent("notes/up/.ant/settings.json").relativePath(from: root) == ".ant/settings.json")
        #expect(root.appendingPathComponent("../outside.txt").relativePath(from: root) == nil)
        // /var and /private/var name the same folder.
        let aliased = URL(fileURLWithPath: root.path.replacingOccurrences(of: "/private/var/", with: "/var/")).appendingPathComponent("x")
        #expect(aliased.relativePath(from: root) == "x")
        #expect(root.appendingPathComponent("x").isContained(in: root))
    }
}
