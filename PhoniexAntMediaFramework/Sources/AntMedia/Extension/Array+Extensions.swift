//
//  Array+Extensions.swift
//  VoW
//
//  Created by Sumit Anantwar on 20/05/2019.
//  Copyright © 2019 Sumit Anantwar. All rights reserved.
//

import Foundation

extension Array where Element: Equatable {

    func item<T>(at index: Int) -> T? {
        if index < self.count {
            return self[index] as? T
        }
        return nil
    }
    
    func item(at index: Int) -> Element? {
        if index < self.count {
            return self[index]
        }
        
        return nil
    }
    
    mutating func remove(_ element: Element) {
        if let index = self.firstIndex(where: { $0 == element }) {
            self.remove(at: index)
        }
    }
}

extension Dictionary {
    func value(forKey key: Key) -> Value? {
        if self.keys.contains(key) {
            return self[key]
        }
        
        return nil
    }
    
    func toJsonData() -> Data? {
        return try? JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
    }
}
