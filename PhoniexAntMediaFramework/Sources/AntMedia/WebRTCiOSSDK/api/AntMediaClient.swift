//
//  WebRTCClient.swift
//  AntMediaSDK
//
//  Copyright © 2018 AntMedia. All rights reserved.
//

import Foundation
import AVFoundation
import Starscream
import WebRTC

public enum AntMediaClientMode: Int {
    case join = 1
    case play = 2
    case publish = 3
    case conference = 4;
    
    func getLeaveMessage() -> String {
        switch self {
        case .join:
            return "leave"
        case .publish, .play:
            return "stop"
        case .conference:
            return "leaveRoom"
        }
    }
    
    func getName() -> String {
        switch self {
        case .join:
            return "join"
        case .play:
            return "play"
        case .publish:
            return "publish"
        case .conference:
            return "conference"
        }
    }
}

open class AntMediaClient: NSObject, AntMediaClientProtocol {
    
    internal static var isDebug: Bool = false
    public var delegate: AntMediaClientDelegate!
    
    private var wsUrl: String!
    private var streamId: String!
    private var token: String!
    private var webSocket: WebSocket?
    private var mode: AntMediaClientMode!
    private var webRTCClient: AntMediaWebRTCClient?
    
    private let audioQueue = DispatchQueue(label: "audio")
    
    private let rtcAudioSession =  RTCAudioSession.sharedInstance()

    private var audioEnable: Bool = true
    
    private var multiPeer: Bool = false
    private var enableDataChannel: Bool = true
    private var multiPeerStreamId: String?
    private var userType: UserType = .listener
    
    /*
     This peer mode is used in multi peer streaming
     */
    private var multiPeerMode: String = "play"
    
    var pingTimer: Timer?
    
    struct HandshakeMessage:Codable {
        var command: String?
        var streamId: String?
        var token: String?
        var video: Bool?
        var audio: Bool?
        var mode: String?
        var multiPeer: Bool?
    }
    
    public override init() {
        self.multiPeerStreamId = nil
    }
    
    public func setOptions(url: String, streamId: String, token: String = "", mode: AntMediaClientMode = .join, enableDataChannel: Bool = true, captureScreenEnabled: Bool = false, userType: UserType) {
        self.wsUrl = url
        self.streamId = streamId
        self.token = token
        self.mode = mode
        self.rtcAudioSession.add(self)
        self.enableDataChannel = enableDataChannel
        self.userType = userType
    }
    
    public func setMaxVideoBps(videoBitratePerSecond: NSNumber) {}
    
    public func setMultiPeerMode(enable: Bool, mode: String) {
        self.multiPeer = enable
        self.multiPeerMode = mode;
    }
    
    public func setVideoEnable( enable: Bool) {}
    
    public func getStreamId() -> String {
        return self.streamId
    }
    
    func getHandshakeMessage() -> String {
        
        let handShakeMesage = HandshakeMessage(command: self.mode.getName(), streamId: self.streamId, token: self.token.isEmpty ? "" : self.token, video: false, audio:self.audioEnable, multiPeer: self.multiPeer && self.multiPeerStreamId != nil ? true : false)
        let json = try! JSONEncoder().encode(handShakeMesage)
        return String(data: json, encoding: .utf8)!
    }
    
    public func getLeaveMessage() -> [String: String] {
        return [COMMAND: self.mode.getLeaveMessage(), STREAM_ID: self.streamId]
    }
    
