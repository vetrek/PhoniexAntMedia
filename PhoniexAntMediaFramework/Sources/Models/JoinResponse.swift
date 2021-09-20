//
//  JoinResponse.swift
//  Vox Connect
//
//  Created by Jayesh Mardiya on 31/05/20.
//  Copyright © 2020 Jayesh Mardiya. All rights reserved.
//

import Foundation

struct ErrorStatus: Codable {
    let payload: ErrorPayload
    let type: String
    let to: String
    
    init(dictionary: [String: Any]) throws {
        self = try JSONDecoder().decode(ErrorStatus.self, from: JSONSerialization.data(withJSONObject: dictionary))
    }
}

struct ErrorPayload: Codable {
    let errorType: String
}

struct SpeakerStatus: Codable {
    let status: String
    let uuId: String?
    
    init(dictionary: [String: Any]) throws {
        self = try JSONDecoder().decode(SpeakerStatus.self, from: JSONSerialization.data(withJSONObject: dictionary))
    }
}

struct TwilioIceServer: Codable {
    let url: String
}

struct TwilioCreds: Codable {
    let ice_servers: [TwilioIceServer]
    let username: String
    let password: String
    
    func servers() -> [String] {
        return ice_servers.map { $0.url }
    }
}

struct ListenerJoinResponse: Codable {
    let speaker_status: SpeakerStatus
    let twilio_creds: TwilioCreds
    
    init(dictionary: [String: Any]) throws {
        let response = try dictionary["response"] as? [String: Any] ?? throw_(Errors.parsingError)
        self = try JSONDecoder().decode(ListenerJoinResponse.self, from: JSONSerialization.data(withJSONObject: response))
    }
}

struct SpeakerJoinResponse: Codable {
    let twilio_creds: TwilioCreds
    
    init(dictionary: [String: Any]) throws {
        let response = try dictionary["response"] as? [String: Any] ?? throw_(Errors.parsingError)
        self = try JSONDecoder().decode(SpeakerJoinResponse.self, from: JSONSerialization.data(withJSONObject: response))
    }
}
