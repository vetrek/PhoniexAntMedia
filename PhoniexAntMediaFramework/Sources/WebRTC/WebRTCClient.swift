//
//  WebRTCClient.swift
//  WebRTC
//
//  Created by Stasel on 20/05/2018.
//  Copyright © 2018 Stasel. All rights reserved.
//

import Foundation
import WebRTC
import CocoaAsyncSocket
import RxSwift

public protocol WebRTCClientDelegate: AnyObject {
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate, clientId: String?)
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState, clientId: String?)
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data, clientId: String?)
    func webRTCClient(_ client: WebRTCClient, didSaveFile file: String, ofType type: String, toPath path: String)
}

public class WebRTCClient: NSObject {
    
    // The `RTCPeerConnectionFactory` is in charge of creating new RTCPeerConnection instances.
    // A new RTCPeerConnection should be created every new call, but the factory is shared.
    private var remoteStream: RTCMediaStream?
    private let userType: String
    private let clientId: String?
    private static let factory = RTCPeerConnectionFactory()
    
    let CHUNK_SIZE = 64000
    
    public var delegate: WebRTCClientDelegate?
    private let peerConnection: RTCPeerConnection
    private let rtcAudioSession =  RTCAudioSession.sharedInstance()
    private let audioQueue = DispatchQueue(label: "audio")
    private let mediaConstrains = [kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue]
    private var remoteDataChannel: RTCDataChannel?
    private var dataChannel: RTCDataChannel?
    private var socket: GCDAsyncSocket?
    
    var fileReader: FileReader!
    
    // Dispose Bag
    private var bag = DisposeBag()
    
    @available(*, unavailable)
    override init() {
        fatalError("WebRTCClient:init is unavailable")
    }
    
    public init(iceServer: RTCIceServer, userType: String, clientId: String? = nil, socket: GCDAsyncSocket? = nil) {
        
        let config = RTCConfiguration()
        
        config.iceServers = [iceServer]
        
        // Unified plan is more superior than planB
        config.sdpSemantics = .unifiedPlan
        
        // gatherContinually will let WebRTC to listen to any network changes and send any new candidates to the other client
        config.continualGatheringPolicy = .gatherContinually
        
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil,
                                              optionalConstraints: ["DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue])
        self.peerConnection = WebRTCClient.factory.peerConnection(with: config, constraints: constraints, delegate: nil)
        self.userType = userType
        self.clientId = clientId
        if let sock = socket {
            self.socket = sock
        }
        
        super.init()
        
        self.fileReader = FileReader(fileManager: FileManagerProxyImpl(), delegate: self)
        
        if socket != nil {
            self.socket?.synchronouslySetDelegate(self)
            self.socket?.synchronouslySetDelegateQueue(DispatchQueue.main)
        }
        self.createMediaSenders()
        self.configureAudioSession()
        self.peerConnection.delegate = self
    }
    
    // MARK: Signaling
    public func offer(completion: @escaping (_ sdp: RTCSessionDescription) -> Void) {
        let constrains = RTCMediaConstraints(mandatoryConstraints: self.mediaConstrains,
                                             optionalConstraints: nil)
        self.peerConnection.offer(for: constrains) { (sdp, error) in
            guard let sdp = sdp else {
                return
            }
            
            self.peerConnection.setLocalDescription(sdp, completionHandler: { (error) in
                completion(sdp)
            })
        }
    }
    
    public func answer(completion: @escaping (_ sdp: RTCSessionDescription) -> Void)  {
        let constrains = RTCMediaConstraints(mandatoryConstraints: self.mediaConstrains,
                                             optionalConstraints: nil)
        self.peerConnection.answer(for: constrains) { (sdp, error) in
            guard let sdp = sdp else {
                return
            }
            
            self.peerConnection.setLocalDescription(sdp, completionHandler: { (error) in
                completion(sdp)
            })
        }
    }
    
    public func set(remoteSdp: RTCSessionDescription, completion: @escaping (Error?) -> ()) {
        self.peerConnection.setRemoteDescription(remoteSdp, completionHandler: completion)
    }
    
    public func set(remoteCandidate: RTCIceCandidate) {
        self.peerConnection.add(remoteCandidate)
    }
    
    private func configureAudioSession() {
        self.rtcAudioSession.lockForConfiguration()
        do {
            try self.rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord.rawValue)
            try self.rtcAudioSession.setMode(AVAudioSession.Mode.voiceChat.rawValue)
            
            if self.userType == "listener" {
                self.startListening()
            }
        } catch let error {
            debugPrint("Error changeing AVAudioSession category: \(error)")
        }
        self.rtcAudioSession.unlockForConfiguration()
    }
    
