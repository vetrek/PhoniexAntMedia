//
//  WebRTCModels.swift
//  VoW
//
//  Created by Sumit Anantwar on 23/12/2019.
//  Copyright © 2019 Jayesh Mardiya. All rights reserved.
//

import Foundation

struct SignalingMessage: Codable {
    let type: String
    let sessionDescription: LocalSDP?
    let candidate: LocalCandidate?
    let password: String?
    let allowRecording: Bool?
    let boxId: String?
    let error: ErrorPayload?
    
    init(type: String,
         sessionDescription: LocalSDP? = nil,
         candidate: LocalCandidate? = nil,
         password: String? = nil,
         allowRecording: Bool = false,
         error: ErrorPayload? = nil,
         boxId: String? = nil) {
        
        self.type = type
        self.sessionDescription = sessionDescription
        self.candidate = candidate
        self.password = password
        self.allowRecording = allowRecording
        self.error = error
        self.boxId = boxId
    }
}
