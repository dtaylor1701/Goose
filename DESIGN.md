# Design Document: Goose

## 1. Executive Summary
**Goose** is a lightweight, utility-driven Swift library designed to bridge the gap between standard Foundation/AppKit types and the requirements of modern, persistent, and sandboxed applications. It provides a suite of tools for data persistence, secure file management, and enhanced collection handling.

## 2. High-Level Architecture
Goose follows a modular utility architecture, organized into three primary functional areas:
- **Persistence Wrappers:** `Codable` abstractions for non-serializable system types (e.g., `CGColor`).
- **Secure Resource Management:** Security-scoped bookmarking for persistent file access in sandboxed environments.
- **Syntactic Sugar & Extensions:** Type-safe enhancements for Swift’s standard library collections, particularly focusing on `Identifiable` and `Comparable` protocols.

## 3. Core Design Philosophies
- **Type Safety:** Leverage Swift's type system (KeyPaths, Generics) to provide compile-time guarantees for operations like sorting and identifying elements.
- **Persistence First:** Every component is designed with `Codable` support where applicable, ensuring compatibility with JSON and property list storage.
- **Surgical Utility:** Avoid bloated frameworks; provide only targeted extensions that solve specific, common pain points in Swift development.
- **Platform Idiomaticity:** Adhere to Apple’s security-scoped resource patterns and Swift naming conventions.

## 4. Technical Stack
- **Language:** Swift 5.7+
- **Build System:** Swift Package Manager (SPM)
- **Frameworks:** Foundation, CoreGraphics
- **Platforms:** macOS (Primary focus for `File`), iOS, watchOS (General utilities)

## 5. Key Components & API Design

### 5.1 StoredColor
A `Codable` wrapper for `CGColor`. Standard `CGColor` does not conform to `Codable`, making it difficult to persist in models. `StoredColor` solves this by storing the color space name and its components.
- **API:** 
    - `init(_ color: CGColor)`
    - `var cgColor: CGColor { get }`
- **Use Case:** Storing user-selected colors in a JSON configuration file or `UserDefaults`.

### 5.2 File (macOS Specific)
A robust implementation of security-scoped bookmarks. Essential for macOS apps that need to remember user-selected files across application launches while operating within a sandbox.
- **API:**
    - `init(at url: URL) throws`: Creates a bookmark and manages security-scope entry/exit.
    - `func url() throws -> URL`: Resolves and refreshes stale bookmarks automatically.
    - `func data() throws -> Data`: Direct access to file contents with managed resource scope.
- **Model:** Encapsulates `Data` (the bookmark) and ensures `startAccessingSecurityScopedResource()` is called correctly.

### 5.3 Array Extensions
#### Array+Identifiable
Streamlines operations on arrays containing `Identifiable` elements (standard in SwiftUI).
- **Features:** 
    - Extraction of IDs: `array.ids`
    - Safe updates: `array.update(item)`
    - Targeted deletion: `array.delete(item)`
    - Item retrieval: `array.item(with: id)`

#### Array+Sorted
Provides KeyPath-based sorting and a `@Sorted` property wrapper.
- **Features:**
    - `sorted(by: \.propertyName, direction: .ascending)`
    - `@Sorted(\.name) var users: [User]` property wrapper to maintain order automatically.

## 6. Technical Specifications

### 6.1 Data Persistence
Persistence is achieved through `Codable` conformance. Components like `StoredColor` and `File` act as bridge types between system-level objects and serializable data structures.

### 6.2 Error Handling
Goose uses Swift's native `Error` protocol. The `File` component, specifically, defines `FileError.couldNotAccessResource` to handle sandbox-related failures during bookmark resolution.

### 6.3 Concurrency Model
The library is designed to be thread-safe where possible. The `File` struct conforms to `Sendable`, ensuring it can be safely passed between actors in modern Swift concurrency.

## 7. Testing Infrastructure
The project employs **XCTest** for validation, located in the `Tests/` directory.
- **Unit Testing:** Focuses on logic for sorting, ID management, and color conversions.
- **Integration Testing:** (Planned) Validating bookmark persistence across simulated app cycles (macOS).
- **Strategy:** Every new extension must include a corresponding test suite (e.g., `Array+SortedTests.swift`) to prevent regressions in collection logic.

## 8. Security & Performance
- **Security:** The `File` component strictly follows Apple's security-scoped bookmark guidelines, preventing resource leaks by ensuring every "start" has a corresponding "stop" in the lifecycle.
- **Performance:** Array extensions are optimized for standard library performance, utilizing native indices and high-order functions to minimize overhead. Property wrappers like `@Sorted` are computed lazily or on-demand to avoid unnecessary sorting operations.
