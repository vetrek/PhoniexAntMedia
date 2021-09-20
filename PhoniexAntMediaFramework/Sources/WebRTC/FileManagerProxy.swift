//
//  FileManagerProxy.swift
//  VoW
//
//  Created by Sumit Anantwar on 20/09/2020.
//  Copyright © 2020 Vox SpA. All rights reserved.
//

import Foundation

protocol FileManagerProxy {
    func save(data: Data, withFileName filename: String, inDirectory directory: String?, inCache: Bool) throws -> String
}

class FileManagerProxyImpl : FileManagerProxy {
    
    private lazy var documentsDir = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }()
    
    private lazy var cachesDir = {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }()
}

extension FileManagerProxyImpl {
    
    func save(data: Data, withFileName filename: String, inDirectory directory: String?, inCache: Bool) throws -> String {
        
        var parentDir = inCache ? cachesDir : documentsDir
        if let directory = directory {
            parentDir = parentDir.appendingPathComponent(directory, isDirectory: true)
            try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true, attributes: nil)
        }
        
        let destPath = parentDir.appendingPathComponent(filename)
        
        try data.write(to: destPath)
        return destPath.path
    }
}