    // Force speaker
    public func speakerOn() {
        
        self.audioQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.rtcAudioSession.lockForConfiguration()
            do {
                try self.rtcAudioSession.overrideOutputAudioPort(.speaker)
                try self.rtcAudioSession.setActive(true)
            } catch let error {
                AntMediaClient.printf("Couldn't force audio to speaker: \(error)")
            }
            self.rtcAudioSession.unlockForConfiguration()
        }
    }
    
    // Fallback to the default playing device: headphones/bluetooth/ear speaker
    public func speakerOff() {
        self.audioQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.rtcAudioSession.lockForConfiguration()
            do {
                try self.rtcAudioSession.overrideOutputAudioPort(.none)
            } catch let error {
                debugPrint("Error setting AVAudioSession category: \(error)")
            }
            self.rtcAudioSession.unlockForConfiguration()
        }
    }
    
    // Mute
    public func muteAudio() {
        
        self.audioQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.rtcAudioSession.lockForConfiguration()
            self.rtcAudioSession.isAudioEnabled = false
            self.rtcAudioSession.unlockForConfiguration()
        }
    }
    
    // UnMute
    public func unMuteAudio() {
        self.audioQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.rtcAudioSession.lockForConfiguration()
            self.rtcAudioSession.isAudioEnabled = true
            self.rtcAudioSession.unlockForConfiguration()
        }
    }
    
    open func start() {
        self.connectWebSocket()
    }
    
    /*
     Connect to websocket
     */
    open func connectWebSocket() {
        AntMediaClient.printf("Connect websocket to \(self.getWsUrl())")
        if (!(self.webSocket?.isConnected ?? false)) { //provides backward compatibility
            AntMediaClient.printf("Will connect to: \(self.getWsUrl()) for stream: \(String(describing: self.streamId))")
            
            webSocket = WebSocket(request: self.getRequest())
            webSocket?.delegate = self
            webSocket?.connect()
        }
        else {
            AntMediaClient.printf("WebSocket is already connected to: \(self.getWsUrl())")
        }
    }
    
    open func setCameraPosition(position: AVCaptureDevice.Position) {}
    
    open func setTargetResolution(width: Int, height: Int) {}
    
    /*
     Stops everything,
     Disconnects from websocket and
     stop webrtc
     */
    open func stop() {
        AntMediaClient.printf("Stop is called")
        if (self.webSocket?.isConnected ?? false) {
            let jsonString = self.getLeaveMessage().json
            webSocket?.write(string: jsonString)
            self.webSocket?.disconnect()
        }
        self.webRTCClient?.disconnect()
        self.webRTCClient = nil
    }
    
    open func initPeerConnection() {
        
        if (self.webRTCClient == nil) {
            AntMediaClient.printf("Has wsClient? (start) : \(String(describing: self.webRTCClient))")
            self.webRTCClient = AntMediaWebRTCClient.init(delegate: self, mode: self.mode, multiPeerActive:  self.multiPeer, enableDataChannel: self.enableDataChannel, userType: self.userType)
            
            self.webRTCClient!.setStreamId(streamId)
            self.webRTCClient!.setToken(self.token)
        } else {
            AntMediaClient.printf("AntMediaWebRTCClient already initialized")
        }
    }
    
    /*
     Just switches the camera. It works on the fly as well
     */
    open func switchCamera() {}
    
    /*
     Send data through WebRTC Data channel.
     */
    open func sendData(data: Data, binary: Bool = false) {
        self.webRTCClient?.sendData(data: data, binary: binary)
    }
    
    open func isDataChannelActive() -> Bool {
        return self.webRTCClient?.isDataChannelActive() ?? false
    }
    
    open func setLocalView( container: UIView, mode: UIView.ContentMode = .scaleAspectFit) {}
    
    open func setRemoteView(remoteContainer: UIView, mode: UIView.ContentMode = .scaleAspectFit) {}
    
    open func isConnected() -> Bool {
        return self.webSocket?.isConnected ?? false
    }
    
    open func setDebug(_ value: Bool) {
        AntMediaClient.isDebug = value
    }
    
    public static func setDebug(_ value: Bool) {
        AntMediaClient.isDebug = value
    }
    
    open func toggleAudio() {
        self.webRTCClient?.toggleAudioEnabled()
    }
    
    open func toggleVideo() {}
    
    open func getCurrentMode() -> AntMediaClientMode {
        return self.mode
    }
    
    open func getWsUrl() -> String {
        return wsUrl;
    }
    
    private func onConnection() {
        if (self.webSocket!.isConnected) {
            let jsonString = getHandshakeMessage()
            AntMediaClient.printf("onConnection message: \(jsonString)")
            webSocket!.write(string: jsonString)
        }
    }
    
    private func onJoined() {}
    
    private func onTakeConfiguration(message: [String: Any]) {
        var rtcSessionDesc: RTCSessionDescription
        let type = message["type"] as! String
        let sdp = message["sdp"] as! String
        
        if type == "offer" {
            rtcSessionDesc = RTCSessionDescription.init(type: RTCSdpType.offer, sdp: sdp)
            self.webRTCClient?.setRemoteDescription(rtcSessionDesc)
            self.webRTCClient?.sendAnswer()
        } else if type == "answer" {
            rtcSessionDesc = RTCSessionDescription.init(type: RTCSdpType.answer, sdp: sdp)
            self.webRTCClient?.setRemoteDescription(rtcSessionDesc)
        }
    }
    
    private func onTakeCandidate(message: [String: Any]) {
        let mid = message["id"] as! String
        let index = message["label"] as! Int
        let sdp = message["candidate"] as! String
        let candidate: RTCIceCandidate = RTCIceCandidate.init(sdp: sdp, sdpMLineIndex: Int32(index), sdpMid: mid)
        self.webRTCClient?.addCandidate(candidate)
    }
    
    private func onMessage(_ msg: String) {
        if let message = msg.toJSON() {
            guard let command = message[COMMAND] as? String else {
                return
            }
            self.onCommand(command, message: message)
        } else {
            print("WebSocket message JSON parsing error: " + msg)
        }
    }
    
    private func onCommand(_ command: String, message: [String: Any]) {
        
        switch command {
        case "start":
            //if this is called, it's publisher or initiator in p2p
            self.initPeerConnection()
            self.webRTCClient?.createOffer()
            break
        case "stop":
            self.webRTCClient?.stop()
            self.webRTCClient = nil
            self.delegate.remoteStreamRemoved(streamId: self.streamId)
            break
        case "takeConfiguration":
            self.initPeerConnection()
            self.onTakeConfiguration(message: message)
            break
        case "takeCandidate":
            self.onTakeCandidate(message: message)
            break
        case "connectWithNewId":
            self.multiPeerStreamId = message["streamId"] as? String
            let jsonString = getHandshakeMessage()
            webSocket!.write(string: jsonString)
            break
        case STREAM_INFORMATION_COMMAND:
            AntMediaClient.printf("stream information command")
            var streamInformations: [StreamInformation] = [];
            
            if let streamInformationArray = message["streamInfo"] as? [Any] {
                for result in streamInformationArray {
                    if let resultObject = result as? [String:Any] {
                        streamInformations.append(StreamInformation(json: resultObject))
                    }
                }
            }
            self.delegate.streamInformation(streamInfo: streamInformations);
            
            break
        case "notification":
            guard let definition = message["definition"] as? String else {
                return
            }
            
            if definition == "joined" {
                AntMediaClient.printf("Joined: Let's go")
                self.onJoined()
            } else if definition == "play_started" {
                AntMediaClient.printf("Play started: Let's go")
                self.delegate.playStarted(streamId: self.streamId)
            } else if definition == "play_finished" {
                AntMediaClient.printf("Playing has finished")
                self.delegate.playFinished(streamId: self.streamId)
            } else if definition == "publish_started" {
                AntMediaClient.printf("Publish started: Let's go")
                self.delegate.publishStarted(streamId: self.streamId)
            } else if definition == "publish_finished" {
                AntMediaClient.printf("Play finished: Let's close")
                self.delegate.publishFinished(streamId: self.streamId)
            }
            break
        case "error":
            guard let definition = message["definition"] as? String else {
                self.delegate.clientHasError("An error occured, please try again")
                return
            }
            self.delegate.clientHasError(AntMediaError.localized(definition))
            break
        default:
            break
        }
    }
    
    private func getRequest() -> URLRequest {
        var request = URLRequest(url: URL(string: self.getWsUrl())!)
        request.timeoutInterval = 5
        return request
    }
    
    public static func printf(_ msg: String) {
        if (AntMediaClient.isDebug) {
            debugPrint("--> AntMediaSDK: " + msg)
        }
    }
    
    public func getStreamInfo() {
        if (self.webSocket?.isConnected ?? false) {
            self.webSocket?.write(string: [COMMAND: GET_STREAM_INFO_COMMAND, STREAM_ID: self.streamId].json)
        } else {
            AntMediaClient.printf("Websocket is not connected")
        }
    }
    
    public func forStreamQuality(resolutionHeight: Int) {
        if (self.webSocket?.isConnected ?? false) {
            self.webSocket?.write(string: [COMMAND: FORCE_STREAM_QUALITY_INFO, STREAM_ID: self.streamId as String, STREAM_HEIGHT_FIELD: resolutionHeight].json)
        } else {
            AntMediaClient.printf("Websocket is not connected")
        }
    }
    
    public func getStats(completionHandler: @escaping (RTCStatisticsReport) -> Void) {
        self.webRTCClient?.getStats(handler: completionHandler)
    }
    
    public func sendFile(message: PresenterMessage) {
        
        if let dictionaryToSend = try? message.asDictionary(), self.isDataChannelActive() {
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: dictionaryToSend, options: .prettyPrinted) {
                let jsonString: String = String(data: jsonData, encoding: .utf8)!
                let messageData = jsonString.data(using: .utf8)!
                
                let buffer = RTCDataBuffer(data: messageData, isBinary: false)
                self.webRTCClient?.sendData(data: buffer.data, binary: false)
            }
        }
    }
}

