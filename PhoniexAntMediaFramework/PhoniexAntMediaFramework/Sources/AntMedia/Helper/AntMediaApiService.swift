//
//  AntMediaApiProvider.swift
//  VoW
//
//  Created by Sumit Anantwar on 01/08/2021.
//  Copyright © 2021 Vox SpA. All rights reserved.
//

import Foundation
import RxSwift

protocol AntMediaApiService {
    func getListenerCount(request: BroadcastStatsRequest) -> Single<BroadcastStatsResponse>
}

private enum EndPoint : String {
    case broadcast_stats = "http://%@/rest/v2/broadcasts/%@/broadcast-statistics"
    
    // http://52.91.238.198:5080
    
    func pathAtServer(_ server: String, withStreamId streamId: String) -> String {
        let serverAddress = server.replacingOccurrences(of: "ws://", with: "")
            .replacingOccurrences(of: "/websocket", with: "")
        return String(format: self.rawValue, serverAddress, streamId)
    }
    
    func urlAtServer(_ server: String, withStreamId streamId: String) -> URL {
        let path = self.pathAtServer(server, withStreamId: streamId)
        guard let url = URL(string: path) else {
            fatalError("Could not form URL from API path: \(path)")
        }
        return url
    }
}


class AntMediaApiServiceImpl : AntMediaApiService {
    
    let apiProvider = ApiProvider()
    
    func getListenerCount(request: BroadcastStatsRequest) -> Single<BroadcastStatsResponse> {
        let url = EndPoint.broadcast_stats.urlAtServer(request.serverAddress, withStreamId: request.streamId)
        return apiProvider.getRequest(url: url)
            .map {
                try $0.decode()
            }
    }
}

struct BroadcastStatsRequest : Codable {
    let serverAddress: String
    let streamId: String
}

struct BroadcastStatsResponse : Codable {
    let totalRTMPWatchersCount: Int
    let totalHLSWatchersCount: Int
    let totalWebRTCWatchersCount: Int
}
