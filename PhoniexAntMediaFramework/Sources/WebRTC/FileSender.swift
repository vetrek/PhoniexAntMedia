//
//  FileSender.swift
//  VoW
//
//  Created by Sumit Anantwar on 22/09/2020.
//  Copyright © 2020 Vox SpA. All rights reserved.
//

import Foundation
import WebRTC

protocol FileSenderDelegate : AnyObject {
    func fileSender(_ fileSender: FileSender, didStartUploadingFile file: String)
    func fileSender(_ fileSender: FileSender, uploadProgress progress: Float, forFile file: String)
    func fileSender(_ fileSender: FileSender, didCompleteUploadingFile file: String)
}


class FileSender {
    
    let CHUNK_SIZE = 64_000
    
    let dataChannel: RTCDataChannel
    weak var delegate: FileSenderDelegate?
    
    init(dataChannel: RTCDataChannel, delegate: FileSenderDelegate? = nil) {
        self.dataChannel = dataChannel
        self.delegate = delegate
    }
}

extension FileSender {
    
    func sendFile(data: Data, filename: String) {
        
        guard let filenameData = filename.data(using: .utf8) else { return }
        
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
            print(bytes.count)
            let bytesData = Data(bytes)
            let buffer = RTCDataBuffer(data: bytesData, isBinary: true)
            self.dataChannel.sendData(buffer)
        }
    }
}


