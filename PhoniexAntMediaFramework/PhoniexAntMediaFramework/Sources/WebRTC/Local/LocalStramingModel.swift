//
//  LocalStramingModel.swift
//  VoW
//
//  Created by Jayesh Mardiya on 19/06/20.
//  Copyright © 2020 Jayesh Mardiya. All rights reserved.
//

import Foundation
import WebRTC

struct LocalSDP : Codable {
    let sdp: String
}

struct LocalCandidate: Codable {
    let sdp: String
    let sdpMLineIndex: Int32
    let sdpMid: String?
}
