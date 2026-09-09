import Foundation

extension Double {
    /// Formats a floating-point number cleanly, omitting decimal places if it is a whole integer.
    public var formattedClean: String {
        if self == self.rounded() {
            return String(format: "%.0f", self)
        } else {
            return String(format: "%.2f", self)
        }
    }
}
