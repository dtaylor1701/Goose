# Goose

Goose is a lightweight, utility-driven Swift library designed to bridge the gap between standard Foundation/AppKit types and the requirements of modern, persistent, and sandboxed applications. It provides a suite of tools for data persistence, secure file management, and enhanced collection handling.

## Core Features

### 🛠 Persistence Wrappers
Simplify the persistence of system types that do not natively conform to `Codable`.
- **`StoredColor`**: A `Codable` wrapper for `CGColor`, allowing you to easily store user-selected colors in JSON or `UserDefaults`.

### 📂 Secure Resource Management
Robust abstractions for macOS security-scoped bookmarks, essential for sandboxed applications.
- **`File`**: Manages the lifecycle of security-scoped bookmarks, ensuring resources are accessed and released correctly across application restarts.

### 🍭 Syntactic Sugar & Extensions
Type-safe enhancements for Swift’s standard library collections, focusing on `Identifiable` and `Comparable` protocols.
- **`Array+Identifiable`**: Streamlines operations like safe updates, targeted deletion, and ID extraction for arrays of `Identifiable` elements.
- **`Array+Sorted`**: Provides KeyPath-based sorting and a `@Sorted` property wrapper to maintain collection order automatically.
- **`String.addingQueryValueEncoding()`**: Percent-encodes one URL query value, always escaping `+ & = # ?` (unlike `.urlQueryAllowed`), so values survive both Foundation and `URLSearchParams` decoding.

### 📁 Paths, Ignore Files & JSON
- **`URL.relativePath(from:)`** / **`isContained(in:)`**: A file's path relative to a root after resolving `..` and symlinks (`nil` when it's outside), so paths can't pretend to be inside a folder.
- **`IgnoreRules`**: Matches paths against `.gitignore`-syntax patterns (negation, anchoring, `**`, character classes), returning `nil` when no pattern decides so callers can cascade folder by folder.
- **`String.canonicalJSON`** / **`prettyPrintedJSON`**: Re-serialise JSON with sorted keys, compactly (so equal values compare equal) or indented.

### 🧭 Environment
- **`DeveloperEnvironment`**: Augments the minimal `PATH` that Finder-launched apps receive so they find Homebrew and version-manager tools.

## Installation

### Swift Package Manager

Add Goose to your project by including it in your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/your-repo/Goose.git", from: "1.0.0")
]
```

Then, add `Goose` as a dependency for your target:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["Goose"]
    )
]
```

## Usage

### Storing Colors
```swift
import Goose
import CoreGraphics

let color = CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
let storedColor = StoredColor(color)

// Encode to JSON
let data = try JSONEncoder().encode(storedColor)

// Decode and retrieve CGColor
let decoded = try JSONDecoder().decode(StoredColor.self, from: data)
let cgColor = decoded.cgColor
```

### Security-Scoped Files
```swift
import Goose

// Create a persistent reference to a user-selected file
let file = try File(at: selectedURL)

// Access file data (automatically updates bookmark if stale)
var file = try File(at: selectedURL)
let data = try file.data()

// Perform complex operations safely with closure-based access
try await file.withURL { url in
    // URL is automatically accessed here
    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
    // ...
}

### Using with Actors

Because `File` is a `struct` with `mutating` methods that update its internal bookmark, you cannot call them directly on actor properties. Instead, use the **Copy-Modify-Assign** pattern:

```swift
actor FileStore {
    var file: File
    
    func process() async throws {
        var fileCopy = self.file // Create local copy
        try await fileCopy.withURL { url in 
            // ...
        }
        self.file = fileCopy // Re-assign updated bookmark
    }
}
```
```

### Sorted Collections
```swift
import Goose

struct User: Identifiable {
    let id: UUID
    let name: String
}

@Sorted(\.name) var users: [User] = []
users.append(User(id: UUID(), name: "Charlie"))
users.append(User(id: UUID(), name: "Alice"))

// 'users' is automatically sorted: ["Alice", "Charlie"]
```

## Dependencies

Goose is designed to be lightweight and has **zero external dependencies**. It relies solely on Apple's standard frameworks:
- Foundation
- CoreGraphics

## Requirements
- Swift 5.7+
- macOS 10.15+ / iOS 13.0+ (General utilities)
- macOS 11.0+ (Specific `File` security-scoped features)
