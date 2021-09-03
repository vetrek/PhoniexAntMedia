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
    
    enum CodingKeys: String, CodingKey {
        
        case id
        case name
        case message
        case isFavotire
        case isTranslated
        case streamName
        case localRecording
        case allowRecording
        case accessByPasscode
        case multicast
        case udpPort
        case subStream
        case speakerHost
        case speakerPort
        case passcode
    }
    
    func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(message, forKey: .message)
        try container.encode(isFavotire, forKey: .isFavotire)
        try container.encode(isTranslated, forKey: .isTranslated)
        try container.encode(streamName, forKey: .streamName)
        try container.encode(localRecording, forKey: .localRecording)
        try container.encode(allowRecording, forKey: .allowRecording)
        try container.encode(accessByPasscode, forKey: .accessByPasscode)
        try container.encode(multicast, forKey: .multicast)
        try container.encode(udpPort, forKey: .udpPort)
        try container.encode(subStream, forKey: .subStream)
        try container.encode(speakerHost, forKey: .speakerHost)
        try container.encode(speakerPort, forKey: .speakerPort)
        try container.encode(passcode, forKey: .passcode)
    }
    
    init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try values.decode(MessageType.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        message = try values.decode(String.self, forKey: .message)
        isFavotire = try values.decode(Bool.self, forKey: .isFavotire)
        isTranslated = try values.decode(Bool.self, forKey: .isTranslated)
        streamName = try values.decode(String.self, forKey: .streamName)
        localRecording = try values.decode(Bool.self, forKey: .localRecording)
        allowRecording = try values.decode(Bool.self, forKey: .allowRecording)
        accessByPasscode = try values.decode(Bool.self, forKey: .accessByPasscode)
        multicast = try values.decode(Bool.self, forKey: .multicast)
        udpPort = try values.decode(UInt16.self, forKey: .udpPort)
        subStream = try values.decode(Bool.self, forKey: .subStream)
        speakerHost = try values.decode(String.self, forKey: .speakerHost)
        speakerPort = try values.decode(Int.self, forKey: .speakerPort)
        passcode = try values.decode(String.self, forKey: .passcode)
    }
}

enum MessageType: String, Codable {
    case message
    case votingAnswer
    case votingData
    case finishedVotingResult
    case setup
}

public class SessionData: Codable {
    
    public var streamName: String?
    public var localRecording: Bool?
    public var allowRecording: Bool?
    public var remoteStream: Bool?
    public var passcode: String?
    public var maxListener: Int?
    
    public init() {}
    
    enum CodingKeys: String, CodingKey {
        case streamName
        case localRecording
        case allowRecording
        case remoteStream
        case passcode
        case maxListener
    }
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(streamName, forKey: .streamName)
        try container.encode(localRecording, forKey: .localRecording)
        try container.encode(allowRecording, forKey: .allowRecording)
        try container.encode(remoteStream, forKey: .remoteStream)
        try container.encode(passcode, forKey: .passcode)
        try container.encode(maxListener, forKey: .maxListener)
    }
    
    public required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        streamName = try values.decode(String.self, forKey: .streamName)
        localRecording = try values.decode(Bool.self, forKey: .localRecording)
        allowRecording = try values.decode(Bool.self, forKey: .allowRecording)
        remoteStream = try values.decode(Bool.self, forKey: .remoteStream)
        passcode = try values.decode(String.self, forKey: .passcode)
        maxListener = try values.decode(Int.self, forKey: .maxListener)
    }
}

public class MessageData: Codable {
    
    public var name: String = ""
    public var message: String = ""
    public var isFavotire: Bool = false
    
    public init() {}
    
    enum CodingKeys: String, CodingKey {
        case name
        case message
        case isFavotire
    }
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(message, forKey: .message)
        try container.encode(isFavotire, forKey: .isFavotire)
    }
    
    public required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try values.decode(String.self, forKey: .name)
        message = try values.decode(String.self, forKey: .message)
        isFavotire = try values.decode(Bool.self, forKey: .isFavotire)
    }
    
    public func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data,
                                                                options: .allowFragments) as? [String: Any] else {
            throw NSError()
        }
        return dictionary
    }
}

public struct PresenterMessage: Codable {
    
    public var type: String?
    public var data: FileData?
    
    enum CodingKeys: String, CodingKey {
        case type
        case data
    }
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type, forKey: .type)
        try container.encode(data, forKey: .data)
    }
    
    public init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        type = try values.decode(String.self, forKey: .type)
        data = try values.decode(FileData.self, forKey: .data)
    }
}

public struct FileData: Codable {
    
    public var url: String?
    public var fileName: String?
    
    enum CodingKeys: String, CodingKey {
        case url
        case fileName
    }
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(url, forKey: .url)
        try container.encode(fileName, forKey: .fileName)
    }
    
    public init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        url = try values.decode(String.self, forKey: .url)
        fileName = try values.decode(String.self, forKey: .fileName)
    }
}

public struct ImagePDFData: Codable {
    
    public var imagePdfData: Data?
    public var isImage: Bool?
    
    enum CodingKeys: String, CodingKey {
        case imagePdfData
        case isImage
    }
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(imagePdfData, forKey: .imagePdfData)
        try container.encode(isImage, forKey: .isImage)
    }
    
    public init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        imagePdfData = try values.decode(Data.self, forKey: .imagePdfData)
        isImage = try values.decode(Bool.self, forKey: .isImage)
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
