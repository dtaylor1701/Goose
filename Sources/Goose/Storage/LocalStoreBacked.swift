//
//  LocalStoreBacked.swift
//  
//
//  Created by David Taylor on 12/28/22.
//

import Foundation

@propertyWrapper
public struct LocalStoreBacked<T: Codable> {
    public let path: String
    public let defaultValue: T
    
    public var url: URL {
        LocalStore.documentsDirectory.appendingPathComponent(path)
    }
    
    private var memo: T?
    
    public var wrappedValue: T {
        get {
            if let memo = memo {
                return memo
            }
            
            return LocalStore.read(type: T.self, from: url) ?? defaultValue
        }
        set {
            LocalStore.write(item: newValue, to: url)
        }
    }
    
    public init(path: String, defaultValue: T) {
        self.path = path
        self.defaultValue = defaultValue
        self.memo = nil
    }
}
