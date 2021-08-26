//
//  FileReader.swift
//  VoW
//
//  Created by Sumit Anantwar on 19/09/2020.
//  Copyright © 2020 Vox SpA. All rights reserved.
//

import Foundation

protocol FileReaderDelegate : class {
    func fileReader(_ fileReader: FileReader, didSaveFile file: String, ofType type: String, toPath path: String)
    func fileReader(_ fileReader: FileReader, didFailToSaveFile file: String, withError error: String)
}

class ReadState {
    var headerRead = false
    var fileRead = false
}

class FileReader {
    
    let INCOMMING_FILES_DIR = "IncommingFilesDir"
    
    var readState = ReadState()
    var fileData = Data()
    var fileLength = 0
    var filename = ""
    var fileType = ""
    
    let fileManager: FileManagerProxy
    weak var delegate: FileReaderDelegate?
    
    init(fileManager: FileManagerProxy, delegate: FileReaderDelegate? = nil) {
        self.fileManager = fileManager
        self.delegate = delegate
    }
}

extension FileReader {
    
    func readFile(buffer: ByteBuffer) {
        if !readState.headerRead {
            let filenameLength = buffer.readShort()
            self.fileLength = buffer.readInt()
            self.filename = buffer.readString(byteLength: filenameLength)! // FIXME: Force Unwrap!!
            self.fileType = (filename as NSString).pathExtension
            readState.headerRead = true
        }
        else if !readState.fileRead {
            let bytes = buffer.remainingBytes()
            fileData.append(contentsOf: bytes)
            
            if self.fileData.count >= self.fileLength {
                do {
                    let destPath = try fileManager.save(data: fileData, withFileName: self.filename, inDirectory: INCOMMING_FILES_DIR, inCache: false)
                    delegate?.fileReader(self, didSaveFile: self.filename, ofType: self.fileType, toPath: destPath)
                    readState.fileRead = true
                    self.reset()
                } catch {
                    delegate?.fileReader(self, didFailToSaveFile: self.filename, withError: error.localizedDescription)
                }
                return
            }
        }
        
        if buffer.remaining() > 0 {
            readFile(buffer: buffer)
        }
    }
}

private extension FileReader {
    
    func reset() {
        self.readState = ReadState()
        self.fileData = Data()
        self.fileLength = 0
        self.filename = ""
        self.fileType = ""
    }
}
