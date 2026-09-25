import Foundation

#if os(macOS) || os(Linux) || os(Windows)

/// Runs external processes asynchronously and returns their captured output.
///
/// `ProcessRunner` wraps Foundation's `Process` with pipe-based output capture using
/// ``ProcessDataBuffer`` and bridges process termination into Swift Concurrency.
///
/// - Output is drained continuously while the process runs, so commands that print more
///   than a pipe buffer (~64 KB) never deadlock.
/// - Cancelling the calling task terminates the process (SIGTERM, then SIGKILL after a grace
///   period), as does exceeding `timeout`.
/// - After the process exits, output is collected until both pipes reach end-of-file or
///   `drainGracePeriod` elapses, so background children that inherit the pipes cannot hang
///   the caller.
/// - An optional `onOutput` handler receives output as it arrives. Every call to it happens
///   before `run` returns.
///
/// ```swift
/// let result = try await ProcessRunner.run(
///     executablePath: "/usr/bin/git",
///     arguments: ["status", "--porcelain"],
///     currentDirectory: repoURL
/// )
/// ```
public struct ProcessRunner: Sendable {
    /// The captured output of a completed process.
    public struct Result: Sendable, Equatable {
        /// The process exit code (or signal number when terminated by a signal).
        public let exitCode: Int32

        /// The UTF-8 decoded contents of standard output.
        public let output: String

        /// The UTF-8 decoded contents of standard error.
        public let errorOutput: String

        /// Why the process stopped.
        public let termination: Termination

        public init(exitCode: Int32, output: String, errorOutput: String, termination: Termination = .exited) {
            self.exitCode = exitCode
            self.output = output
            self.errorOutput = errorOutput
            self.termination = termination
        }

        /// Whether the process exited normally with status zero.
        public var succeeded: Bool { termination == .exited && exitCode == 0 }
    }

    /// A piece of output read from one of the process's pipes.
    public struct OutputChunk: Sendable, Equatable {
        /// The pipe a chunk was read from.
        public enum Source: Sendable, Equatable {
            case standardOutput
            case standardError
        }

        public let source: Source
        public let data: Data

        public init(source: Source, data: Data) {
            self.source = source
            self.data = data
        }
    }

    /// Receives output while a process runs. Called on a background thread, one chunk at a
    /// time per pipe, so it should return quickly.
    public typealias OutputHandler = @Sendable (OutputChunk) -> Void

    /// How a process run ended.
    public enum Termination: Sendable, Equatable {
        /// The process exited on its own.
        case exited
        /// The process was stopped because it exceeded its timeout.
        case timedOut
        /// The process was stopped because the calling task was cancelled.
        case cancelled
    }

    /// Runs an external process and returns its captured output.
    ///
    /// - Parameters:
    ///   - executablePath: Absolute path to the executable (e.g. `"/usr/bin/git"`).
    ///   - arguments: Command-line arguments passed to the process.
    ///   - currentDirectory: Optional working directory. When `nil`, inherits the parent process directory.
    ///   - environment: Optional environment. When `nil`, inherits the parent process environment.
    ///   - timeout: Seconds after which the process is terminated. `nil` waits indefinitely.
    ///   - drainGracePeriod: Seconds to keep collecting output after exit while waiting for end-of-file.
    ///   - onOutput: Receives output as it arrives; the returned ``Result`` still contains all of it.
    /// - Returns: A ``Result`` containing the exit code, captured output streams, and termination reason.
    /// - Throws: Any error thrown by `Process.run()` (e.g. executable not found).
    public static func run(
        executablePath: String,
        arguments: [String],
        currentDirectory: URL? = nil,
        environment: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        drainGracePeriod: TimeInterval = 1.0,
        onOutput: OutputHandler? = nil
    ) async throws -> Result {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        if let currentDirectory {
            process.currentDirectoryURL = currentDirectory
        }
        if let environment {
            process.environment = environment
        }
        process.standardInput = FileHandle.nullDevice

        let run = ProcessRun(process: process, drainGracePeriod: drainGracePeriod, onOutput: onOutput)

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                run.start(timeout: timeout, continuation: continuation)
            }
        } onCancel: {
            run.stop(reason: .cancelled)
        }
    }
}

