//
//  Array+Sorted.swift
//  
//
//  Created by David Taylor on 12/28/22.
//

import Foundation

public extension Array {
    func sorted<U: Comparable>(by property: KeyPath<Element, U>) -> Array<Element> {
        sorted {
            $0[keyPath: property] < $1[keyPath: property]
        }
    }
}
