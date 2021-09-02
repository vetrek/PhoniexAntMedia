//
//  BaseConnect.swift
//  TCP_Socket_POC
//
//  Created by Jayesh Mardiya on 20/01/20.
//  Copyright © 2020 Sumit's Inc. All rights reserved.
//

import UIKit
import WebRTC
import CocoaAsyncSocket
import RxSwift
import RxCocoa

class ClientBase: NSObject {
    
    let CHUNK_SIZE = 64000
    var fileReader: FileReader!
    
    private var remoteStream: RTCMediaStream?
    private var dataChannel: RTCDataChannel?
    private var remoteDataChannel: RTCDataChannel?
    
    private let audioQueue = DispatchQueue(label: "audio")
    private let rtcAudioSession =  RTCAudioSession.sharedInstance()
    private var userType: String
    var delegate: ConnectDelegate?
    public private(set) var isConnected: Bool = false
    
    private var socket: GCDAsyncSocket
    var peerConnectionFactory = RTCPeerConnectionFactory()
    
    // Dispose Bag
    private var bag = DisposeBag()
    
    lazy var peerConnection: RTCPeerConnection = {
        let rtcConf = RTCConfiguration()
        rtcConf.sdpSemantics = .unifiedPlan
        let mediaConstraints = RTCMediaConstraints.init(mandatoryConstraints: nil, optionalConstraints: nil)
        let pc = self.peerConnectionFactory.peerConnection(with: rtcConf, constraints: mediaConstraints, delegate: nil)
        return pc
    }()
    
    init(socket: GCDAsyncSocket, and userType: String) {
        self.socket = socket
        self.userType = userType
        super.init()
        
        self.socket.synchronouslySetDelegate(self)
        self.socket.synchronouslySetDelegateQueue(DispatchQueue.main)
        
        self.peerConnection.delegate = self
        
        self.dataChannel = self.setupDataChannel()
        self.dataChannel?.delegate = self
        
        self.connect()
        
        self.configureAudioSession()
        
        self.fileReader = FileReader(fileManager: FileManagerProxyImpl(), delegate: self)
    }
    
    deinit {
        print("WebRTC Client Deinit")
        //        self.peerConnection = nil
    }
    
    func connect() {
        fatalError("Should override in subclass")
    }
    
    func disconnect() {
        self.peerConnection.close()
    }
}

extension ClientBase: FileReaderDelegate {
    func fileReader(_ fileReader: FileReader, didSaveFile file: String, ofType type: String, toPath path: String) {
        self.delegate?.webRTCClient(self, didSaveFile: file, ofType: type, toPath: path)
    }
    
    func fileReader(_ fileReader: FileReader, didFailToSaveFile file: String, withError error: String) {
        
    }
}

extension ClientBase {
    
    func setVolume(volume: Double) {
        
        if let audioTrack = self.remoteStream?.audioTracks.first {
            print("audio track faund")
            audioTrack.source.volume = volume
        }
    }
    
    func receiveCandidate(candidate: RTCIceCandidate) {
        self.peerConnection.add(candidate)
    }
    
    func receiveAnswer(answerSDP: RTCSessionDescription) {
        
        self.peerConnection.setRemoteDescription(answerSDP) { (err) in
            if let error = err {
                print("failed to set remote answer SDP")
                print(error)
                return
            }
        }
    }
    
    func receiveOffer(offerSDP: RTCSessionDescription, onCreateAnswer: @escaping (RTCSessionDescription) -> Void) {
        
        print("set remote description")
        self.peerConnection.setRemoteDescription(offerSDP) { (err) in
            if let error = err {
                print("failed to set remote offer SDP")
                print(error)
                return
            }
            
            print("succeed to set remote offer SDP")
            self.makeAnswer(onCreateAnswer: onCreateAnswer)
        }
    }
    
