//
//  SnowErrors.swift
//  Snowymage
//
//  Created by Emil Pedersen on 11/02/2021.
//

import Foundation

enum SnowReaderError: Error {
    case invalidMetadata
    case malformedClip
    case unexpectedEOF
    case decodingFailed
    case trailingData
}
