import Foundation

/// A thread-safe, lock-protected buffer for accumulating data from asynchronous process pipes.
///
/// `ProcessDataBuffer` is designed to be shared across readability-handler closures
/// that fire on arbitrary threads. All mutations are serialized through an `NSLock`.
public final class ProcessDataBuffer: @unchecked Sendable {
    private var data = Data()
    private let lock = NSLock()

    /// Creates an empty data buffer.
    public init() {}

    /// Appends a chunk of data to the buffer in a thread-safe manner.
    ///
    /// Empty chunks are ignored to avoid unnecessary locking.
    /// - Parameter chunk: The data to append.
    public func append(_ chunk: Data) {
        guard !chunk.isEmpty else { return }
        lock.lock()
        data.append(chunk)
        lock.unlock()
    }

    /// Returns a snapshot of the accumulated data.
    public func getData() -> Data {
        lock.lock()
        defer { lock.unlock() }
        return data
    }
}
