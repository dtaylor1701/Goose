//
//  Array+Sorted.swift
//
//
//  Created by David Taylor on 12/28/22.
//

import Foundation

public enum SortDirection {
  case ascending
  case descending
}

extension Array {
  public func sorted<U: Comparable>(
    by property: KeyPath<Element, U>, direction: SortDirection = .ascending
  ) -> [Element] {
    sorted {
      switch direction {
      case .ascending:
        return $0[keyPath: property] < $1[keyPath: property]
      case .descending:
        return $0[keyPath: property] > $1[keyPath: property]
      }
    }
  }
}

@propertyWrapper
public struct Sorted<T, U> where U: Comparable {
  private var value: [T]
  private let keyPath: KeyPath<T, U>
  private let direction: SortDirection

  public init(wrappedValue: [T], _ keyPath: KeyPath<T, U>, direction: SortDirection = .ascending) {
    self.value = wrappedValue
    self.keyPath = keyPath
    self.direction = direction
  }

  public var wrappedValue: [T] {
    get {
      value.sorted(by: keyPath, direction: direction)
    }
    set {
      value = newValue
    }
  }
}
