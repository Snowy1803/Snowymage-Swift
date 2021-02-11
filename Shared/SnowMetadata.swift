//
//  SnowMetadata.swift
//  Snowymage
//
//  Created by Emil Pedersen on 10/02/2021.
//

import Foundation

struct SnowMetadata: OptionSet {
    var rawValue: UInt8
    
    static let alpha = SnowMetadata(rawValue: 1 << 0)
    static let grayscale = SnowMetadata(rawValue: 1 << 1)
    static let palette = SnowMetadata(rawValue: 1 << 3)
    static let paletteCompression = SnowMetadata(rawValue: 1 << 2)
    static let clip = SnowMetadata(rawValue: 1 << 4)
    static let small = SnowMetadata(rawValue: 1 << 5)
    
    var bytesPerPixel: Int {
        (self.contains(.grayscale) ? 1 : 3) + (self.contains(.alpha) ? 1 : 0)
    }
    
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