/// Coordinates one process launch: output draining, termination, and resuming the caller once.
private final class ProcessRun: @unchecked Sendable {
    private let process: Process
    private let drainGracePeriod: TimeInterval
    private let outPipe = Pipe()
    private let errorPipe = Pipe()
    private let outBuffer = ProcessDataBuffer()
    private let errorBuffer = ProcessDataBuffer()
    private let onOutput: ProcessRunner.OutputHandler?
    /// Serializes delivery to `onOutput` with finishing, so no chunk is delivered after `run` returns.
    private let deliveryLock = NSLock()
    private var isDelivering = true

    private let lock = NSLock()
    private var continuation: CheckedContinuation<ProcessRunner.Result, Error>?
    private var outputClosed = false
    private var errorClosed = false
    private var hasExited = false
    private var stopReason: ProcessRunner.Termination?
    private var isFinished = false

    init(process: Process, drainGracePeriod: TimeInterval, onOutput: ProcessRunner.OutputHandler?) {
        self.process = process
        self.drainGracePeriod = drainGracePeriod
        self.onOutput = onOutput
        process.standardOutput = outPipe
        process.standardError = errorPipe
    }

    func start(timeout: TimeInterval?, continuation: CheckedContinuation<ProcessRunner.Result, Error>) {
        lock.withLock { self.continuation = continuation }

        outPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            self?.receive(handle.availableData, isOutput: true)
        }
        errorPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            self?.receive(handle.availableData, isOutput: false)
        }
        process.terminationHandler = { [weak self] _ in
            self?.processDidExit()
        }

        do {
            try process.run()
        } catch {
            outPipe.fileHandleForReading.readabilityHandler = nil
            errorPipe.fileHandleForReading.readabilityHandler = nil
            let pending = lock.withLock { () -> CheckedContinuation<ProcessRunner.Result, Error>? in
                isFinished = true
                defer { self.continuation = nil }
                return self.continuation
            }
            pending?.resume(throwing: error)
            return
        }

        // A cancellation that raced ahead of launch is applied now that there is a process.
        if lock.withLock({ stopReason != nil }) {
            terminate()
        }
        if let timeout {
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { [weak self] in
                self?.stop(reason: .timedOut)
            }
        }
    }

    /// Terminates the process, recording why. Safe to call before launch or after exit.
    func stop(reason: ProcessRunner.Termination) {
        let shouldTerminate = lock.withLock { () -> Bool in
            guard stopReason == nil, !hasExited else { return false }
            stopReason = reason
            return true
        }
        if shouldTerminate { terminate() }
    }

    private func terminate() {
        guard process.isRunning else { return }
        process.terminate()
        let pid = process.processIdentifier
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) { [process] in
            if process.isRunning { kill(pid, SIGKILL) }
        }
    }

    private func receive(_ chunk: Data, isOutput: Bool) {
        if chunk.isEmpty {
            (isOutput ? outPipe : errorPipe).fileHandleForReading.readabilityHandler = nil
            let ready = lock.withLock { () -> Bool in
                if isOutput { outputClosed = true } else { errorClosed = true }
                return hasExited && outputClosed && errorClosed
            }
            if ready { finish() }
        } else {
            deliveryLock.withLock {
                guard isDelivering else { return }
                (isOutput ? outBuffer : errorBuffer).append(chunk)
                onOutput?(ProcessRunner.OutputChunk(source: isOutput ? .standardOutput : .standardError, data: chunk))
            }
        }
    }

    private func processDidExit() {
        let ready = lock.withLock { () -> Bool in
            hasExited = true
            return outputClosed && errorClosed
        }
        if ready {
            finish()
        } else {
            // Background children may hold the pipes open; don't wait on them forever.
            DispatchQueue.global().asyncAfter(deadline: .now() + drainGracePeriod) { [weak self] in
                self?.finish()
            }
        }
    }

    private func finish() {
        let pending = lock.withLock { () -> CheckedContinuation<ProcessRunner.Result, Error>? in
            guard !isFinished else { return nil }
            isFinished = true
            defer { continuation = nil }
            return continuation
        }
        guard let pending else { return }

        outPipe.fileHandleForReading.readabilityHandler = nil
        errorPipe.fileHandleForReading.readabilityHandler = nil
        // Waits for any chunk being delivered, then drops later ones, so the result and the
        // handler see the same output.
        deliveryLock.withLock { isDelivering = false }
        let reason = lock.withLock { stopReason } ?? .exited
        pending.resume(returning: ProcessRunner.Result(
            exitCode: process.terminationStatus,
            output: String(decoding: outBuffer.getData(), as: UTF8.self),
            errorOutput: String(decoding: errorBuffer.getData(), as: UTF8.self),
            termination: reason
        ))
    }
}

#endif
