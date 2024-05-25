//
//  StoredColor.swift
//  Storeshot
//
//  Created by David Taylor on 5/19/24.
//

import Foundation
import CoreGraphics

public struct StoredColor: Codable {
  public var colorSpace: String
  public var components: [CGFloat]
  
  public var cgColor: CGColor {
    guard let cgColorSpace = CGColorSpace(name: colorSpace as CFString) else {
      return .clear
    }
    return CGColor(colorSpace: cgColorSpace, components: components) ?? .clear
  }
  
  public init(colorSpace: String?, components: [CGFloat]?) {
    self.colorSpace = colorSpace ?? String(CGColorSpace.sRGB)
    self.components = components ?? [1, 1, 1, 1]
  }
  
  public init(_ color: CGColor) {
    self.init(colorSpace: color.colorSpace?.name as? String, components: color.components)
  }
}
