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
public extension Array where Element: Identifiable {
    var ids: [Element.ID] {
        self.map { $0.id }
    }
    
    func index(of element: Element) -> Int? {
        firstIndex(where: { $0.id == element.id })
    }
    
    func item(with id: Element.ID) -> Element? {
        first(where: { $0.id == id })
    }
    
    func contains(id: Element.ID) -> Bool {
        contains(where: {$0.id == id})
    }
    
    mutating func delete(_ element: Element) {
        guard let index = index(of: element) else { return }
        
        remove(at: index)
    }
    
    mutating func update(_ element: Element) {
        guard let index = index(of: element) else { return }
        
        self[index] = element
    }
}
