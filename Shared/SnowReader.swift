//
//  SnowReader.swift
//  Snowymage
//
//  Created by Emil Pedersen on 10/02/2021.
//

import Foundation
import CoreGraphics

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
            location += size * metadata.bytesPerPixel
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
        
        for x in 0..<width {
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
            } else {
                off = 0
                len = height
            }
            
            if let palette = palette {
                if metadata.contains(.paletteCompression) {
                    var currByte = Int(readByte())
                    var j = 0
                    for y in off ..< off + len {
                        let convLocation = height * y * metadata.bytesPerPixel + x * metadata.bytesPerPixel
                        if j == cmpixelsPerByte {
                            currByte = Int(readByte())
                            j = 0
                        }
                        let b = currByte % (palette.colors + 1) - 1
                        currByte /= (palette.colors + 1)
                        let pal = palette.bytes.startIndex + b * metadata.bytesPerPixel
                        converted[convLocation...(convLocation + metadata.bytesPerPixel - 1)] = palette.bytes[pal ... (pal + metadata.bytesPerPixel - 1)]
                        j += 1
                    }
                } else {
                    for y in off ..< off + len {
                        let convLocation = height * y * metadata.bytesPerPixel + x * metadata.bytesPerPixel
                        let pal = palette.bytes.startIndex + Int(readByte()) * metadata.bytesPerPixel
                        converted[convLocation...(convLocation + metadata.bytesPerPixel - 1)] = palette.bytes[pal ... (pal + metadata.bytesPerPixel - 1)]
                    }
                }
            } else {
                for y in off ..< off + len {
                    let convLocation = height * y * metadata.bytesPerPixel + x * metadata.bytesPerPixel
                    converted[convLocation...(convLocation + metadata.bytesPerPixel - 1)] = source[location ... (location + metadata.bytesPerPixel - 1)]
                    location += metadata.bytesPerPixel
                }
            }
        }
        
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 8 * metadata.bytesPerPixel, bytesPerRow: metadata.bytesPerPixel * width, space: CGColorSpace(name: metadata.contains(.grayscale) ? CGColorSpace.linearGray : CGColorSpace.sRGB)!, bitmapInfo: [CGBitmapInfo(rawValue: (metadata.contains(.alpha) ? CGImageAlphaInfo.last : CGImageAlphaInfo.none).rawValue)], provider: CGDataProvider(data: converted as CFData)!, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
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
