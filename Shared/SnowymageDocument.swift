//
//  SnowymageDocument.swift
//  Shared
//
//  Created by Emil Pedersen on 10/02/2021.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var sni: UTType {
        UTType(exportedAs: "fr.orbisec.sni")
    }
}

struct SnowymageDocument: FileDocument {
    var image: CGImage

    init(image: CGImage) {
        self.image = image
    }

    static var readableContentTypes: [UTType] { [.sni, .png] }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        switch configuration.contentType {
        case .png:
            guard let provider = CGDataProvider(data: data as CFData),
                  let img = CGImage(pngDataProviderSource: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent) else {
                throw CocoaError(.fileReadCorruptFile)
            }
            image = img
        case .sni:
            var reader = SnowReader(source: data)
            image = try reader.read()
        default:
            throw CocoaError(.fileReadUnsupportedScheme)
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        switch configuration.contentType {
        case .png:
            guard let data = CFDataCreateMutable(nil, 0) else {
                throw CocoaError(.fileWriteOutOfSpace)
            }
            guard let dest = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else {
                throw CocoaError(.fileWriteUnsupportedScheme)
            }
            CGImageDestinationAddImage(dest, image, nil)
            guard CGImageDestinationFinalize(dest) else {
                throw CocoaError(.fileWriteUnknown)
            }
            return .init(regularFileWithContents: data as Data)
        case .sni:
            return .init(regularFileWithContents: try bestWriter())
        default:
            throw CocoaError(.fileReadUnsupportedScheme)
        }
    }
    
    func bestWriter() throws -> Data {
        var result: Data?
        var error: Error?
        runAsyncAndBlock {
            do {
                guard let data = try await SnowWriter.best(source: image) else {
                    throw CocoaError(.fileWriteUnknown)
                }
                result = data
            } catch let e {
                error = e
            }
        }
        if let error = error {
            throw error
        } else if let result = result {
            return result
        } else {
            throw CocoaError(.fileWriteUnknown)
        }
    }
}