extension AntMediaClient: AntMediaWebRTCClientDelegate {
    
    public func sendMessage(_ message: [String : Any]) {
        self.webSocket?.write(string: message.json)
    }
    
    public func addLocalStream() {
        self.delegate.localStreamStarted(streamId: self.streamId)
    }
    
    public func addRemoteStream() {
        self.delegate.remoteStreamStarted(streamId: self.streamId)
    }
    
    public func connectionStateChanged(newState: RTCIceConnectionState) {
        if newState == RTCIceConnectionState.closed ||
            newState == RTCIceConnectionState.disconnected ||
            newState == RTCIceConnectionState.failed
        {
            AntMediaClient.printf("connectionStateChanged: \(newState.rawValue) for stream: \(String(describing: self.streamId))")
            self.delegate.disconnected(streamId: self.streamId);
        }
    }
    
    public func dataReceivedFromDataChannel(didReceiveData data: RTCDataBuffer) {
        self.delegate.dataReceivedFromDataChannel(streamId: streamId, data: data.data, binary: data.isBinary);
    }
}

extension AntMediaClient: WebSocketDelegate {
    
    public func getPingMessage() -> [String: String] {
        return [COMMAND: "ping"]
    }
    
    public func websocketDidConnect(socket: WebSocketClient) {
        
        AntMediaClient.printf("WebSocketDelegate->Connected: \(socket.isConnected)")
        //no need to init peer connection but it opens camera and other stuff so that some users want at first
        self.initPeerConnection()
        self.onConnection()
        self.delegate?.clientDidConnect(self)
        
        //too keep the connetion alive send ping command for every 10 seconds
        pingTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { pingTimer in
            let jsonString = self.getPingMessage().json
            self.webSocket?.write(string: jsonString)
        }
    }
    
    public func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        
        pingTimer?.invalidate()
        AntMediaClient.printf("WebSocketDelegate -> Disconnected connected: \(socket.isConnected) \(String(describing: self.webSocket?.isConnected))")
        
        if let e = error as? WSError {
            self.delegate?.clientDidDisconnect(e.message)
        } else if let e = error {
            self.delegate?.clientDidDisconnect(e.localizedDescription)
        } else {
            self.delegate?.clientDidDisconnect("Disconnected")
        }
    }
    
    public func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        self.onMessage(text)
    }
    
    public func websocketDidReceiveData(socket: WebSocketClient, data: Data) {}
}

extension AntMediaClient: RTCAudioSessionDelegate {
    
    public func audioSessionDidStartPlayOrRecord(_ session: RTCAudioSession) {
        self.delegate.audioSessionDidStartPlayOrRecord(streamId: self.streamId)
    }
}