    private func rxSetup() {
        
        NotificationCenter.default.rx
            .notification(UIDevice.proximityStateDidChangeNotification)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                
                let proximityState = UIDevice.current.proximityState
                
                if proximityState {
                    self?.setAudioSessionCategory(category: .playAndRecord)
                } else {
                    self?.setAudioSessionCategory(category: .playback)
                }
            }).disposed(by: bag)
    }
    
    private func setAudioSessionCategory(category: AVAudioSession.Category) {
        // Initialize the AudioSession
        do {
            if #available(iOS 10.0, *) {
                try self.rtcAudioSession.session.setCategory(category, mode: .default, options: [])
            } else {
                // Set category without options (<= iOS 9) setCategory(_:)
                self.rtcAudioSession.session.perform(NSSelectorFromString("setCategory:error:"), with: category)
            }
            try self.rtcAudioSession.session.setActive(true)
        } catch _ {
            
        }
    }
    
    private func startListening() {
        TimeoutHandler.setTimeout(enabled: true)
        self.setProximitySensorEnabled(true)
    }
    
    private func stopListening() {
        TimeoutHandler.setTimeout(enabled: false)
        self.setProximitySensorEnabled(false)
    }
    
    private func setProximitySensorEnabled(_ enabled: Bool) {
        let device = UIDevice.current
        device.isProximityMonitoringEnabled = enabled
    }
    
    private func createMediaSenders() {
        let streamId = "stream"
        
        // Audio
        if self.userType != "listener" {
            let audioTrack = self.createAudioTrack()
            self.peerConnection.add(audioTrack, streamIds: [streamId])
        }
        
        // Data
        self.dataChannel = self.createDataChannel()
        self.dataChannel?.delegate = self
    }
    
    private func createAudioTrack() -> RTCAudioTrack {
        let audioConstrains = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = WebRTCClient.factory.audioSource(with: audioConstrains)
        let audioTrack = WebRTCClient.factory.audioTrack(with: audioSource, trackId: "audio0")
        return audioTrack
    }
    
    // MARK: Data Channels
    private func createDataChannel() -> RTCDataChannel? {
        let dataChannelConfig = RTCDataChannelConfiguration()
        dataChannelConfig.channelId = 0
        
        let _dataChannel = self.peerConnection.dataChannel(forLabel: "dataChannel", configuration: dataChannelConfig)
        return _dataChannel!
    }
    
    func sendData(_ data: Data) {
        let buffer = RTCDataBuffer(data: data, isBinary: true)
        self.remoteDataChannel?.sendData(buffer)
    }
    
    public func sendFile(message: PresenterMessage) {
        
        guard
            let dataChannel = self.remoteDataChannel
        else { return }
        
        if let dictionaryToSend = try? message.asDictionary() {
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: dictionaryToSend, options: .prettyPrinted) {
                let jsonString: String = String(data: jsonData, encoding: .utf8)!
                let messageData = jsonString.data(using: .utf8)!
                
                let buffer = RTCDataBuffer(data: messageData, isBinary: false)
                dataChannel.sendData(buffer)
            }
        }
    }
    
    func receivingData(buffer: RTCDataBuffer, dataChannel: RTCDataChannel) {
        self.delegate?.webRTCClient(self, didReceiveData: buffer.data, clientId: self.clientId)
    }
    
    public func disconnect() {
        self.peerConnection.close()
        self.peerConnection.stopRtcEventLog()
    }
    
    public func sendTextMessage(message: MessageData) -> Bool {
        
        if let dictionaryToSend = try? message.asDictionary() {
            
            let terminatorString = "\r\n"
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: dictionaryToSend, options: .prettyPrinted) {
                let jsonString: NSString = String(data: jsonData, encoding: .utf8)! as NSString
                let stringToSend = "\(jsonString)\(terminatorString)"
                let messageData = stringToSend.data(using: .utf8)!
                
                let buffer = RTCDataBuffer(data: messageData, isBinary: false)
                self.remoteDataChannel?.sendData(buffer)
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
}

extension WebRTCClient : FileReaderDelegate {
    
    func fileReader(_ fileReader: FileReader, didSaveFile file: String, ofType type: String, toPath path: String) {
        self.delegate?.webRTCClient(self, didSaveFile: file, ofType: type, toPath: path)
    }
    
    func fileReader(_ fileReader: FileReader, didFailToSaveFile file: String, withError error: String) {}
}

extension WebRTCClient: RTCPeerConnectionDelegate {
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        debugPrint("peerConnection new signaling state: \(stateChanged)")
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        debugPrint("peerConnection did add stream")
        
        self.remoteStream = stream
        
        if let audioTrack = stream.audioTracks.first{
            print("audio track faund")
            audioTrack.source.volume = 10
        }
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        debugPrint("peerConnection did remote stream")
    }
    
    public func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        debugPrint("peerConnection should negotiate")
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        debugPrint("peerConnection new connection state: \(newState)")
        self.delegate?.webRTCClient(self, didChangeConnectionState: newState, clientId: self.clientId)
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        debugPrint("peerConnection new gathering state: \(newState)")
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        self.delegate?.webRTCClient(self, didDiscoverLocalCandidate: candidate, clientId: self.clientId)
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        debugPrint("peerConnection did remove candidate(s)")
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        debugPrint("peerConnection did open data channel")
        self.remoteDataChannel = dataChannel
    }
}

