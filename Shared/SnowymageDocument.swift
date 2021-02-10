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

    static var readableContentTypes: [UTType] { [.png, .sni] }
    
    static var writableContentTypes: [UTType] { [.sni] }

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
            guard let img = reader.read() else {
                throw CocoaError(.fileReadCorruptFile)
            }
            image = img
        default:
            throw CocoaError(.fileReadUnsupportedScheme)
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        throw CocoaError(.featureUnsupported)
//        let data = text.data(using: .utf8)!
//        return .init(regularFileWithContents: data)
    }
}
