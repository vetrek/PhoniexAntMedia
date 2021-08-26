//
//  Codable+Extensions.swift
//  popguide
//
//  Created by Sumit Anantwar on 22/12/2018.
//  Copyright © 2018 Populi Ltd. All rights reserved.
//

import Foundation

extension Encodable {
    func toJSONData() -> Data? {
        return try? JSONEncoder().encode(self)
    }
}

extension Encodable {
    func encode() throws -> Data {
        return try JSONEncoder().encode(self)
    }
}

extension Data {
    func decode<T: Decodable>() throws -> T {
        return try JSONDecoder().decode(T.self, from: self)
    }
}
