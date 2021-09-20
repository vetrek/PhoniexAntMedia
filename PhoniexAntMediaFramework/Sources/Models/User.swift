//
//  User.swift
//  VoW
//
//  Created by Jayesh Mardiya on 16/08/19.
//  Copyright © 2019 Jayesh Mardiya. All rights reserved.
//

import Foundation

struct UserInfo: Codable {
    let username: String
    let password: String
}

// Enum for UserType
public enum UserType: String {
    
    case listener
    case presenter
    case interpreter
}

extension UserType: Codable {
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        let rawValue = try container.decode(Int.self, forKey: .rawValue)
        switch rawValue {
        case 0:
            self = .listener
        case 1:
            self = .presenter
        case 2:
            self = .interpreter
        default:
            throw CodingError.unknownValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        switch self {
        case .listener:
            try container.encode(0, forKey: .rawValue)
        case .presenter:
            try container.encode(1, forKey: .rawValue)
        case .interpreter:
            try container.encode(2, forKey: .rawValue)
        }
    }
    
    enum Key: CodingKey {
        case rawValue
    }
    
    enum CodingError: Error {
        case unknownValue
    }
}
