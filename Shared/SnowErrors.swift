//
//  SnowErrors.swift
//  Snowymage
//
//  Created by Emil Pedersen on 11/02/2021.
//

import Foundation

/// The errors that can be generated by SnowReader
enum SnowReaderError: Error {
    /// The metadata is not valid (See SnowMetadata.validate)
    case invalidMetadata
    /// The clip is bigger than the image
    case malformedClip
    /// The reader expected more data, the image is incomplete
    case unexpectedEOF
    /// CoreGraphics could not decode the raw bitmap. Should never happen.
    case decodingFailed
    /// The reader expected the end of the file, but more data was found.
    case trailingData
}

/// The errors that can be generated by SnowWriter
enum SnowWriterError: Error {
    /// The metadata is not valid (See SnowMetadata.validate)
    case invalidMetadata
    /// The metadata is not compatible with the given image (alpha or grayscale issues)
    case metadataMismatch
    /// The image contains more colors than a palette supports (256). Try disabling the palette.
    case paletteTooBig
    /// The image is bigger than supported (65535 * 65535)
    case imageTooBig
}

enum VerbosityLevel: Int, Comparable {
    /// No message will ever be printed
    case quiet
    /// Messages will be printed on errors
    case error
    /// Messages will be printed when changing phase
    case info
    /// All messages will be printed
    case debug
    
    static func < (lhs: VerbosityLevel, rhs: VerbosityLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
