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
