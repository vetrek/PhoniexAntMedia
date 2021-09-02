//
//  NetServerBrowser.swift
//  TCP_Socket_POC
//
//  Created by Jayesh Mardiya on 21/01/20.
//  Copyright © 2020 Sumit's Inc. All rights reserved.
//

import Foundation
import CocoaAsyncSocket
import WebRTC
import RxSwift
import Reachability
import RxReachability

protocol ConnectDelegate {
    func didIceConnectionStateChanged(iceConnectionState: RTCIceConnectionState)
    func didReceiveData(data: Data)
    func didReceiveMessage(message: MessageData)
    func didConnectWebRTC(client: ClientBase)
    func didDisconnectWebRTC(client: ClientBase)
    func didSetPassword(password: String, completion: @escaping (_ result: Bool) -> ())
    func didShowErrorMessage(message: String)
    func webRTCClient(_ client: ClientBase, didSaveFile file: String, ofType type: String, toPath path: String)
}

protocol NetServerBrowser {
    
    func startBrowser()
    func refreshBrowser()
    func serverListStream() -> Observable<[NetService]>
    func checkWifi(connection: Reachability.Connection)
}

class NetServerBrowserImpl: NSObject, NetServerBrowser {
    
    private let serverListPublisher = PublishSubject<[NetService]>()
    private var netServiceBrowser: NetServiceBrowser!

    private var serverList: [NetService] = []
    
    private var wifiStatus: Bool = false
    private let disposeBag = DisposeBag()
    
    override init() {
        super.init()

        Reachability.rx
            .status
            .subscribe(onNext: { status in
                self.checkWifi(connection: status)
            })
            .disposed(by: disposeBag)
    }
    
    func startBrowser() {
        self.serverList.removeAll()
        self.netServiceBrowser = NetServiceBrowser()
        self.netServiceBrowser.delegate = self
        self.netServiceBrowser.searchForServices(ofType: "_populi._tcp.", inDomain: "")
    }
    
    func refreshBrowser() {
        self.netServiceBrowser.stop()
        self.serverList.removeAll()
        self.netServiceBrowser.searchForServices(ofType: "_populi._tcp.", inDomain: "")
    }
    
    func serverListStream() -> Observable<[NetService]> {
        return self.serverListPublisher
            .do(onSubscribed: {
                self.startBrowser()
            })
    }
    
    func checkWifi(connection: Reachability.Connection) {
        self.wifiStatus = false

        if connection == .wifi {
            wifiStatus = true
        }
    }
}

// MARK: - NetServiceBrowserDelegate
extension NetServerBrowserImpl: NetServiceBrowserDelegate {
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
//        Log.debug(message: "Browser did find Service: \(service.name)", event: .info)
        self.serverList.append(service)
        self.serverListPublisher.onNext(self.serverList)
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        
//        Log.debug(message: "Browser did remove Service: \(service.name)", event: .info)
        if let index = self.serverList.firstIndex(of: service) {
            self.serverList.remove(at: index)
            self.serverListPublisher.onNext(self.serverList)
        }
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        
        self.serverList.removeAll()
        self.serverListPublisher.onNext(self.serverList)
    }
}

extension NetServerBrowserImpl: ConnectDelegate {
    
    func didShowErrorMessage(message: String) {
        
    }
    
    func didSetPassword(password: String, completion: @escaping (Bool) -> ()) {
        
    }
    
    func didIceConnectionStateChanged(iceConnectionState: RTCIceConnectionState) {
        
    }
    
    func didOpenDataChannel() {
        
    }
    
    func didReceiveData(data: Data) {
        
    }
    
    func didReceiveMessage(message: MessageData) {
        
    }
    
    func didConnectWebRTC(client: ClientBase) {
        
    }
    
    func didDisconnectWebRTC(client: ClientBase) {
        
    }
    
    func webRTCClient(_ client: ClientBase, didSaveFile file: String, ofType type: String, toPath path: String) {
        
    }
}
