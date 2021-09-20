//
//  ListenerMessages.swift
//  Vox Connect
//
//  Created by Jayesh Mardiya on 31/05/20.
//  Copyright © 2020 Jayesh Mardiya. All rights reserved.
//

import Foundation

struct OfferMessage {
    let payload: RemoteSDP
    let src: String
    let type: String
}

extension OfferMessage {
    
    init(dictionary: Dictionary<String, Any>) throws {
        let payload = dictionary["payload"] as! [String: Any]
        let src = dictionary["src"] as! String
        let type = dictionary["type"] as! String
        let value = try RemoteSDP(dictionary: payload)
        self.init(payload: value, src: src, type: type)
    }
}

struct AnswerMessage {
    let to: String
    let sdp: RemoteAnswerSDP
    let sdpType: SdpType
}

extension AnswerMessage {
    
    init(dictionary: Dictionary<String, Any>) throws {
        let to = dictionary["to"] as! String
        let sdp = dictionary["sdp"] as! String
        //        let sdpType = dictionary["sdpType"] as! String
        
        let answerSDP = RemoteAnswerSDP(sdp: sdp, sdpType: .answer)
        self.init(to: to, sdp: answerSDP, sdpType: .answer)
    }
}

struct CandidateMessage {
    let candidate: RemoteCandidate
    let type: String
    let src: String?
}

extension CandidateMessage {
    
    init(dictionary: Dictionary<String, Any>) throws {
        
        let payload = dictionary["payload"] as! [String: Any]
        let src = dictionary["src"] as! String
        let type = dictionary["type"] as! String
        let value = try RemoteCandidate(dictionary: payload)
        self.init(candidate: value, type: type, src: src)
    }
}

enum Errors: Error {
    case parsingError
}

func throw_<T> (_ error: Error) throws -> T {
    throw error
}
