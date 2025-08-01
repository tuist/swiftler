#!/usr/bin/env swift

import Foundation

// Simulate what the BEAM.Term conversion should do
func testDataToBinary() {
    let testString = "Hello World"
    guard let data = testString.data(using: .utf8) else {
        print("Failed to convert string to data")
        return
    }
    
    print("Original string: '\(testString)'")
    print("Data size: \(data.count) bytes")
    
    // Test the data conversion back
    if let reconstituted = String(data: data, encoding: .utf8) {
        print("Reconstituted: '\(reconstituted)'")
        print("Match: \(testString == reconstituted)")
    }
    
    // Test withUnsafeBytes
    data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
        if let baseAddress = bytes.baseAddress {
            print("Base address: \(baseAddress)")
            print("Count: \(bytes.count)")
            
            // Simulate copying to a buffer (like we do in BEAM.Term)
            let buffer = UnsafeMutableRawPointer.allocate(byteCount: bytes.count, alignment: 1)
            defer { buffer.deallocate() }
            
            _ = memcpy(buffer, baseAddress, bytes.count)
            
            // Read back from buffer
            let copiedData = Data(bytes: buffer, count: bytes.count)
            if let copiedString = String(data: copiedData, encoding: .utf8) {
                print("Copied string: '\(copiedString)'")
                print("Copy match: \(testString == copiedString)")
            }
        }
    }
}

testDataToBinary()