// MARK: - GCDAsyncSocketDelegate Delegeates
extension WebRTCClient: GCDAsyncSocketDelegate {
    
    public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        
        guard let text = String(data: data, encoding: .utf8) else { return }
        do {
            let signalingMessage = try JSONDecoder().decode(MessageData.self, from: text.data(using: .utf8)!)
            print(signalingMessage)
        } catch {
            print(error)
        }
    }
}

// MARK:- Audio control
extension WebRTCClient {
    
    public func setVolume(volume: Double) {
        
        if let audioTrack = self.remoteStream?.audioTracks.first {
            audioTrack.source.volume = volume
        }
    }
    
    public func muteAudio(isRemote: Bool) {
        if isRemote {
            self.setAudioEnabled(false)
        } else {
            self.setAudioEnabledForListener(false)
        }
    }
    
    public func unmuteAudio(isRemote: Bool) {
        if isRemote {
            self.setAudioEnabled(true)
        } else {
            self.setAudioEnabledForListener(true)
        }
    }
    
    // Fallback to the default playing device: headphones/bluetooth/ear speaker
    func speakerOff() {
        self.audioQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            
            self.rtcAudioSession.lockForConfiguration()
            do {
                try self.rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord.rawValue)
                try self.rtcAudioSession.overrideOutputAudioPort(.none)
            } catch let error {
                debugPrint("Error setting AVAudioSession category: \(error)")
            }
            self.rtcAudioSession.unlockForConfiguration()
        }
    }
    
    // Force speaker
    func speakerOn() {
        self.audioQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            
            self.rtcAudioSession.lockForConfiguration()
            do {
                try self.rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord.rawValue)
                try self.rtcAudioSession.overrideOutputAudioPort(.speaker)
                try self.rtcAudioSession.setActive(true)
            } catch let error {
                debugPrint("Couldn't force audio to speaker: \(error)")
            }
            self.rtcAudioSession.unlockForConfiguration()
        }
    }
    
    private func setAudioEnabled(_ isEnabled: Bool) {
        let audioTracks = self.peerConnection.senders.compactMap { return $0.track as? RTCAudioTrack }
        audioTracks.forEach { $0.isEnabled = isEnabled }
    }
    
    private func setAudioEnabledForListener(_ isEnabled: Bool) {
        let audioTracks = self.peerConnection.receivers.compactMap { return $0.track as? RTCAudioTrack }
        audioTracks.forEach { $0.isEnabled = isEnabled }
    }
}

extension WebRTCClient: RTCDataChannelDelegate {
    public func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        debugPrint("dataChannel did change state: \(dataChannel.readyState)")
    }
    
    public func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        
        if self.userType == "listener" {
            self.receivingData(buffer: buffer, dataChannel: dataChannel)
        } else {
            self.delegate?.webRTCClient(self, didReceiveData: buffer.data, clientId: self.clientId)
        }
    }
    
    public func dataChannel(_ dataChannel: RTCDataChannel, didChangeBufferedAmount amount: UInt64) {
        print(amount)
    }
}

class TimeoutHandler {
    
    class func setTimeout(enabled: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now()+1.0) {
            UIApplication.shared.isIdleTimerDisabled = enabled
        }
    }
}
