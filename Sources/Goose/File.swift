#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
import Foundation

/// A bookmarked file reference that persists access to a security-scoped resource.
///
/// `File` provides value-semantics for security-scoped bookmarks, ensuring that
/// file access is maintained across application restarts in sandboxed environments.
public struct File: Codable, Equatable, Sendable {
    public enum FileError: Error {
        case couldNotAccessResource
        case bookmarkResolutionFailed
    }

    /// The raw bookmark data.
    public private(set) var bookmark: Data
    
    /// A best-effort hint of the filename at the time the bookmark was created.
    public let filename: String?

    /// Creates a new `File` reference by creating a security-scoped bookmark for the given URL.
    /// - Parameter url: The URL to bookmark.
    /// - Throws: An error if the bookmark data could not be created.
    public init(at url: URL) throws {
        // Attempt to start accessing. This may return false if the URL is already accessible
        // or not security-scoped, but we proceed to try and create a bookmark regardless.
        let isScoped = url.startAccessingSecurityScopedResource()
        defer {
            if isScoped {
                url.stopAccessingSecurityScopedResource()
            }
        }

        self.bookmark = try url.bookmarkData(options: .withSecurityScope)
        self.filename = url.lastPathComponent
    }

    /// Resolves the bookmark and performs an asynchronous task with the resulting security-scoped URL.
    ///
    /// This will automatically update the internal bookmark if it has become stale.
    ///
    /// - Parameter block: An asynchronous closure that receives the resolved URL.
    /// - Returns: The value returned by the closure.
    /// - Throws: An error if the bookmark cannot be resolved or accessed.
  @available(macOS 10.15.0, *)
  public mutating func withURL<T>(_ block: (URL) async throws -> T) async throws -> T {
        let url = try resolveURL()
        guard url.startAccessingSecurityScopedResource() else {
            throw FileError.couldNotAccessResource
        }
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        return try await block(url)
    }

    /// Resolves the bookmark and performs a task with the resulting security-scoped URL.
    ///
    /// This will automatically update the internal bookmark if it has become stale.
    ///
    /// - Parameter block: A closure that receives the resolved URL.
    /// - Returns: The value returned by the closure.
    /// - Throws: An error if the bookmark cannot be resolved or accessed.
    public mutating func withURL<T>(_ block: (URL) throws -> T) throws -> T {
        let url = try resolveURL()
        guard url.startAccessingSecurityScopedResource() else {
            throw FileError.couldNotAccessResource
        }
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        return try block(url)
    }

    /// Reads the data from the bookmarked file.
    ///
    /// This will automatically update the internal bookmark if it has become stale.
    /// - Returns: The contents of the file.
    /// - Throws: An error if the file cannot be read or accessed.
    public mutating func data() throws -> Data {
        try withURL { url in
            try Data(contentsOf: url)
        }
    }

    /// Resolves the bookmark to a URL, updating the internal bookmark data if it has become stale.
    ///
    /// - Returns: The resolved URL.
    /// - Throws: An error if resolution fails.
    public mutating func resolveURL() throws -> URL {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmark,
            options: .withSecurityScope,
            bookmarkDataIsStale: &isStale
        )
        
