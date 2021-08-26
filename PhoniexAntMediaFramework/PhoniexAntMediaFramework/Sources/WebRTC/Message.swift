//
//  Message.swift
//  VoW
//
//  Created by Jayesh Mardiya on 04/09/19.
//  Copyright © 2019 Jayesh Mardiya. All rights reserved.
//

import UIKit
import WebRTC

struct Message: Codable {
    var id: MessageType = .setup
    var name: String?
    var message: String?
    var isFavotire: Bool?
    var isTranslated: Bool?
    var streamName: String?
    var localRecording: Bool?
    var allowRecording: Bool?
    var accessByPasscode: Bool?
    var multicast: Bool?
    var udpPort: UInt16?
    var subStream: Bool?
    var speakerHost: String?
    var speakerPort: Int?
    var passcode: String?

    init() {

    }
}

enum MessageType: String, Codable {
    case message
    case votingAnswer
    case votingData
    case finishedVotingResult
    case setup
}

struct SessionData: Codable {
    
    var streamName: String?
    var localRecording: Bool?
    var allowRecording: Bool?
    var remoteStream: Bool?
    var passcode: String?
    var maxListener: Int?

    init() {

    }
}

struct MessageData: Codable {
    
    var name: String?
    var message: String?
    var isFavotire: Bool?

    init() {

    }
}

struct PresenterMessage: Codable {
    
    var type: String?
    var data: FileData?

    init() {

    }
}

struct FileData: Codable {
    
    var url: String?
    var fileName: String?
    
    init() {

    }
}

struct ImagePDFData: Codable {
    
    var imagePdfData: Data?
    var isImage: Bool?

    init() {

    }
}

extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data,
                                                                options: .allowFragments) as? [String: Any] else {
            throw NSError()
        }
        return dictionary
    }
}
