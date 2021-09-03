//
//  ClientListener.swift
//  TCP_Socket_POC
//
//  Created by Jayesh Mardiya on 18/01/20.
//  Copyright © 2020 Sumit's Inc. All rights reserved.
//

import UIKit
import WebRTC
import CocoaAsyncSocket

public class ClientListener: ClientBase {

    private lazy var localAudioTrack: RTCAudioTrack = {
        let audioConstrains = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = self.peerConnectionFactory.audioSource(with: audioConstrains)
        let audioTrack = self.peerConnectionFactory.audioTrack(with: audioSource, trackId: "audio0")
        return audioTrack
    }()
        
    private let password: String?
    private let allowRecording: Bool
    private let currentConnectedClient: Int
    private let maxConnectClient: Int
    private let box_id: String
    
    init(socket: GCDAsyncSocket, password: String? = nil, allowRecording: Bool = false, currentConnectedClient: Int, maxConnectClient: Int, box_id: String) {
        
        self.password = password
        self.allowRecording = allowRecording
        self.maxConnectClient = maxConnectClient
        self.currentConnectedClient = currentConnectedClient
        self.box_id = box_id
        
        super.init(socket: socket, and: "presenter")
    }
    
    // MARK: Connect
    override func connect() {
        
        self.peerConnection.add(localAudioTrack, streamIds: ["stream0"])
        self.makeOffer { offerSdp in
            self.sendOffer(with: self.box_id, sessionDescription: offerSdp, password: self.password, allowRecording: self.allowRecording)
        }
    }
    
    // MARK: - Signaling Offer/Answer
    private func makeOffer(onSuccess: @escaping (RTCSessionDescription) -> Void) {
        self.peerConnection.offer(for: RTCMediaConstraints.init(mandatoryConstraints: nil, optionalConstraints: nil)) { (sdp, err) in
            if let error = err {
                print("error with make offer")
                print(error)
                return
            }
            
            if let offerSDP = sdp {
                print("make offer, created local sdp")
                self.peerConnection.setLocalDescription(offerSDP, completionHandler: { (err) in
                    if let error = err {
                        print("error with set local offer sdp")
                        print(error)
                        return
                    }
                    print("succeed to set local offer SDP")
                    onSuccess(offerSDP)
                })
            }
        }
    }
}
