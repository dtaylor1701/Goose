#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
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
        XCTAssertEqual(file.filename, tempFileURL.lastPathComponent)
    }

    func testResolveURL() throws {
        var file = try File(at: tempFileURL)
        let url = try file.resolveURL()
        XCTAssertEqual(url.standardizedFileURL, tempFileURL.standardizedFileURL)
    }

    func testGetData() throws {
        var file = try File(at: tempFileURL)
        let data = try file.data()
        XCTAssertEqual(data, testData)
    }

    func testWithURL() throws {
        var file = try File(at: tempFileURL)
        try file.withURL { url in
            XCTAssertEqual(url.standardizedFileURL, tempFileURL.standardizedFileURL)
            let data = try Data(contentsOf: url)
            XCTAssertEqual(data, testData)
        }
    }

    func testWithURLAsync() async throws {
        var file = try File(at: tempFileURL)
        try await file.withURL { url in
            XCTAssertEqual(url.standardizedFileURL, tempFileURL.standardizedFileURL)
            
            // Simulate async work
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            
            let data = try Data(contentsOf: url)
            XCTAssertEqual(data, testData)
        }
    }

    func testAutomaticBookmarkUpdate() throws {
        var file = try File(at: tempFileURL)
        
        // Move the file to make the bookmark stale
        let newURL = tempFileURL.deletingLastPathComponent().appendingPathComponent(UUID().uuidString).appendingPathExtension("txt")
        try FileManager.default.moveItem(at: tempFileURL, to: newURL)
        tempFileURL = newURL
        
        let oldBookmark = file.bookmark
        let resolvedURL = try file.resolveURL()
        
        XCTAssertEqual(resolvedURL.standardizedFileURL, newURL.standardizedFileURL)
        XCTAssertNotEqual(file.bookmark, oldBookmark, "Bookmark should have been automatically updated after resolution of stale data")
    }

    func testCodable() throws {
        let file = try File(at: tempFileURL)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let encodedData = try encoder.encode(file)
        var decodedFile = try decoder.decode(File.self, from: encodedData)
        
        XCTAssertEqual(decodedFile.filename, file.filename)
        
        let url = try decodedFile.resolveURL()
        XCTAssertEqual(url.standardizedFileURL, tempFileURL.standardizedFileURL)
    }

    func testMoveFile() throws {
        var file = try File(at: tempFileURL)
        
        let newURL = tempFileURL.deletingLastPathComponent().appendingPathComponent(UUID().uuidString).appendingPathExtension("txt")
        try FileManager.default.moveItem(at: tempFileURL, to: newURL)
        
        // Update tempFileURL so tearDown works
        tempFileURL = newURL
        
        let resolvedURL = try file.resolveURL()
        XCTAssertEqual(resolvedURL.standardizedFileURL, newURL.standardizedFileURL)
        
        let data = try file.data()
        XCTAssertEqual(data, testData)
    }

    func testDeletedFile() throws {
        var file = try File(at: tempFileURL)
        
        try FileManager.default.removeItem(at: tempFileURL)
        
        XCTAssertThrowsError(try file.resolveURL())
    }

    func testWithURLsArity2() throws {
        let tempFileURL2 = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("txt")
        try "Second File".data(using: .utf8)?.write(to: tempFileURL2)
        defer { try? FileManager.default.removeItem(at: tempFileURL2) }

        var file1 = try File(at: tempFileURL)
        var file2 = try File(at: tempFileURL2)

        try File.withURLs(&file1, &file2) { url1, url2 in
            XCTAssertEqual(url1.standardizedFileURL, tempFileURL.standardizedFileURL)
            XCTAssertEqual(url2.standardizedFileURL, tempFileURL2.standardizedFileURL)
            XCTAssertEqual(try Data(contentsOf: url1), testData)
            XCTAssertEqual(try Data(contentsOf: url2), "Second File".data(using: .utf8))
        }
    }

    func testWithURLsArity3() throws {
        let tempFileURL2 = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("txt")
        let tempFileURL3 = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("txt")
        try "Second File".data(using: .utf8)?.write(to: tempFileURL2)
        try "Third File".data(using: .utf8)?.write(to: tempFileURL3)
        defer {
            try? FileManager.default.removeItem(at: tempFileURL2)
            try? FileManager.default.removeItem(at: tempFileURL3)
        }

        var file1 = try File(at: tempFileURL)
        var file2 = try File(at: tempFileURL2)
        var file3 = try File(at: tempFileURL3)

        try File.withURLs(&file1, &file2, &file3) { url1, url2, url3 in
            XCTAssertEqual(url1.standardizedFileURL, tempFileURL.standardizedFileURL)
            XCTAssertEqual(url2.standardizedFileURL, tempFileURL2.standardizedFileURL)
            XCTAssertEqual(url3.standardizedFileURL, tempFileURL3.standardizedFileURL)
        }
    }

    func testWithURLsArray() throws {
        let tempFileURL2 = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("txt")
        try "Second File".data(using: .utf8)?.write(to: tempFileURL2)
        defer { try? FileManager.default.removeItem(at: tempFileURL2) }

        var files = [
            try File(at: tempFileURL),
            try File(at: tempFileURL2)
        ]

        try files.withURLs { urls in
            XCTAssertEqual(urls.count, 2)
            XCTAssertEqual(urls[0].standardizedFileURL, tempFileURL.standardizedFileURL)
            XCTAssertEqual(urls[1].standardizedFileURL, tempFileURL2.standardizedFileURL)
        }
    }

    func testWithURLsArrayAsync() async throws {
        let tempFileURL2 = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("txt")
        try "Second File".data(using: .utf8)?.write(to: tempFileURL2)
        defer { try? FileManager.default.removeItem(at: tempFileURL2) }

        var files = [
            try File(at: tempFileURL),
            try File(at: tempFileURL2)
        ]

        try await files.withURLs { urls in
            XCTAssertEqual(urls.count, 2)
            try await Task.sleep(nanoseconds: 10_000_000)
            XCTAssertEqual(urls[0].standardizedFileURL, tempFileURL.standardizedFileURL)
            XCTAssertEqual(urls[1].standardizedFileURL, tempFileURL2.standardizedFileURL)
        }
    }
}
#endif
