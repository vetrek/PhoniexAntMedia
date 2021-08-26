//
//  Int+Extensions.swift
//  popguide
//
//  Created by Sumit Anantwar on 22/12/2018.
//  Copyright © 2019 Populi Ltd. All rights reserved.
//

import Foundation

extension Int {
    
    func toString() -> String {
        return String(self)
    }
}

extension Date {
    func toString(format: String) -> String {
        let dateformat = DateFormatter()
        dateformat.dateFormat = format
        return dateformat.string(from: self)
    }
}

extension Data {
    var array: [UInt8] { return Array(self) }
}

extension UInt32 {
    var data: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout<UInt32>.size)
    }
}

extension UInt16 {
    var data: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout<UInt16>.size)
    }
}

extension Int {
    var data: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout<Int>.size)
    }
}

extension Dictionary {
    var jsonStringRepresentation: String? {
        guard let theJSONData = try? JSONSerialization.data(withJSONObject: self,
                                                            options: [.prettyPrinted]) else {
            return nil
        }

        return String(data: theJSONData, encoding: .ascii)
    }
}
