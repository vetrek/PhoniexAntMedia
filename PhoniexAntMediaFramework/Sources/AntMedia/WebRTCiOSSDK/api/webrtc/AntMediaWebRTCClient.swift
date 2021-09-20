//
//  AntMediaWebRTCClient.swift
//  AntMediaSDK
//
//  Created by Oğulcan on 6.06.2018.
//  Copyright © 2018 AntMedia. All rights reserved.
//

import Foundation
import AVFoundation
import WebRTC
import ReplayKit

class AntMediaWebRTCClient: NSObject {

    let AUDIO_TRACK_ID = "AUDIO"
    let LOCAL_MEDIA_STREAM_ID = "STREAM"
    
    private static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        return RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
    }()
    
    var delegate: AntMediaWebRTCClientDelegate?
    var peerConnection: RTCPeerConnection?
    
    var localAudioTrack: RTCAudioTrack!
    var remoteAudioTrack: RTCAudioTrack!
    var dataChannel: RTCDataChannel?
    
    private var token: String!
    private var streamId: String!
    private var userType: UserType = .listener

    private var audioEnabled: Bool = true
    private var config = AntMediaConfig.init()
    private var mode: AntMediaClientMode = AntMediaClientMode.join
    
    public init(delegate: AntMediaWebRTCClientDelegate) {
        super.init()
        
        self.delegate = delegate
        
        RTCPeerConnectionFactory.initialize()
        
        let stunServer = config.defaultStunServer()
        let defaultConstraint = config.createDefaultConstraint()
        let configuration = config.createConfiguration(server: stunServer)
        
        self.peerConnection = AntMediaWebRTCClient.factory.peerConnection(with: configuration, constraints: defaultConstraint, delegate: self)
    }
    
    public convenience init(delegate: AntMediaWebRTCClientDelegate, mode: AntMediaClientMode, userType: UserType) {
        self.init(delegate: delegate,
                  mode: mode, multiPeerActive:false, enableDataChannel: true, userType: userType)
    }
    public convenience init(delegate: AntMediaWebRTCClientDelegate, mode: AntMediaClientMode, multiPeerActive: Bool, enableDataChannel: Bool, userType: UserType) {
        
        self.init(delegate: delegate)
        self.mode = mode
        self.userType = userType
        
        if (self.mode != .play && !multiPeerActive) {
            if userType != .listener {

            }
            
            let addedStream = self.addLocalMediaStream()
            print(addedStream)
        }
        
        if enableDataChannel && self.mode == .publish {
            // in publish mode, client opens the data channel
        }
        
        self.dataChannel = self.createDataChannel()
        self.dataChannel?.delegate = self
    }
    
    public func getStats(handler: @escaping (RTCStatisticsReport) -> Void) {
        self.peerConnection?.statistics(completionHandler: handler);
    }
    
    public func setStreamId(_ streamId: String) {
        self.streamId = streamId
    }
    
    public func setToken(_ token: String) {
        self.token = token
    }
    
    public func setRemoteDescription(_ description: RTCSessionDescription) {
        self.peerConnection?.setRemoteDescription(description, completionHandler: {
            (error) in
            if (error != nil) {
                AntMediaClient.printf("Error (setRemoteDescription): " + error!.localizedDescription + " debug description: " + error.debugDescription)
                
            }
        })
    }
    
    public func addCandidate(_ candidate: RTCIceCandidate) {
        self.peerConnection?.add(candidate)
    }
    
    public func sendData(data: Data, binary: Bool = false) {
        if (self.dataChannel?.readyState == .open) {
            let dataBuffer = RTCDataBuffer.init(data: data, isBinary: binary);
            self.dataChannel?.sendData(dataBuffer);
        } else {
            AntMediaClient.printf("Data channel is nil or state is not open. State is \(String(describing: self.dataChannel?.readyState)) Please check that data channel is enabled in server side ")
        }
    }
    
    public func isDataChannelActive() -> Bool {
        return self.dataChannel?.readyState == .open;
    }

    
    public func sendAnswer() {
        let constraint = self.config.createAudioVideoConstraints()
        self.peerConnection?.answer(for: constraint, completionHandler: { (sdp, error) in
            if (error != nil) {
                AntMediaClient.printf("Error (sendAnswer): " + error!.localizedDescription)
            } else {
                AntMediaClient.printf("Got your answer")
                if (sdp?.type == RTCSdpType.answer) {
                    self.peerConnection?.setLocalDescription(sdp!, completionHandler: {
                        (error) in
                        if (error != nil) {
                            AntMediaClient.printf("Error (sendAnswer/closure): " + error!.localizedDescription)
                        }
                    })
                    
                    var answerDict = [String: Any]()
                    
                    if (self.token.isEmpty) {
                        answerDict =  ["type": "answer",
                                       "command": "takeConfiguration",
                                       "sdp": sdp!.sdp,
                                       "streamId": self.streamId!] as [String : Any]
                    } else {
                        answerDict =  ["type": "answer",
                                       "command": "takeConfiguration",
                                       "sdp": sdp!.sdp,
                                       "streamId": self.streamId!,
                                       "token": self.token ?? ""] as [String : Any]
                    }
                    
                    self.delegate?.sendMessage(answerDict)
                }
            }
        })
    }
    
    public func createOffer() {
        let constraint = self.config.createAudioVideoConstraints()

        self.peerConnection?.offer(for: constraint, completionHandler: { (sdp, error) in
            if (sdp?.type == RTCSdpType.offer) {
                AntMediaClient.printf("Got your offer")
                
                self.peerConnection?.setLocalDescription(sdp!, completionHandler: {
                    (error) in
                    if (error != nil) {
                        AntMediaClient.printf("Error (createOffer): " + error!.localizedDescription)
                    }
                })
                
                AntMediaClient.printf("offer sdp: " + sdp!.sdp)
                var offerDict = [String: Any]()
                
                if (self.token.isEmpty) {
                    offerDict =  ["type": "offer",
                                  "command": "takeConfiguration",
                                  "sdp": sdp!.sdp,
                                  "streamId": self.streamId!] as [String : Any]
                } else {
                    offerDict =  ["type": "offer",
                                      "command": "takeConfiguration",
                                      "sdp": sdp!.sdp,
                                      "streamId": self.streamId!,
                                      "token": self.token ?? ""] as [String : Any]
                }
                
                self.delegate?.sendMessage(offerDict)
            }
        })
    }
    
    public func stop() {
        disconnect();
    }
    
    private func createDataChannel() -> RTCDataChannel? {
        let config = RTCDataChannelConfiguration()
        config.channelId = 0
        guard let dataChannel = self.peerConnection?.dataChannel(forLabel: "WebRTCData", configuration: config) else {
            AntMediaClient.printf("Warning: Couldn't create data channel.")
            return nil
        }
        return dataChannel
    }

    public func disconnect() {
        self.peerConnection?.close()
    }
    
    public func toggleAudioEnabled() {
        self.audioEnabled = !self.audioEnabled
        if (self.localAudioTrack != nil) {
            self.localAudioTrack.isEnabled = self.audioEnabled
        }
    }
        
    private func addLocalMediaStream() -> Bool {

        AntMediaClient.printf("Add local media streams")
        
        if self.userType == .presenter {
            let audioSource = AntMediaWebRTCClient.factory.audioSource(with: self.config.createTestConstraints())
            self.localAudioTrack = AntMediaWebRTCClient.factory.audioTrack(with: audioSource, trackId: AUDIO_TRACK_ID)
            self.peerConnection?.add(self.localAudioTrack, streamIds: [LOCAL_MEDIA_STREAM_ID])
        }
        
        self.delegate?.addLocalStream()
        return true
    }
}

