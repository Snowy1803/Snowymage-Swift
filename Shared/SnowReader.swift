//
//  SnowReader.swift
//  Snowymage
//
//  Created by Emil Pedersen on 10/02/2021.
//

import Foundation
import AppKit

struct SnowReader {
    var source: Data
    var location: Int = 0
    
    var metadata: SnowMetadata = []
    var width: Int = 0
    var height: Int = 0
    var palette: SnowPalette?
    
    /// no idea what it is
    var cmpixelsPerByte: Int = 1
    
    mutating func read() -> CGImage? {
        readHeader()
        readPalette()
        return readImage()
    }
    
    mutating func readHeader() {
        skip(bytes: 2) // magic number SM
        metadata = SnowMetadata(rawValue: readByte())
        width = readPosition()
        height = readPosition()
    }
    
    mutating func readPalette() {
        if metadata.contains(.palette) {
            let size = Int(readByte())
            let data = source[location ... location + (size * metadata.bytesPerPixel) - 1]
            let palette = SnowPalette(colors: size, bytes: data)
            self.palette = palette
            
            if metadata.contains(.paletteCompression) {
                var loop = palette.colors + 1
                while loop * palette.colors < 256 { // ???
                    cmpixelsPerByte += 1
                    loop *= palette.colors + 1
                }
            }
        }
    }
    
    mutating func readImage() -> CGImage? {
        // Here we convert to raw bitmap data: ARGB, un-paletted
        var converted = Data(count: metadata.bytesPerPixel * width * height)
        var conversionLocation = 0
        
        for _ in 0..<width {
            let off: Int
            let len: Int
            if metadata.contains(.clip) {
                off = readPosition()
                len = readPosition()
                if len + off > height {
                    print("Malformed SNI clip")
                    return nil
                }
                // skipped bytes will keep zeroed bytes
                conversionLocation += metadata.bytesPerPixel * off
            } else {
                off = 0
                len = height
            }
            
            if let palette = palette {
                if metadata.contains(.paletteCompression) {
                    fatalError("Palette compression not implemented yet")
                } else {
                    for _ in off ..< off + len {
                        let pal = Int(readByte()) * metadata.bytesPerPixel
                        converted[conversionLocation...(conversionLocation + metadata.bytesPerPixel - 1)] = palette.bytes[pal ... (pal + metadata.bytesPerPixel - 1)]
                        conversionLocation += 1
                    }
                }
            } else {
                for _ in off ..< off + len {
                    convertBytes(into: &converted, at: &conversionLocation)
                }
            }
            
            conversionLocation += metadata.bytesPerPixel * (height - len - off)
        }
        
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 8 * metadata.bytesPerPixel, bytesPerRow: metadata.bytesPerPixel * width, space: CGColorSpace(name: metadata.contains(.grayscale) ? CGColorSpace.linearGray : CGColorSpace.sRGB)!, bitmapInfo: [CGBitmapInfo(rawValue: (metadata.contains(.alpha) ? CGImageAlphaInfo.last : CGImageAlphaInfo.none).rawValue)], provider: CGDataProvider(data: converted as CFData)!, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
    }
    
    private mutating func convertBytes(into converted: inout Data, at: inout Int) {
        converted[at...(at + metadata.bytesPerPixel - 1)] = source[location ... (location + metadata.bytesPerPixel - 1)]
        at += metadata.bytesPerPixel
        location += metadata.bytesPerPixel
    }
    
    private mutating func skip(bytes: Int) {
        location += bytes
    }
    
    private mutating func readByte() -> UInt8 {
        let byte = source[location]
        location += 1
        return byte
    }
    
    private mutating func readShort() -> UInt16 {
        let bytes = source[location ... location + 1]
        location += 2
        var short: UInt16 = 0
        bytes.withUnsafeBytes {
            short = $0.bindMemory(to: UInt16.self).first!
        }
        return UInt16(bigEndian: short)
    }
    
    private mutating func readPosition() -> Int {
        if metadata.contains(.small) {
            return Int(readByte())
        } else {
            return Int(readShort())
        }
    }
}
