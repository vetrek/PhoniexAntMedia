//
//  NetServiceServer.swift
//  TCP_Socket_POC
//
//  Created by Jayesh Mardiya on 21/01/20.
//  Copyright © 2020 Sumit's Inc. All rights reserved.
//

import Foundation
import CocoaAsyncSocket
import WebRTC

public protocol NetServiceServerDelegate {
    func setListenerCount(count: Int)
    func setServerName(name: String)
    func setMessageData(message: MessageData)
}

public class NetServiceServer: NSObject {
    
    private var netService: NetService!
    private var asyncSocketServer: GCDAsyncSocket!
    public var clientListener: ClientListener?
    public var connectedClients: [ClientListener] = []
    private var tcpPort: UInt16!
    public var delegate: NetServiceServerDelegate?
    private var serviceName: String = ""
    private var sessionData: SessionData? = nil
    
    public init(with sessionData: SessionData) {
        self.serviceName = sessionData.streamName ?? ""
        self.sessionData = sessionData
        super.init()
        self.startServer()
    }
    
    func startServer() {
        
        self.updateListenerCount()
        self.asyncSocketServer = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
        
        if let server = self.asyncSocketServer {
            server.delegate = self
            
            do {
                try server.accept(onPort: 0)
            } catch {
                return
            }
            
            self.tcpPort = server.localPort
            
            server.perform {
                server.enableBackgroundingOnSocket()
            }
            
            server.autoDisconnectOnClosedReadStream = false

            self.netService = NetService(domain: "", type: "_populi._tcp.", name: self.serviceName, port: Int32(self.tcpPort))
            self.netService.schedule(in: RunLoop.current, forMode: .common)
            self.netService.publish()
            self.netService.delegate = self
        }
    }
    
    public func stopServer() {
        
        self.clientListener?.peerConnection.close()
        self.connectedClients.removeAll()
        self.netService.stop()
        self.netService.remove(from: .current, forMode: .common)
    }
    
    func updateListenerCount() {
        self.delegate?.setListenerCount(count: self.connectedClients.count)
    }
}

extension NetServiceServer: ConnectDelegate {
    
    func didShowErrorMessage(message: String) {}
    
    func didIceConnectionStateChanged(iceConnectionState: RTCIceConnectionState) {}
    
    func didReceiveData(data: Data) {
        
    }
    
    func didReceiveMessage(message: MessageData) {
        self.delegate?.setMessageData(message: message)
    }
    
    func didConnectWebRTC(client: ClientBase) {
        self.connectedClients.append(client as! ClientListener)
        self.updateListenerCount()
    }
    
    func didDisconnectWebRTC(client: ClientBase) {
        self.connectedClients.remove(client as! ClientListener)
        self.updateListenerCount()
    }
    
    func didSetPassword(password: String, completion: @escaping (Bool) -> ()) {}
    
    func webRTCClient(_ client: ClientBase, didSaveFile file: String, ofType type: String, toPath path: String) {}
}

extension NetServiceServer: GCDAsyncSocketDelegate {
    
    public func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        
        // Send session setup to client
        guard
            let sessionSetupData = self.sessionData,
            let maxListener = sessionSetupData.maxListener
        else {
            return
        }
        
        if maxListener > self.connectedClients.count {
            let box_id = sessionSetupData.streamName ?? ""
            let clientListener = ClientListener(socket: newSocket, password: sessionSetupData.passcode, allowRecording: sessionSetupData.allowRecording ?? false, currentConnectedClient: self.connectedClients.count, maxConnectClient: maxListener, box_id: box_id)
            clientListener.delegate = self
            self.clientListener = clientListener
        } else {
            self.sendError(toSocket: newSocket)
        }
    }
    
    func sendError(toSocket socket: GCDAsyncSocket) {
        let errorPayload = ErrorPayload(errorType: "connections_limit_exceeded")
        let errorMessage = ErrorMessage(type: "error", error: errorPayload)
        
        do {
            let data = try JSONEncoder().encode(errorMessage)
            let message = String(data: data, encoding: String.Encoding.utf8)!
            
            self.sendMessage(message, toSocket: socket)
            
        } catch {
            print(error)
        }
    }
    
    func sendMessage(_ message: String, toSocket socket: GCDAsyncSocket) {
        
        let terminatorString = "\r\n"
        let messageToSend = "\(message)\(terminatorString)"
        let data = messageToSend.data(using: .utf8)!
        socket.write(data, withTimeout: -1, tag: 0)
        socket.readData(to: GCDAsyncSocket.crlfData(), withTimeout: -1, tag: 0)
    }
}

extension NetServiceServer: NetServiceDelegate {
    
    public func netServiceDidPublish(_ sender: NetService) {
        self.delegate?.setServerName(name: sender.name)
    }
    
    public func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {}
    
    public func netServiceDidStop(_ sender: NetService) {}
}
