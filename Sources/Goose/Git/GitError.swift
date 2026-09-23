import Foundation

/// Errors raised by ``GitRepository``.
public enum GitError: LocalizedError, Equatable, Sendable {
    /// `git` ran and exited unsuccessfully.
    case commandFailed(arguments: [String], exitCode: Int32, message: String)
    /// `git` was stopped before finishing (timeout or cancellation).
    case interrupted(arguments: [String])

    public var errorDescription: String? {
        switch self {
        case .commandFailed(let arguments, let code, let message):
            let detail = message.trimmingCharacters(in: .whitespacesAndNewlines)
            return "git \(arguments.joined(separator: " ")) failed (exit \(code))" + (detail.isEmpty ? "." : ": \(detail)")
        case .interrupted(let arguments):
            return "git \(arguments.joined(separator: " ")) was interrupted."
        }
    }
}
