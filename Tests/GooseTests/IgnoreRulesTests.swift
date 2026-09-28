import Testing
@testable import Goose

@Suite("Ignore rules")
struct IgnoreRulesTests {
    private func ignored(_ rules: IgnoreRules, _ path: String, directory: Bool = false) -> Bool? {
        rules.decision(for: path, isDirectory: directory)
    }

    @Test("Comments, blank lines and unmatched paths make no decision")
    func noDecision() {
        let rules = IgnoreRules(contents: "# build output\n\n   \n*.log\n")
        #expect(ignored(rules, "Sources/main.swift") == nil)
        #expect(ignored(rules, "# build output") == nil)
    }

    @Test("A pattern without a slash matches the name at any depth")
    func unanchored() {
        let rules = IgnoreRules(contents: "*.log\n.DS_Store\nbuild/\n")
        #expect(ignored(rules, "error.log") == true)
        #expect(ignored(rules, "a/b/error.log") == true)
        #expect(ignored(rules, "a/.DS_Store") == true)
        #expect(ignored(rules, "a/build", directory: true) == true)
        #expect(ignored(rules, "a/build", directory: false) == nil, "a trailing slash matches only folders")
        #expect(ignored(rules, "error.log.txt") == nil)
    }

    @Test("A pattern with a slash is relative to the ignore file's folder")
    func anchored() {
        let rules = IgnoreRules(contents: "/TODO\ndocs/*.md\nPackages/*/\n")
        #expect(ignored(rules, "TODO") == true)
        #expect(ignored(rules, "src/TODO") == nil)
        #expect(ignored(rules, "docs/guide.md") == true)
        #expect(ignored(rules, "docs/api/guide.md") == nil, "* doesn't cross folders")
        #expect(ignored(rules, "Packages/Goose", directory: true) == true)
        #expect(ignored(rules, "Packages/README.md") == nil)
    }

    @Test("Double stars cross folders")
    func doubleStars() {
        let rules = IgnoreRules(contents: "**/fixtures\nlogs/**\na/**/z\n")
        #expect(ignored(rules, "fixtures", directory: true) == true)
        #expect(ignored(rules, "tests/unit/fixtures", directory: true) == true)
        #expect(ignored(rules, "logs/2026/app.log") == true)
        #expect(ignored(rules, "logs") == nil)
        #expect(ignored(rules, "a/z") == true)
        #expect(ignored(rules, "a/b/c/z") == true)
    }

    @Test("Negation re-includes, and the last matching pattern wins")
    func negation() {
        let rules = IgnoreRules(contents: "*.md\n!README.md\n")
        #expect(ignored(rules, "notes.md") == true)
        #expect(ignored(rules, "README.md") == false)
        #expect(ignored(IgnoreRules(contents: "!README.md\n*.md\n"), "README.md") == true)
    }

    @Test("Question marks, character classes and escapes")
    func specialCharacters() {
        let rules = IgnoreRules(contents: "file?.txt\n[ab].swift\n[!c]x.swift\n\\#literal\n\\!bang\nspace\\ \n")
        #expect(ignored(rules, "file1.txt") == true)
        #expect(ignored(rules, "file10.txt") == nil)
        #expect(ignored(rules, "a.swift") == true)
        #expect(ignored(rules, "c.swift") == nil)
        #expect(ignored(rules, "dx.swift") == true)
        #expect(ignored(rules, "cx.swift") == nil)
        #expect(ignored(rules, "#literal") == true)
        #expect(ignored(rules, "!bang") == true)
        #expect(ignored(rules, "space ") == true)
    }

    @Test("Regex characters in names are literal")
    func literalCharacters() {
        let rules = IgnoreRules(contents: "a+b.(1)\n")
        #expect(ignored(rules, "a+b.(1)") == true)
        #expect(ignored(rules, "aab.(1)") == nil)
    }
}
