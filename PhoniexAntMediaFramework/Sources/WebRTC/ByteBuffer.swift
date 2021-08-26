//
//  ByteBuffer.swift
//  VoW
//
//  Created by Sumit Anantwar on 19/09/2020.
//  Copyright © 2020 Vox SpA. All rights reserved.
//

import Foundation

class ByteBuffer {
    
    private var currentIndex = 0
    private let byteArray: [UInt8]
    
    init(data: Data) {
        byteArray = [UInt8](data)
    }
}

// MARK: - Public APIs
extension ByteBuffer {
    func readByte() -> UInt8 {
        let byte = byteArray[currentIndex]
        currentIndex += 1
        return byte
    }
    
    func readShort() -> Int {
        return readBytesToInt(2)
    }
    
    func readInt() -> Int {
        return readBytesToInt()
    }
    
    func readString(byteLength: Int) -> String? {
        let data = Data(getBytes(byteLength))
        return String(data: data, encoding: .utf8)
    }
    
    func readBytes(length: Int) -> [UInt8] {
        return getBytes(length)
    }
    
    func remainingBytes() -> [UInt8] {
        return getBytes(remaining())
    }
    
    func remaining() -> Int {
        return byteArray.count - currentIndex
    }
}

// MARK: - Private Methods
private extension ByteBuffer {
    func readBytesToInt(_ count: Int = 4) -> Int {
        var value: Int = 0
        let bytes = getBytes(count)
        for byte in bytes {
            value = value << 8
            value = value | Int(byte)
        }
        return value
    }
    
    func getBytes(_ count: Int) -> [UInt8] {
        let start = currentIndex
        currentIndex = min((currentIndex + count), byteArray.count)
        return Array(byteArray[start..<currentIndex])
    }
}