        if isStale {
            let isScoped = url.startAccessingSecurityScopedResource()
            defer {
                if isScoped {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            bookmark = try url.bookmarkData(options: .withSecurityScope)
        }
        
        return url
    }

    // MARK: - Legacy / Manual Access

    /// Starts accessing the security-scoped URL and returns it.
    ///
    /// - Warning: You MUST call `stopAccessingSecurityScopedResource()` on the returned URL
    ///   when you are finished with it. Failure to do so will result in resource leaks.
    ///   Prefer `withURL(_:)` for a safer, closure-based approach.
    ///
    /// - Returns: The resolved and accessed URL.
    /// - Throws: An error if the bookmark cannot be resolved or accessed.
    @available(*, deprecated, renamed: "withURL(_:)", message: "Use the closure-based withURL(_:) instead to avoid resource leaks.")
    public mutating func startAccessingSecurityScopedURL() throws -> URL {
        let url = try resolveURL()
        guard url.startAccessingSecurityScopedResource() else {
            throw FileError.couldNotAccessResource
        }
        return url
    }

    // MARK: - Batch Access

    /// Resolves and accesses multiple files concurrently.
    /// - Parameters:
    ///   - file1: The first file to access.
    ///   - file2: The second file to access.
    ///   - block: A closure that receives the resolved URLs.
    /// - Returns: The value returned by the closure.
    public static func withURLs<T>(
        _ file1: inout File,
        _ file2: inout File,
        _ block: (URL, URL) throws -> T
    ) throws -> T {
        let url1 = try file1.resolveURL()
        guard url1.startAccessingSecurityScopedResource() else { throw FileError.couldNotAccessResource }
        defer { url1.stopAccessingSecurityScopedResource() }

        let url2 = try file2.resolveURL()
        guard url2.startAccessingSecurityScopedResource() else { throw FileError.couldNotAccessResource }
        defer { url2.stopAccessingSecurityScopedResource() }

        return try block(url1, url2)
    }

    /// Resolves and accesses multiple files concurrently.
    /// - Parameters:
    ///   - file1: The first file to access.
    ///   - file2: The second file to access.
    ///   - block: An asynchronous closure that receives the resolved URLs.
    /// - Returns: The value returned by the closure.
  @available(macOS 10.15.0, *)
  public static func withURLs<T>(
        _ file1: inout File,
        _ file2: inout File,
        _ block: (URL, URL) async throws -> T
    ) async throws -> T {
        let url1 = try file1.resolveURL()
        guard url1.startAccessingSecurityScopedResource() else { throw FileError.couldNotAccessResource }
        defer { url1.stopAccessingSecurityScopedResource() }

        let url2 = try file2.resolveURL()
        guard url2.startAccessingSecurityScopedResource() else { throw FileError.couldNotAccessResource }
        defer { url2.stopAccessingSecurityScopedResource() }

        return try await block(url1, url2)
    }

    /// Resolves and accesses multiple files concurrently.
    /// - Parameters:
    ///   - file1: The first file to access.
    ///   - file2: The second file to access.
    ///   - file3: The third file to access.
    ///   - block: A closure that receives the resolved URLs.
    /// - Returns: The value returned by the closure.
    public static func withURLs<T>(
        _ file1: inout File,
        _ file2: inout File,
        _ file3: inout File,
        _ block: (URL, URL, URL) throws -> T
    ) throws -> T {
        let url1 = try file1.resolveURL()
        guard url1.startAccessingSecurityScopedResource() else { throw FileError.couldNotAccessResource }
        defer { url1.stopAccessingSecurityScopedResource() }

        let url2 = try file2.resolveURL()
        guard url2.startAccessingSecurityScopedResource() else { throw FileError.couldNotAccessResource }
        defer { url2.stopAccessingSecurityScopedResource() }

        let url3 = try file3.resolveURL()
        guard url3.startAccessingSecurityScopedResource() else { throw FileError.couldNotAccessResource }
        defer { url3.stopAccessingSecurityScopedResource() }

        return try block(url1, url2, url3)
    }

    /// Resolves and accesses multiple files concurrently.
    /// - Parameters:
    ///   - file1: The first file to access.
    ///   - file2: The second file to access.
    ///   - file3: The third file to access.
    ///   - block: An asynchronous closure that receives the resolved URLs.
    /// - Returns: The value returned by the closure.
  @available(macOS 10.15.0, *)
  public static func withURLs<T>(
        _ file1: inout File,
        _ file2: inout File,
        _ file3: inout File,
        _ block: (URL, URL, URL) async throws -> T
    ) async throws -> T {
        let url1 = try file1.resolveURL()
        guard url1.startAccessingSecurityScopedResource() else { throw FileError.couldNotAccessResource }
        defer { url1.stopAccessingSecurityScopedResource() }

        let url2 = try file2.resolveURL()
        guard url2.startAccessingSecurityScopedResource() else { throw FileError.couldNotAccessResource }
        defer { url2.stopAccessingSecurityScopedResource() }

        let url3 = try file3.resolveURL()
        guard url3.startAccessingSecurityScopedResource() else { throw FileError.couldNotAccessResource }
        defer { url3.stopAccessingSecurityScopedResource() }

        return try await block(url1, url2, url3)
    }
}

extension Array where Element == File {
    /// Resolves and accesses all files in the array concurrently.
    ///
    /// This method ensures all successfully accessed URLs are properly released even if an error occurs
    /// during resolution of one of the files.
    ///
    /// - Parameter block: A closure that receives the array of resolved URLs.
    /// - Returns: The value returned by the closure.
    public mutating func withURLs<T>(_ block: ([URL]) throws -> T) throws -> T {
        var accessedURLs = [URL]()
        accessedURLs.reserveCapacity(count)

        defer {
            for url in accessedURLs {
                url.stopAccessingSecurityScopedResource()
            }
        }

        for i in indices {
            let url = try self[i].resolveURL()
            guard url.startAccessingSecurityScopedResource() else {
                throw File.FileError.couldNotAccessResource
            }
            accessedURLs.append(url)
        }

        return try block(accessedURLs)
    }

    /// Resolves and accesses all files in the array concurrently.
    ///
    /// This method ensures all successfully accessed URLs are properly released even if an error occurs
    /// during resolution of one of the files.
    ///
    /// - Parameter block: An asynchronous closure that receives the array of resolved URLs.
    /// - Returns: The value returned by the closure.
  @available(macOS 10.15.0, *)
  public mutating func withURLs<T>(_ block: ([URL]) async throws -> T) async throws -> T {
        var accessedURLs = [URL]()
        accessedURLs.reserveCapacity(count)

        defer {
            for url in accessedURLs {
                url.stopAccessingSecurityScopedResource()
            }
        }

        for i in indices {
            let url = try self[i].resolveURL()
            guard url.startAccessingSecurityScopedResource() else {
                throw File.FileError.couldNotAccessResource
            }
            accessedURLs.append(url)
        }

        return try await block(accessedURLs)
    }
}
#endif
