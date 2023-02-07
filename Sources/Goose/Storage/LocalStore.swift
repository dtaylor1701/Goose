//
//  LocalStore.swift
//  
//
//  Created by David Taylor on 12/28/22.
//

import Foundation

public class LocalStore {
    public static let documentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first! // This should always succeed

    public static func write<T>(item: T, to path: URL) where T: Encodable {
        do {
            let data = try JSONEncoder().encode(item)
            try data.write(to: path)
        } catch {
            print("Save Failed")
        }
    }

    public static func read<T>(type: T.Type, from path: URL) -> T? where T: Decodable {
        do {
            let data = try Data(contentsOf: path)
            let item = try JSONDecoder().decode(T.self, from: data)
            return item
        } catch {
            print("Retrieve Failed")
            return nil
        }
    }
}
