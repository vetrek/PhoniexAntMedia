//
//  RemoteStreamingModel.swift
//  VoW
//
//  Created by Jayesh Mardiya on 19/06/20.
//  Copyright © 2020 Jayesh Mardiya. All rights reserved.
//

import Foundation
import WebRTC

enum RemoteMessage {
    case sdp(RemoteSDP)
    case candidate(RemoteCandidate)
    case listenerLimit
}

extension RemoteMessage {
    
    func toDictionary() -> [String : Any] {
        
        switch self {
        case .sdp(let sdp):
            return [
                "type": "sdp",
                "payload": sdp.toDictionary()
            ]
        case .candidate(let candidate):
            return [
                "type": "candidate",
                "payload": candidate.toDictionary()
            ]
        case .listenerLimit:
            return [
                "type": "error",
                "payload": ["errorType": "connections_limit_exceeded"],
            ]
        }
    }
}

struct RemoteSyn: Codable {
    
    let clientType: String
    let sourceId: String
}

struct RemoteSDP {
    let sdp: String
    let sdpType: SdpType
}

extension RemoteSDP: Codable {
    
    init(rtcSDP: RTCSessionDescription) {
        
        self.sdp = rtcSDP.sdp
        
        switch rtcSDP.type {
            case .answer: self.sdpType = .answer
            case .offer: self.sdpType = .offer
            case .prAnswer: self.sdpType = .prAnswer
            @unknown default:
                fatalError("Invalid RTCSDPType")
        }
    }
    
    func toDictionary() -> [String : String] {
        return [
            "sdp": self.sdp,
            "sdpType": self.sdpType.rawValue
        ]
    }
    
    func rtcSDP() -> RTCSessionDescription {
        return RTCSessionDescription(type: self.sdpType.rtcSdpType, sdp: self.sdp)
    }
    
    init(dictionary: [String: Any]) throws {
        self = try JSONDecoder().decode(
            RemoteSDP.self, from: JSONSerialization.data(withJSONObject: dictionary)
        )
    }
}

struct RemoteAnswerSDP {
    let sdp: String
    let sdpType: SdpType
}

extension RemoteAnswerSDP {
    
    init(rtcSDP: RTCSessionDescription) {
        
        self.sdp = rtcSDP.sdp
        
        switch rtcSDP.type {
            case .answer: self.sdpType = .answer
            case .offer: self.sdpType = .offer
            case .prAnswer: self.sdpType = .prAnswer
            @unknown default:
                fatalError("Invalid RTCSDPType")
        }
    }
    
    func toDictionary() -> [String : String] {
        return [
            "sdp": self.sdp,
            "sdpType": self.sdpType.rawValue
        ]
    }
    
    func rtcSDP() -> RTCSessionDescription {
        return RTCSessionDescription(type: self.sdpType.rtcSdpType, sdp: self.sdp)
    }
    
    init(dictionary: Dictionary<String, Any>) throws {
        let sdp = dictionary["sdp"] as! String
        self.init(sdp: sdp, sdpType: .answer)
    }
}

struct RemoteCandidate: Codable {
    let sdp: String
    let sdpMLineIndex: Int32
    let sdpMid: String?
}

extension RemoteCandidate {
    
    init(dictionary: [String: Any]) throws {
        self = try JSONDecoder().decode(
            RemoteCandidate.self, from: JSONSerialization.data(withJSONObject: dictionary)
        )
    }
    
    init(rtcICE: RTCIceCandidate) {
        self.sdp = rtcICE.sdp
        self.sdpMLineIndex = rtcICE.sdpMLineIndex
        self.sdpMid = rtcICE.sdpMid
    }
    
    func toDictionary() -> [String : Any] {
        return [
            "sdp": self.sdp,
            "sdpMLineIndex": self.sdpMLineIndex,
            "sdpMid": self.sdpMid ?? ""
        ]
    }
    
    func rtcCandidate() -> RTCIceCandidate {
        return RTCIceCandidate(sdp: self.sdp, sdpMLineIndex: self.sdpMLineIndex, sdpMid: sdpMid)
    }
}

struct RemoteSdpResponse: Codable {
    let src: String?
    let payload: RemoteSDP
    
    init(dictionary: [String: Any]) throws {
        self = try JSONDecoder().decode(
            RemoteSdpResponse.self, from: JSONSerialization.data(withJSONObject: dictionary)
        )
    }
}

struct RemoteCandidateResponse: Codable {
    let src: String?
    let payload: RemoteCandidate
    
    init(dictionary: [String: Any]) throws {
        self = try JSONDecoder().decode(
            RemoteCandidateResponse.self, from: JSONSerialization.data(withJSONObject: dictionary)
        )
    }
}