extension AntMediaWebRTCClient: RTCDataChannelDelegate {
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        self.delegate?.dataReceivedFromDataChannel(didReceiveData: buffer)
    }
    
    func dataChannelDidChangeState(_ parametersdataChannel: RTCDataChannel)  {
        if (parametersdataChannel.readyState == .open) {
            AntMediaClient.printf("Data channel state is open")
        } else if  (parametersdataChannel.readyState == .connecting) {
            AntMediaClient.printf("Data channel state is connecting")
        } else if  (parametersdataChannel.readyState == .closing) {
            AntMediaClient.printf("Data channel state is closing")
        } else if  (parametersdataChannel.readyState == .closed) {
            AntMediaClient.printf("Data channel state is closed")
        }
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didChangeBufferedAmount amount: UInt64) {
        
    }
}

extension AntMediaWebRTCClient: RTCPeerConnectionDelegate {
    
    // signalingStateChanged
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        //AntMediaClient.printf("---> StateChanged:\(stateChanged.rawValue)")
    }
    
    // addedStream
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        AntMediaClient.printf("AddedStream")
        
        self.localAudioTrack = stream.audioTracks.first
        if (stream.audioTracks.count > 1 || stream.videoTracks.count > 1) {
            return
        }
    }
    
    // removedStream
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        AntMediaClient.printf("RemovedStream")
        remoteAudioTrack = nil
    }
    
    // GotICECandidate
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        let candidateJson = ["command": "takeCandidate",
                             "type" : "candidate",
                             "streamId": self.streamId ?? "",
                             "candidate" : candidate.sdp,
                             "label": candidate.sdpMLineIndex,
                             "id": candidate.sdpMid ?? ""] as [String : Any]
        self.delegate?.sendMessage(candidateJson)
    }
    
    // iceConnectionChanged
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        AntMediaClient.printf("---> iceConnectionChanged: \(newState.rawValue) for stream: \(self.streamId ?? "")")
        self.delegate?.connectionStateChanged(newState: newState)
    }
    
    // iceGatheringChanged
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        //AntMediaClient.printf("---> iceGatheringChanged")
    }
    
    // didOpen dataChannel
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        AntMediaClient.printf("---> dataChannel opened")

        self.dataChannel = dataChannel
        self.dataChannel?.delegate = self
    }

    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        //AntMediaClient.printf("---> peerConnectionShouldNegotiate")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        //AntMediaClient.printf("---> didRemove")
    }
}