    func makeAnswer(onCreateAnswer: @escaping (RTCSessionDescription) -> Void) {
        
        self.peerConnection.answer(for: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil), completionHandler: { (answerSessionDescription, err) in
            
            if let error = err {
                print("failed to create local answer SDP")
                print(error)
                return
            }
            
            print("succeed to create local answer SDP")
            if let answerSDP = answerSessionDescription{
                self.peerConnection.setLocalDescription( answerSDP, completionHandler: { (err) in
                    if let error = err {
                        print("failed to set local ansewr SDP")
                        print(error)
                        return
                    }
                    
                    print("succeed to set local answer SDP")
                    onCreateAnswer(answerSDP)
                })
            }
        })
    }
    
    func sendOffer(with box_id: String, sessionDescription: RTCSessionDescription, password: String?, allowRecording: Bool) {
        let sdp = LocalSDP(sdp: sessionDescription.sdp)
        let signalingMessage = SignalingMessage(type: "offer", sessionDescription: sdp, password: password, allowRecording: allowRecording, boxId: box_id)
        
        do {
            let data = try JSONEncoder().encode(signalingMessage)
            let message = String(data: data, encoding: String.Encoding.utf8)!
            
            self.sendMessage(message)
            
        } catch {
            print(error)
        }
    }
    
    func sendAnswer(sdp: RTCSessionDescription) {
        let localSdp = LocalSDP(sdp: sdp.sdp)
        let signalingMessage = SignalingMessage(type: "answer", sessionDescription: localSdp)
        
        do {
            let data = try JSONEncoder().encode(signalingMessage)
            let message = String(data: data, encoding: String.Encoding.utf8)!
            
            self.sendMessage(message)
            
        } catch {
            print(error)
        }
    }
    
    func sendMessage(_ message: String) {
        
        let terminatorString = "\r\n"
        let messageToSend = "\(message)\(terminatorString)"
        let data = messageToSend.data(using: .utf8)!
        self.socket.write(data, withTimeout: -1, tag: 0)
        self.socket.readData(to: GCDAsyncSocket.crlfData(), withTimeout: -1, tag: 0)
    }
    
    func sendTextMessage(message: MessageData) {
        
        if let dictionaryToSend = try? message.asDictionary() {
            
            let terminatorString = "\r\n"
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: dictionaryToSend, options: .prettyPrinted) {
                let jsonString: NSString = String(data: jsonData, encoding: .utf8)! as NSString
                let stringToSend = "\(jsonString)\(terminatorString)"
                let messageData = stringToSend.data(using: .utf8)!
                
                let buffer = RTCDataBuffer(data: messageData, isBinary: false)
                self.remoteDataChannel?.sendData(buffer)
            }
        }
    }
    
    func sendFile(_ data: Data, filename: String, filesize: Int) -> Bool {
        
        guard
            let dataChannel = self.remoteDataChannel,
            let filenameData = filename.data(using: .utf8)
        else { return false }
        
        var dataObject: Data = Data() // 1
        let filenameCount = UInt16(filenameData.count) // 2
        let byteArray = [UInt8](filenameCount.bigEndian.data) // 3
        let fileDataCount = UInt32(data.count)
        let fileDataCountByteArray = fileDataCount.bigEndian.data
        dataObject.append(contentsOf: byteArray) // 4
        dataObject.append(contentsOf: fileDataCountByteArray)
        dataObject.append(filenameData)
        dataObject.append(data)
        let byteBuffer = ByteBuffer(data: dataObject)
        
        while byteBuffer.remaining() > 0 {
            
            let bytes = byteBuffer.readBytes(length: CHUNK_SIZE)
            let bytesData = Data(bytes)
            let buffer = RTCDataBuffer(data: bytesData, isBinary: true)
            dataChannel.sendData(buffer)
        }
        
        return true
    }
    
    func receivingData(buffer: RTCDataBuffer, dataChannel: RTCDataChannel) {
        
        let byteBuffer = ByteBuffer(data: buffer.data)
        fileReader.readFile(buffer: byteBuffer)
    }
    
    func muteAudio(isRemote: Bool) {
        if isRemote {
            self.setAudioEnabled(false)
        } else {
            self.setAudioEnabledForListener(false)
        }
    }
    
    func unmuteAudio(isRemote: Bool) {
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
}

