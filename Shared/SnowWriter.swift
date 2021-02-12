//
//  SnowWriter.swift
//  Snowymage
//
//  Created by Emil Pedersen on 11/02/2021.
//

import Foundation
import CoreGraphics

/// This structure permits to write SNI images to Data. Initialize the struct with a source CGImage and some metadata, then call `write()` to get the data. You may also use `best` to automatically choose the best metadata
struct SnowWriter {
    /// The source image. It must be of the color space of the metadata (RGB(A) or Grayscale).
    var source: CGImage
    /// The wanted metadata. The alpha bit and the small bit will be changed automatically.
    var metadata: SnowMetadata
    /// The verbosity level of the writer
    var verbosity: VerbosityLevel
    
    /// `input` is raw bitmap data, we assume the color space is correct, and that it's 8 bits per component
    var input: Data
    /// The SNI output
    var output: Data
    
    /// The composed palette
    var palette: SnowPalette?
    /// The palette lookup table. Raw color data as key, the palette index as value. Speeds up writing images with palettes.
    var lookup: [Data: UInt8]?
    
    /// Creates a SnowWriter for the specified image with the given metadata
    /// - Parameters:
    ///   - source: The source image. It must be of the color space of the metadata (RGB(A) or Grayscale).
    ///   - metadata: The wanted metadata. The alpha bit and the small bit will be changed automatically.
    /// - Throws: SnowWriterError if the metadata is not supported
    init(source: CGImage, metadata: SnowMetadata? = nil, verbosity: VerbosityLevel = .error) throws {
        self.metadata = metadata ?? []
        self.source = source
        self.verbosity = verbosity
        self.input = Data()
        self.output = Data()
        if metadata == nil {
            deduceMetadata()
        }
        normalizeMetadata()
        guard self.metadata.validate() else {
            if verbosity >= .error {
                print("Error: given metadata doesn't exist: \(self.metadata)")
            }
            throw SnowWriterError.invalidMetadata
        }
        
        guard let image = source.copy(colorSpace: CGColorSpace(name: self.metadata.contains(.grayscale) ? CGColorSpace.linearGray : CGColorSpace.sRGB)!),
              let data = image.dataProvider?.data as Data?,
              self.metadata.bytesPerPixel * image.width * image.height == data.count else {
            // color space probably incompatible, we could convert with Core Image, or just fail
            if verbosity >= .error {
                print("[\(self.metadata.rawValue)] Error: could not convert image to an 8 bit/component image with the given colorspace. Image color space is \(source.colorSpace?.name as String? ?? "<not found>")")
            }
            throw SnowWriterError.metadataMismatch
        }
        self.source = image
        self.input = data
    }
    
    /// Detects the needed color space. Called by `init` if the metadata is not provided
    mutating func deduceMetadata() {
        if source.colorSpace?.model == .monochrome {
            metadata.insert(.grayscale)
        } else {
            metadata.remove(.grayscale)
        }
    }
    
    /// Replaces the `alpha` and the `small` bits of the metadata according to the source image.
    mutating func normalizeMetadata() {
        if source.alphaInfo == .none {
            metadata.remove(.alpha)
        } else {
            metadata.insert(.alpha)
        }
        if source.width < 256 && source.height < 256 {
            metadata.insert(.small)
        } else {
            metadata.remove(.small)
        }
    }
    
    /// Attempts to write the data to SNI.
    mutating func write() throws -> Data {
        try writeHeader()
        try writePalette()
        writeImage()
        return output
    }
    
    /// Writes the SNI header: Magic number, metadata and size
    /// - Throws: SnowReaderError.imageTooBig if the image size doesn't fits in two shorts.
    mutating func writeHeader() throws {
        if verbosity >= .info {
            print("[\(metadata.rawValue)] Writing header")
            if verbosity >= .debug {
                print(metadata)
            }
        }
        write(short: 0x534d) // SM
        write(byte: metadata.rawValue)
        guard source.width <= UInt16.max && source.height <= UInt16.max else {
            if verbosity >= .error {
                print("[\(metadata.rawValue)] Error: image exceeds the limit of \(UInt16.max) * \(UInt16.max) pixels: Image is \(source.width) * \(source.height)")
            }
            throw SnowWriterError.imageTooBig
        }
        write(position: source.width)
        write(position: source.height)
    }
    
