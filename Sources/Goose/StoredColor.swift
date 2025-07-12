import CoreGraphics
import Foundation

public struct StoredColor: Codable {
  public var colorSpace: String
  public var components: [CGFloat]

  static let clear = StoredColor(colorSpace: String(CGColorSpace.sRGB), components: [0, 0, 0, 0])

  public var cgColor: CGColor {
    guard let cgColorSpace = CGColorSpace(name: colorSpace as CFString) else {
      return Self.clear.cgColor
    }
    return CGColor(colorSpace: cgColorSpace, components: components) ?? Self.clear.cgColor
  }

  public init(colorSpace: String?, components: [CGFloat]?) {
    self.colorSpace = colorSpace ?? String(CGColorSpace.sRGB)
    self.components = components ?? [1, 1, 1, 1]
  }

  public init(_ color: CGColor) {
    self.init(colorSpace: color.colorSpace?.name as? String, components: color.components)
  }
}