private extension ClientBase {
    
    func configureAudioSession() {
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
    
    func setAudioEnabled(_ isEnabled: Bool) {
        
        let audioTracks = self.peerConnection.senders.compactMap { return $0.track as? RTCAudioTrack }
        audioTracks.forEach { $0.isEnabled = isEnabled }
    }
    
    func setAudioEnabledForListener(_ isEnabled: Bool) {
        
        let audioTracks = self.peerConnection.receivers.compactMap { return $0.track as? RTCAudioTrack }
        audioTracks.forEach { $0.isEnabled = isEnabled }
    }
    
    func setupDataChannel() -> RTCDataChannel {
        let dataChannelConfig = RTCDataChannelConfiguration()
        dataChannelConfig.channelId = 0
        
        let _dataChannel = self.peerConnection.dataChannel(forLabel: "dataChannel", configuration: dataChannelConfig)
        return _dataChannel!
    }
    
    func onConnected() {
        
        self.isConnected = true
        
        DispatchQueue.main.async {
            self.delegate?.didConnectWebRTC(client: self)
        }
    }
    
    func onDisConnected() {
        
        self.isConnected = false
        
        DispatchQueue.main.async {
            print("--- on dis connected ---")
            self.peerConnection.close()
            self.dataChannel = nil
            self.delegate?.didDisconnectWebRTC(client: self)
        }
    }
    
    func sendCandidate(_ iceCandidate: RTCIceCandidate) {
        let candidate = LocalCandidate.init(sdp: iceCandidate.sdp, sdpMLineIndex: iceCandidate.sdpMLineIndex, sdpMid: iceCandidate.sdpMid!)
        let signalingMessage = SignalingMessage(type: "candidate", candidate: candidate)
        do {
            let data = try JSONEncoder().encode(signalingMessage)
            let message = String(data: data, encoding: String.Encoding.utf8)!
            self.sendMessage(message)
        } catch {
            print(error)
        }
    }
    
    func sendData(data: Data) {
        if let _dataChannel = self.dataChannel {
            if _dataChannel.readyState == .open {
                let buffer = RTCDataBuffer(data: data, isBinary: true)
                _dataChannel.sendData(buffer)
            }
        }
    }
    
    func rxSetup() {
        
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
    
    func setAudioSessionCategory(category: AVAudioSession.Category) {
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
    
    func startListening() {
        TimeoutHandler.setTimeout(enabled: true)
        self.setProximitySensorEnabled(true)
    }
    
    func stopListening() {
        TimeoutHandler.setTimeout(enabled: false)
        self.setProximitySensorEnabled(false)
    }
    
    func setProximitySensorEnabled(_ enabled: Bool) {
        let device = UIDevice.current
        device.isProximityMonitoringEnabled = enabled
    }
}

// MARK: - GCDAsyncSocketDelegate Delegeates
extension ClientBase: GCDAsyncSocketDelegate {
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        
        guard let text = String(data: data, encoding: .utf8) else { return }
        do {
            let signalingMessage = try JSONDecoder().decode(SignalingMessage.self, from: text.data(using: .utf8)!)
            
            if signalingMessage.type == "answer" {
                let answerSdp = RTCSessionDescription(type: .answer, sdp: (signalingMessage.sessionDescription?.sdp)!)
                self.receiveAnswer(answerSDP: answerSdp)
            } else if signalingMessage.type == "offer" {
                #if VoxBox
                if let voxBoxList = UserDefaults.standard.getVoxBoxList() {
                    print(voxBoxList)
                    if signalingMessage.password != nil {
                        self.delegate?.didSetPassword(password: signalingMessage.password!, completion: { isCorrect in
                            if isCorrect {
                                let offerSdp = RTCSessionDescription(type: .offer, sdp: (signalingMessage.sessionDescription?.sdp)!)
                                self.receiveOffer(offerSDP: offerSdp, onCreateAnswer: { answerSDP in
                                    self.sendAnswer(sdp: answerSDP)
                                })
                            }
                        })
                    } else {
                        if voxBoxList.contains(where: {$0.box_id == signalingMessage.boxId}) {
                            let offerSdp = RTCSessionDescription(type: .offer, sdp: (signalingMessage.sessionDescription?.sdp)!)
                            self.receiveOffer(offerSDP: offerSdp, onCreateAnswer: { answerSDP in
                                self.sendAnswer(sdp: answerSDP)
                            })
                        } else {
                            self.delegate?.didShowErrorMessage(message: .alertDescCantConnectBox)
                        }
                    }
                } else {
                    self.delegate?.didShowErrorMessage(message: .alertDescSomethingWrong)
                }
                #else
                if signalingMessage.password != nil {
                    self.delegate?.didSetPassword(password: signalingMessage.password!, completion: { isCorrect in
                        if isCorrect {
                            let offerSdp = RTCSessionDescription(type: .offer, sdp: (signalingMessage.sessionDescription?.sdp)!)
                            self.receiveOffer(offerSDP: offerSdp, onCreateAnswer: { answerSDP in
                                self.sendAnswer(sdp: answerSDP)
                            })
                        }
                    })
                } else {
                    let offerSdp = RTCSessionDescription(type: .offer, sdp: (signalingMessage.sessionDescription?.sdp)!)
                    self.receiveOffer(offerSDP: offerSdp, onCreateAnswer: { answerSDP in
                        self.sendAnswer(sdp: answerSDP)
                    })
                }
                #endif
            } else if signalingMessage.type == "candidate" {
                let candidate = signalingMessage.candidate!
                self.receiveCandidate(candidate: RTCIceCandidate(sdp: candidate.sdp, sdpMLineIndex: candidate.sdpMLineIndex, sdpMid: candidate.sdpMid))
            } else if signalingMessage.type == "error" {
                self.delegate?.didShowErrorMessage(message: .alertDescLimitExceeded)
            }
        } catch {
            print(error)
        }
    }
}

// MARK: - PeerConnection Delegeates
extension ClientBase: RTCPeerConnectionDelegate {
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        
        var state = ""
        if stateChanged == .stable {
            state = "stable"
        }
        
        if stateChanged == .closed {
            state = "closed"
        }
        
        print("signaling state changed: ", state)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        
        switch newState {
        case .connected, .completed:
            if !self.isConnected {
                self.onConnected()
            }
        default:
            if self.isConnected {
                self.onDisConnected()
            }
        }
        
        DispatchQueue.main.async {
            self.delegate?.didIceConnectionStateChanged(iceConnectionState: newState)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("did add stream")
        self.remoteStream = stream
        
        if let audioTrack = stream.audioTracks.first{
            print("audio track faund")
            audioTrack.source.volume = 10
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        self.sendCandidate(candidate)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("--- did remove stream ---")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        self.remoteDataChannel = dataChannel
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}
}

extension ClientBase: RTCDataChannelDelegate {
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        DispatchQueue.main.async {
            if buffer.isBinary {
                if self.userType == "listener" {
                    self.receivingData(buffer: buffer, dataChannel: dataChannel)
                } else {
                    self.delegate?.didReceiveData(data: buffer.data)
                }
            } else {
                
                let recievedDataString = String(data: buffer.data, encoding: .utf8)!
                let decryptedStringData: Data = recievedDataString.data(using: String.Encoding.utf8)!
                
                do {
                    let jsonDecoder = JSONDecoder()
                    let message = try jsonDecoder.decode(MessageData.self, from: decryptedStringData)
                    print("Message : \(message)")
                    self.delegate?.didReceiveMessage(message: message)
                } catch let error as NSError {
                    print(error)
                }
            }
        }
    }
    
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        print("data channel did change state")
    }
}
