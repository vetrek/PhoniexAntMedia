//
//  RemoteStreamingModel.swift
//  VoW
//
//  Created by Jayesh Mardiya on 19/06/20.
//  Copyright © 2020 Jayesh Mardiya. All rights reserved.
//

import Foundation
import WebRTC

public enum RemoteMessage {
    case sdp(RemoteSDP)
    case candidate(RemoteCandidate)
    case listenerLimit
}

extension RemoteMessage {
    
    public func toDictionary() -> [String : Any] {
        
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

public struct RemoteSDP {
    let sdp: String
    let sdpType: SdpType
    
    enum CodingKeys: String, CodingKey {
        case sdp
        case sdpType
    }
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sdp, forKey: .sdp)
        try container.encode(sdpType, forKey: .sdpType)
    }
    
    public init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        sdp = try values.decode(String.self, forKey: .sdp)
        sdpType = try values.decode(SdpType.self, forKey: .sdpType)
    }
}

extension RemoteSDP: Codable {
    
    public init(rtcSDP: RTCSessionDescription) {
        
        self.sdp = rtcSDP.sdp
        
        switch rtcSDP.type {
        case .answer: self.sdpType = .answer
        case .offer: self.sdpType = .offer
        case .prAnswer: self.sdpType = .prAnswer
        @unknown default:
            fatalError("Invalid RTCSDPType")
        }
    }
    
    public func toDictionary() -> [String : String] {
        return [
            "sdp": self.sdp,
            "sdpType": self.sdpType.rawValue
        ]
    }
    
    public func rtcSDP() -> RTCSessionDescription {
        return RTCSessionDescription(type: self.sdpType.rtcSdpType, sdp: self.sdp)
    }
    
    public init(dictionary: [String: Any]) throws {
        self = try JSONDecoder().decode(
            RemoteSDP.self, from: JSONSerialization.data(withJSONObject: dictionary)
        )
    }
}

public struct RemoteAnswerSDP {
    public var sdp: String
    public var sdpType: SdpType
}

extension RemoteAnswerSDP {
    
    public init(rtcSDP: RTCSessionDescription) {
        
        self.sdp = rtcSDP.sdp
        
        switch rtcSDP.type {
        case .answer: self.sdpType = .answer
        case .offer: self.sdpType = .offer
        case .prAnswer: self.sdpType = .prAnswer
        @unknown default:
            fatalError("Invalid RTCSDPType")
        }
    }
    
    public func toDictionary() -> [String : String] {
        return [
            "sdp": self.sdp,
            "sdpType": self.sdpType.rawValue
        ]
    }
    
    public func rtcSDP() -> RTCSessionDescription {
        return RTCSessionDescription(type: self.sdpType.rtcSdpType, sdp: self.sdp)
    }
    
    public init(dictionary: Dictionary<String, Any>) throws {
        let sdp = dictionary["sdp"] as! String
        self.init(sdp: sdp, sdpType: .answer)
    }
    
    public init(with sdp: String, and sdpType: SdpType) {
        self.init(sdp: sdp, sdpType: sdpType)
    }
}

public struct RemoteCandidate: Codable {
    public var sdp: String
    public var sdpMLineIndex: Int32
    public var sdpMid: String?
}

extension RemoteCandidate {
    
    public init(dictionary: [String: Any]) throws {
        self = try JSONDecoder().decode(
            RemoteCandidate.self, from: JSONSerialization.data(withJSONObject: dictionary)
        )
    }
    
    public init(rtcICE: RTCIceCandidate) {
        self.sdp = rtcICE.sdp
        self.sdpMLineIndex = rtcICE.sdpMLineIndex
        self.sdpMid = rtcICE.sdpMid
    }
    
    public func toDictionary() -> [String : Any] {
        return [
            "sdp": self.sdp,
            "sdpMLineIndex": self.sdpMLineIndex,
            "sdpMid": self.sdpMid ?? ""
        ]
    }
    
    public func rtcCandidate() -> RTCIceCandidate {
        return RTCIceCandidate(sdp: self.sdp, sdpMLineIndex: self.sdpMLineIndex, sdpMid: sdpMid)
    }
}

public struct RemoteSdpResponse: Codable {
    public var src: String?
    public var payload: RemoteSDP
    
    public init(dictionary: [String: Any]) throws {
        self = try JSONDecoder().decode(
            RemoteSdpResponse.self, from: JSONSerialization.data(withJSONObject: dictionary)
        )
    }
}

public struct RemoteCandidateResponse: Codable {
    public var src: String?
    public var payload: RemoteCandidate
    
    public init(dictionary: [String: Any]) throws {
        self = try JSONDecoder().decode(
            RemoteCandidateResponse.self, from: JSONSerialization.data(withJSONObject: dictionary)
        )
    }
}
