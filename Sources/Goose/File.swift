#if os(macOS)
  import Foundation

  /// A bookmarked file reference.
  public struct File: Codable, Equatable, Sendable {
    public enum FileError: Error {
      case couldNotAccessResource
    }

    public private(set) var bookmark: Data

    public init(at url: URL) throws {
      defer {
        url.stopAccessingSecurityScopedResource()
      }

      guard url.startAccessingSecurityScopedResource() else {
        throw FileError.couldNotAccessResource
      }

      self.bookmark = try url.bookmarkData(options: .withSecurityScope)
    }

    public mutating func url() throws -> URL {
      var isStale = false
      let url = try URL(
        resolvingBookmarkData: bookmark,
        options: .withSecurityScope,
        bookmarkDataIsStale: &isStale)
      if isStale {
        guard url.startAccessingSecurityScopedResource() else {
          throw FileError.couldNotAccessResource
        }
        bookmark = try url.bookmarkData(options: .withSecurityScope)
        url.stopAccessingSecurityScopedResource()
      }

      return url
    }

    public mutating func data() throws -> Data {
      let url = try url()
      guard url.startAccessingSecurityScopedResource() else {
        throw FileError.couldNotAccessResource
      }

      let data = try Data(contentsOf: url)
      url.stopAccessingSecurityScopedResource()
      return data
    }

    public mutating func startAccessingSecurityScopedURL() throws -> URL {
      let url = try url()
      guard url.startAccessingSecurityScopedResource() else {
        throw FileError.couldNotAccessResource
      }

      return url
    }
  }
#endif
