//
//  File.swift
//  
//
//  Created by David Taylor on 8/13/23.
//

import Foundation

@propertyWrapper
public struct UbiquitousKeyValueStored<T> where T: Codable {
    public let key: String
    public let defaultValue: T?

    public init(_ key: String, defaultValue: T?) {
        self.key = key
        self.defaultValue = defaultValue
    }

    public var wrappedValue: T? {
        get {
            guard let data = UserDefaults.standard.data(forKey: key),
                  let value = try? JSONDecoder().decode(T.self, from: data) else {
                return defaultValue
            }
            
            return value
        }
        set {
            if let data = try? JSONEncoder().encode(newValue){
                UserDefaults.standard.set(data, forKey: key)
                NSUbiquitousKeyValueStore.default.set(data, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
                NSUbiquitousKeyValueStore.default.removeObject(forKey: key)
            }
        }
    }
    
    public func sync() {
        if let data = NSUbiquitousKeyValueStore.default.data(forKey: key),
           let value = try? JSONDecoder().decode(T.self, from: data) {
            UserDefaults.standard.set(value, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