    /// Writes the palette of the image, if enabled
    /// - Throws: SnowWriterError.paletteTooBig if there is more than 256 colors.
    mutating func writePalette() throws {
        guard metadata.contains(.palette) else { return }
        if verbosity >= .info {
            print("[\(metadata.rawValue)] Computing palette")
        }
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
                if verbosity >= .error {
                    print("[\(metadata.rawValue)] Error: image has more than 256 colors")
                }
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
    
    /// Writes the actual image data from the raw input
    mutating func writeImage() {
        if verbosity >= .info {
            print("[\(metadata.rawValue)] Writing image")
        }
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
                    if input[srcloc + metadata.bytesPerPixel - 1] != 0 { // last component (alpha) is not transparent?
                        off = y
                        break
                    }
                }
                if off == source.height {
                    len = 0
                } else {
                    for y in (off ... source.height - 1).reversed() {
                        let srcloc = source.height * y * metadata.bytesPerPixel + x * metadata.bytesPerPixel
                        if input[srcloc + metadata.bytesPerPixel - 1] != 0 {
                            len = y - off
                            break
                        }
                    }
                }
                write(position: off)
                write(position: len)
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
    
    /// Writes a big-endian short to the output buffer
    mutating func write(short: UInt16) {
        output.append(withUnsafeBytes(of: short.bigEndian) { Data($0) })
    }
    
    /// Writes a byte to the output buffer
    mutating func write(byte: UInt8) {
        output.append(byte)
    }
    
    /// Writes a position (byte or short depending on metadata)
    mutating func write(position: Int) {
        if metadata.contains(.small) {
            write(byte: UInt8(position))
        } else {
            write(short: UInt16(position))
        }
    }
}

extension SnowWriter {
    /// Finds and returns the smallest SNI Data that represents the given image
    /// - Parameter source: the image to encode
    /// - Throws: Should never throw
    /// - Returns: The smallest SNI Data found
    static func best(source: CGImage, verbosity: VerbosityLevel = .error) async throws -> Data? {
        let r = try await allPossible(source: source, verbosity: verbosity).min(by: { $0.count < $1.count })
        if let r = r {
            print("Chose: \(r[r.startIndex + 2])")
        } else {
            print("None found")
        }
        return r
    }
    
    /// Finds all the possible SNI Data that represents the given image
    /// - Parameter source: the image to encode
    /// - Throws: Should never throw
    /// - Returns: All SNI Datas representing the same image, with different metadata
    static func allPossible(source: CGImage, verbosity: VerbosityLevel = .error) async throws -> [Data] {
        try await Task.withGroup(resultType: Data?.self) { group in
            for meta in allMetadatas() {
                await group.add {
                    do {
                        var writer = try SnowWriter(source: source, metadata: meta, verbosity: verbosity)
                        return try writer.write()
                    } catch let e {
                        print("Failed for metadata \(meta): \(e)")
                        return nil
                    }
                }
            }
            
            var result = [Data]()
            while let data = try await group.next() {
                if let data = data {
                    result.append(data)
                }
            }
            return result
        }
    }
    
    /// Returns the possible metadata an image can have
    private static func allMetadatas() -> [SnowMetadata] {
        var all = [SnowMetadata]()
        for clip in [SnowMetadata(), SnowMetadata.clip] {
            for gray in [SnowMetadata(), SnowMetadata.grayscale] {
                for pal in [SnowMetadata(), SnowMetadata.palette, SnowMetadata.paletteCompression] {
                    all.append([clip, gray, pal])
                }
            }
        }
        return all
    }
}
