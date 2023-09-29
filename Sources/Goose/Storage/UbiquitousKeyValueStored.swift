//
//  File.swift
//  
//
//  Created by David Taylor on 8/13/23.
//

import Foundation

@available(watchOS 9.0, *)
@propertyWrapper
public struct UbiquitousKeyValueStored<T> where T: Codable {
    public let key: String
    public let defaultValue: T?
    public let userDefaults: UserDefaults

    public init(_ key: String, defaultValue: T?, userDefaults: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.userDefaults = userDefaults
    }
    
    public var wrappedValue: T? {
        get {
            guard let data = userDefaults.data(forKey: key),
                  let value = try? JSONDecoder().decode(T.self, from: data) else {
                return defaultValue
            }
            
            return value
        }
        set {
            if let data = try? JSONEncoder().encode(newValue){
                userDefaults.set(data, forKey: key)
                NSUbiquitousKeyValueStore.default.set(data, forKey: key)
            } else {
                userDefaults.removeObject(forKey: key)
                NSUbiquitousKeyValueStore.default.removeObject(forKey: key)
            }
        }
    }
    
    public func sync() {
        if let data = NSUbiquitousKeyValueStore.default.data(forKey: key) {
            userDefaults.set(data, forKey: key)
        } else {
            userDefaults.removeObject(forKey: key)
        }
    }
}
