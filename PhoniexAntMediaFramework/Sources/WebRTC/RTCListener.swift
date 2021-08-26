//
//  RTCListener.swift
//  VoW
//
//  Created by Jayesh Mardiya on 27/01/20.
//  Copyright © 2020 Jayesh Mardiya. All rights reserved.
//

import Foundation
import CocoaAsyncSocket
import WebRTC
import RxSwift
import Swinject
import Reachability

protocol RTCListenerDelegate {
    func showPasswordView(password: String, completion: @escaping (Bool) -> ())
    func showConnectionStatus(isConnected: Bool)
    func showErrorMessage(message: String)
    func webRTCClient(_ client: ClientBase, didSaveFile file: String, ofType type: String, toPath path: String)
}

protocol RTCListener {
    
    var rtcListenerDelegate: RTCListenerDelegate? { get set }
    func connectToServer(server: NetService)
    func disConnectFromServer()
    func sendMessage(message: MessageData)
    func setVolume(volume: Double)
    func muteEnable(isMute: Bool)
}

class RTCListenerImpl: NSObject, RTCListener {
    
    var rtcListenerDelegate: RTCListenerDelegate?
    private var serverAddresses: [Data] = []
    var clientPresenter: ClientPresenter!
    
    override init() {
        super.init()
    }
    
    func connectToServer(server: NetService) {
        
        server.delegate = self
        server.resolve(withTimeout: 5.0)
    }
    
    func disConnectFromServer() {
        if self.clientPresenter != nil {
            self.clientPresenter.disconnect()
        }
    }
    
    func sendMessage(message: MessageData) {
        
        self.clientPresenter.sendTextMessage(message: message)
    }
    
    func setVolume(volume: Double) {
        if clientPresenter != nil {
            self.clientPresenter.setVolume(volume: volume)
        }
    }
    
    func muteEnable(isMute: Bool) {
        if clientPresenter != nil {
            if isMute {
                self.clientPresenter.muteAudio(isRemote: false)
            } else {
                self.clientPresenter.unmuteAudio(isRemote: false)
            }
        }
    }
}

extension RTCListenerImpl: ConnectDelegate {
    
    func didShowErrorMessage(message: String) {
        self.rtcListenerDelegate?.showErrorMessage(message: message)
    }

    func webRTCClient(_ client: ClientBase, didSaveFile file: String, ofType type: String, toPath path: String) {
        self.rtcListenerDelegate?.webRTCClient(client, didSaveFile: file, ofType: type, toPath: path)
    }
    
    func didSetPassword(password: String, completion: @escaping (Bool) -> ()) {
        
        self.rtcListenerDelegate?.showPasswordView(password: password, completion: { isCorrect in
            completion(isCorrect)
        })
    }
    
    func didIceConnectionStateChanged(iceConnectionState: RTCIceConnectionState) {
        
    }
    
    func didReceiveData(data: Data) {
        
    }
    
    func didReceiveMessage(message: MessageData) {
        
    }
    
    func didConnectWebRTC(client: ClientBase) {
        self.rtcListenerDelegate?.showConnectionStatus(isConnected: true)
    }
    
    func didDisconnectWebRTC(client: ClientBase) {
        self.rtcListenerDelegate?.showConnectionStatus(isConnected: false)
    }
}

extension RTCListenerImpl: NetServiceDelegate {
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        guard let addresses = sender.addresses
            else { return }
        
        self.serverAddresses = addresses
        guard let addr = addresses.first else { return }
        
        let socket = GCDAsyncSocket()
        do {
            self.clientPresenter = ClientPresenter(socket: socket, and: "listener")
            self.clientPresenter.delegate = self
            try socket.connect(toAddress: addr)
            socket.readData(to: GCDAsyncSocket.crlfData(), withTimeout: -1, tag: 0)
        } catch {
            return
        }
    }
}

class RTCListenerAssembly: Assembly {

    func assemble(container: Container) {
        container.register(RTCListener.self) { _ in
            return RTCListenerImpl()
        }.inObjectScope(.container)
    }
}
