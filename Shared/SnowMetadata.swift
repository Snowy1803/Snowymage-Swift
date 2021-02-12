//
//  SnowMetadata.swift
//  Snowymage
//
//  Created by Emil Pedersen on 10/02/2021.
//

import Foundation

struct SnowMetadata: OptionSet {
    var rawValue: UInt8
    
    /// The image has an additional alpha channel as the last component
    static let alpha = SnowMetadata(rawValue: 1 << 0)
    /// The image is grayscaled (1 white component) instead of RGB
    static let grayscale = SnowMetadata(rawValue: 1 << 1)
    /// The image contains a palette, of maximum 256 colors, and then each pixel can be encoded as a single byte
    static let palette = SnowMetadata(rawValue: 1 << 3)
    /// Each pixel in the image is compressed into less than a byte
    static let paletteCompression = SnowMetadata(rawValue: 1 << 2)
    /// The image is clipped so that transparent pixels around the image don't take as much space
    static let clip = SnowMetadata(rawValue: 1 << 4)
    /// The image fits in 256*256 pixels
    static let small = SnowMetadata(rawValue: 1 << 5)
    
    /// The number of bytes per pixel (between 1 (grayscale) and 4 (RGBA))
    var bytesPerPixel: Int {
        (self.contains(.grayscale) ? 1 : 3) + (self.contains(.alpha) ? 1 : 0)
    }
    
    /// Validates that the metadata is valid (doesn't contain mutually exclusive bits)
    func validate() -> Bool {
        if self.contains(.clip) && !self.contains(.alpha) {
            return false
        }
        if self.contains(.paletteCompression) && !self.contains(.palette) {
            return false
        }
        return true
    }
}

extension SnowMetadata: CustomStringConvertible {
    var description: String {
        "SnowMetadata \(rawValue) [alpha=\(self.contains(.alpha)), grayscaled=\(self.contains(.grayscale)), palette=\(self.contains(.palette) ? self.contains(.paletteCompression) ? "compressed" : "uncompressed" : "none"), clip=\(self.contains(.clip)), small=\(self.contains(.small))]"
    }
}
