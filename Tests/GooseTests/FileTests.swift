#if os(macOS)
import XCTest
@testable import Goose

final class FileTests: XCTestCase {
    var tempFileURL: URL!
    let testData = "Hello, Goose!".data(using: .utf8)!

    override func setUp() {
        super.setUp()
        let tempDirectory = FileManager.default.temporaryDirectory
        tempFileURL = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("txt")
        try? testData.write(to: tempFileURL)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempFileURL)
        super.tearDown()
    }

    func testInitWithURL() throws {
        let file = try File(at: tempFileURL)
        XCTAssertNotNil(file.bookmark)
    }

    func testGetURL() throws {
        var file = try File(at: tempFileURL)
        let url = try file.url()
        XCTAssertEqual(url.standardizedFileURL, tempFileURL.standardizedFileURL)
    }

    func testGetData() throws {
        var file = try File(at: tempFileURL)
        let data = try file.data()
        XCTAssertEqual(data, testData)
    }

    func testStartAccessingSecurityScopedURL() throws {
        var file = try File(at: tempFileURL)
        let url = try file.startAccessingSecurityScopedURL()
        XCTAssertEqual(url.standardizedFileURL, tempFileURL.standardizedFileURL)
        
        // Ensure we can read it
        let data = try Data(contentsOf: url)
        XCTAssertEqual(data, testData)
        
        url.stopAccessingSecurityScopedResource()
    }

    func testCodable() throws {
        let file = try File(at: tempFileURL)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let encodedData = try encoder.encode(file)
        var decodedFile = try decoder.decode(File.self, from: encodedData)
        
        let url = try decodedFile.url()
        XCTAssertEqual(url.standardizedFileURL, tempFileURL.standardizedFileURL)
    }

    func testMoveFile() throws {
        var file = try File(at: tempFileURL)
        
        let newURL = tempFileURL.deletingLastPathComponent().appendingPathComponent(UUID().uuidString).appendingPathExtension("txt")
        try FileManager.default.moveItem(at: tempFileURL, to: newURL)
        
        // Update tempFileURL so tearDown works
        tempFileURL = newURL
        
        let resolvedURL = try file.url()
        XCTAssertEqual(resolvedURL.standardizedFileURL, newURL.standardizedFileURL)
        
        let data = try file.data()
        XCTAssertEqual(data, testData)
    }

    func testDeletedFile() throws {
        var file = try File(at: tempFileURL)
        
        try FileManager.default.removeItem(at: tempFileURL)
        
        XCTAssertThrowsError(try file.url())
    }
}
#endif
