import Foundation
import Testing
@testable import Goose

@Suite("ProcessRunner")
struct ProcessRunnerTests {
    @Test("Captures stdout, stderr, and exit code")
    func capturesOutput() async throws {
        let result = try await ProcessRunner.run(executablePath: "/bin/sh", arguments: ["-c", "echo out; echo err >&2; exit 3"])
        #expect(result.output == "out\n")
        #expect(result.errorOutput == "err\n")
        #expect(result.exitCode == 3)
        #expect(result.termination == .exited)
        #expect(!result.succeeded)
    }

    @Test("Output larger than a pipe buffer does not deadlock")
    func largeOutput() async throws {
        let result = try await ProcessRunner.run(executablePath: "/bin/sh", arguments: ["-c", "head -c 1000000 /dev/zero | tr '\\0' a"], timeout: 20)
        #expect(result.output.utf8.count == 1_000_000)
        #expect(result.succeeded)
    }

    @Test("Timeout terminates the process")
    func timeout() async throws {
        let start = ContinuousClock.now
        let result = try await ProcessRunner.run(executablePath: "/bin/sleep", arguments: ["30"], timeout: 0.3)
        #expect(result.termination == .timedOut)
        #expect(ContinuousClock.now - start < .seconds(5))
    }

    @Test("Cancelling the task terminates the process")
    func cancellation() async throws {
        let start = ContinuousClock.now
        let task = Task { try await ProcessRunner.run(executablePath: "/bin/sleep", arguments: ["30"]) }
        try await Task.sleep(for: .milliseconds(200))
        task.cancel()
        let result = try await task.value
        #expect(result.termination == .cancelled)
        #expect(ContinuousClock.now - start < .seconds(5))
    }

    @Test("A background child holding the pipes open does not hang the caller")
    func backgroundChild() async throws {
        let start = ContinuousClock.now
        let result = try await ProcessRunner.run(executablePath: "/bin/sh", arguments: ["-c", "echo started; sleep 30 &"], drainGracePeriod: 0.3)
        #expect(result.output == "started\n")
        #expect(ContinuousClock.now - start < .seconds(5))
    }

    @Test("Environment and working directory are applied")
    func environmentAndDirectory() async throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        let result = try await ProcessRunner.run(
            executablePath: "/bin/sh", arguments: ["-c", "echo $GOOSE_TEST; pwd -P"],
            currentDirectory: directory, environment: ["GOOSE_TEST": "hi", "PATH": "/bin:/usr/bin"]
        )
        let lines = result.output.split(separator: "\n").map(String.init)
        #expect(lines.first == "hi")
        #expect(lines.last == directory.canonicalFileURL?.path)
    }

    @Test("A missing executable throws")
    func missingExecutable() async {
        await #expect(throws: (any Error).self) {
            _ = try await ProcessRunner.run(executablePath: "/nonexistent/tool", arguments: [])
        }
    }

    @Test("Output is delivered to the handler as it arrives, before run returns")
    func streamsOutput() async throws {
        let received = ProcessDataBuffer()
        let errors = ProcessDataBuffer()
        let result = try await ProcessRunner.run(
            executablePath: "/bin/sh",
            arguments: ["-c", "echo one; sleep 0.2; echo two; echo oops >&2"]
        ) { chunk in
            (chunk.source == .standardOutput ? received : errors).append(chunk.data)
        }
        #expect(String(decoding: received.getData(), as: UTF8.self) == "one\ntwo\n")
        #expect(String(decoding: errors.getData(), as: UTF8.self) == "oops\n")
        #expect(result.output == "one\ntwo\n")
    }

    @Test("The first chunk arrives while the process is still running")
    func streamsBeforeExit() async throws {
        let start = ContinuousClock.now
        let arrival = LockedValue<Duration?>(nil)
        _ = try await ProcessRunner.run(executablePath: "/bin/sh", arguments: ["-c", "echo early; sleep 1"]) { _ in
            arrival.setIfNil(ContinuousClock.now - start)
        }
        let elapsed = try #require(arrival.value)
        #expect(elapsed < .milliseconds(900))
    }
}

/// A lock-protected value for recording from background callbacks.
private final class LockedValue<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: Value

    init(_ value: Value) { stored = value }

    var value: Value { lock.withLock { stored } }

    func setIfNil<Wrapped>(_ newValue: Wrapped) where Value == Wrapped? {
        lock.withLock { if stored == nil { stored = newValue } }
    }
}
