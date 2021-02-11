//
//  SnowWriter.swift
//  Snowymage
//
//  Created by Emil Pedersen on 11/02/2021.
//

import Foundation
import CoreGraphics

struct SnowWriter {
    var source: CGImage
    var metadata: SnowMetadata
    
    /// `input` is raw bitmap data, we can assume the color space is correct, and it's 8 bits per component
    var input: Data
    var output: Data
    
    var palette: SnowPalette?
    var lookup: [Data: UInt8]?
    
    init(source: CGImage, metadata: SnowMetadata? = nil) throws {
        self.metadata = metadata ?? []
        self.source = source
        self.input = Data()
        self.output = Data()
        if metadata == nil {
            deduceMetadata()
        }
        normalizeMetadata()
        guard self.metadata.validate() else {
            throw SnowWriterError.invalidMetadata
        }
        
        guard let image = source.copy(colorSpace: CGColorSpace(name: self.metadata.contains(.grayscale) ? CGColorSpace.linearGray : CGColorSpace.sRGB)!),
              let data = image.dataProvider?.data as Data? else {
            // color space probably incompatible, we could convert with Core Image, or just fail
            throw SnowWriterError.metadataMismatch
        }
        self.source = image
        self.input = data
    }
    
    mutating func deduceMetadata() {
        if source.alphaInfo == .none {
            metadata.remove(.alpha)
        } else {
            metadata.insert(.alpha)
        }
        if source.colorSpace?.model == .monochrome {
            metadata.insert(.grayscale)
        } else {
            metadata.remove(.grayscale)
        }
    }
    
    mutating func normalizeMetadata() {
        if source.width < 256 && source.height < 256 {
            metadata.insert(.small)
        } else {
            metadata.remove(.small)
        }
    }
    
    mutating func write() throws -> Data {
        try writeHeader()
        try writePalette()
        writeImage()
        return output
    }
    
    mutating func writeHeader() throws {
        print("Writing header")
        write(short: 0x534d) // SM
        write(byte: metadata.rawValue)
        guard source.width <= UInt16.max && source.height <= UInt16.max else {
            throw SnowWriterError.imageTooBig
        }
        write(position: source.width)
        write(position: source.height)
    }
    
    mutating func writePalette() throws {
        guard metadata.contains(.palette) else { return }
        print("Computing palette")
        // Our raw palette data
        var pal = Data()
        // Our lookup table
        var lookup: [Data: UInt8] = [:]
        var read = input.startIndex
        while read < input.endIndex {
            let color = input[read ... read + metadata.bytesPerPixel - 1]
            if let _ = lookup[color] {
                // ignore here, not optimized
            } else if lookup.count == 256 {
                throw SnowWriterError.paletteTooBig
            } else {
                lookup[color] = UInt8(lookup.count)
                pal.append(color)
            }
            read += metadata.bytesPerPixel
        }
        palette = SnowPalette(colors: lookup.count, bytes: pal)
        self.lookup = lookup
        write(byte: UInt8(lookup.count))
        output.append(pal)
    }
    
    mutating func writeImage() {
        print("Writing image")
        for x in 0..<source.width {
            var off = 0
            var len = source.height
            if metadata.contains(.clip) {
                for y in 0...source.height {
                    if y == source.height {
                        off = y
                        break
                    }
                    let srcloc = source.height * y * metadata.bytesPerPixel + x * metadata.bytesPerPixel
                    if input[srcloc + metadata.bytesPerPixel - 2] != 0 { // last component (alpha) is not transparent?
                        off = y
                        break
                    }
                }
                for y in (off..<source.height).reversed() {
                    let srcloc = source.height * y * metadata.bytesPerPixel + x * metadata.bytesPerPixel
                    if input[srcloc + metadata.bytesPerPixel - 2] != 0 {
                        len = source.height - y - off
                        break
                    }
                }
            }
            
            if let lookup = lookup {
                let paletteSize = UInt8(lookup.count)
                if metadata.contains(.paletteCompression) {
                    var currByte: UInt8 = 0
                    var j: UInt8 = 1
                    for y in off..<(off + len) {
                        let srcloc = source.height * y * metadata.bytesPerPixel + x * metadata.bytesPerPixel
                        let color = input[srcloc ... srcloc + metadata.bytesPerPixel - 1]
                        currByte += j * lookup[color]!
                        j *= paletteSize + 1
                        if Int(currByte) + Int(j) * Int(paletteSize) >= 256 {
                            write(byte: currByte)
                            currByte = 0
                            j = 1
                        }
                    }
                    if currByte > 0 {
                        write(byte: currByte)
                    }
                } else { // palette, 1 per byte
                    for y in off..<(off + len) {
                        let srcloc = source.height * y * metadata.bytesPerPixel + x * metadata.bytesPerPixel
                        let color = input[srcloc ... srcloc + metadata.bytesPerPixel - 1]
                        write(byte: lookup[color]!)
                    }
                }
            } else { // raw copy
                for y in off..<(off + len) {
                    let srcloc = source.height * y * metadata.bytesPerPixel + x * metadata.bytesPerPixel
                    let color = input[srcloc ... srcloc + metadata.bytesPerPixel - 1]
                    output.append(color)
                }
            }
        }
    }
    
    mutating func write(short: UInt16) {
        output.append(withUnsafeBytes(of: short.bigEndian) { Data($0) })
    }
    
    mutating func write(byte: UInt8) {
        output.append(byte)
    }
    
    mutating func write(position: Int) {
        if metadata.contains(.small) {
            write(byte: UInt8(position))
        } else {
            write(short: UInt16(position))
        }
    }
}
