# Product Document: Goose

## 1. Product Vision & Core Objectives
**Goose** is a developer-centric Swift utility library designed to simplify the complexities of modern application development. Its vision is to provide a "standard library plus" experience, filling the critical gaps between Apple's Foundation/AppKit frameworks and the practical needs of building persistent, secure, and performant applications.

### Core Objectives:
*   **Bridge Persistence Gaps:** Enable seamless `Codable` support for system types that lack it (e.g., `CGColor`).
*   **Simplify Security Scoping:** Provide a robust, leak-proof abstraction for macOS security-scoped bookmarks.
*   **Reduce Boilerplate:** Offer high-level collection extensions that eliminate repetitive logic for sorting, updating, and identifying elements.
*   **Maintain Platform Idiomaticity:** Ensure all utilities feel like a natural extension of the Swift language and its modern concurrency model.

---

## 2. Target Audience & User Personas
Goose is built for **Swift Developers** ranging from independent app creators to enterprise engineering teams.

### User Personas:
*   **The SwiftUI Specialist:** Needs to manage `Identifiable` collections efficiently and wants to persist user-selected colors or settings without writing custom encoders.
*   **The macOS Developer:** Grapples with the complexities of the App Sandbox and needs a reliable way to maintain access to user-selected files across application restarts.
*   **The Performance Engineer:** Values lightweight, surgical utilities over heavy, all-encompassing frameworks that bloat binary size and increase complexity.

---

## 3. Feature Roadmap

### Short-Term (0-6 Months)
*   **Extended Persistence Wrappers:** Add `Codable` support for `NSAttributedString`, `UIFont/NSFont`, and `CGAffineTransform`.
*   **Advanced Collection Helpers:** Introduce `Dictionary` and `Set` extensions focused on merging and diffing.
*   **Enhanced Documentation:** Provide comprehensive DocC documentation with inline examples for every public API.

### Medium-Term (6-12 Months)
*   **Async File Operations:** Extend the `File` component to support `Swift Concurrency` for non-blocking I/O.
*   **Directory Monitoring:** A lightweight utility to observe changes in the file system for specific `File` references.
*   **Type-Safe UserDefaults:** A property wrapper system built on Goose's persistence wrappers for effortless settings management.

### Long-Term (12+ Months)
*   **Cross-Platform Sync Helpers:** Utilities to facilitate data synchronization across iCloud or other backends using Goose’s serializable models.
*   **State Management Utilities:** Lightweight abstractions for common state patterns in SwiftUI that complement the existing collection extensions.

---

## 4. Feature Prioritization
Goose prioritizes features based on the **"Utility-to-Boilerplate Ratio."**
*   **Core Priority (High):** Features that solve "impossible" problems (like `CGColor` persistence) or "risky" problems (like security-scoped resource management).
*   **Secondary Priority (Medium):** Features that reduce significant amounts of repetitive code (like `@Sorted` property wrappers).
*   **Tertiary Priority (Low):** Features that have existing, well-known solutions but could be made slightly more "Go
