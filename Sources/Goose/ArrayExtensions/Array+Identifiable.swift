//
//  Array+Identifiable.swift
//
//
//  Created by David Taylor on 12/28/22.
//

import Foundation

@available(macOS 10.15, *)
@available(iOS 13.0, *)
@available(watchOS 6.0, *)
extension Array where Element: Identifiable {
  public var ids: [Element.ID] {
    self.map { $0.id }
  }

  public func index(of element: Element) -> Int? {
    firstIndex(where: { $0.id == element.id })
  }

  public func item(with id: Element.ID) -> Element? {
    first(where: { $0.id == id })
  }

  public func contains(id: Element.ID) -> Bool {
    contains(where: { $0.id == id })
  }

  public mutating func delete(_ element: Element) {
    guard let index = index(of: element) else { return }

    remove(at: index)
  }

  public mutating func update(_ element: Element) {
    guard let index = index(of: element) else { return }

    self[index] = element
  }
}
