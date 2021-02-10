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
    var text: String

    init(text: String = "Hello, world!") {
        self.text = text
    }

    static var readableContentTypes: [UTType] { [.png, .bmp, .sni] }
    
    static var writableContentTypes: [UTType] { [.sni] }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return .init(regularFileWithContents: data)
    }
}
