//
//  main.swift
//  SNIConverter
//
//  Created by Emil Pedersen on 12/02/2021.
//

import Foundation
import CoreGraphics
import ArgumentParser

//@main
struct Converter: ParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "sni-converter", abstract: "Utility to convert from/to SNI images", version: "1.0", subcommands: [SNIConverter.self, PNGConverter.self], defaultSubcommand: SNIConverter.self)
    }
}

struct SNIConverter: ParsableCommand {
    
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "to-sni", abstract: "Converts from PNG/SNI to SNI")
    }
    
    @Flag(name: .shortAndLong, help: "The verbosity level")
    var verbose: Int

    @Flag(name: .shortAndLong, help: "Quiet errors")
    var quiet: Bool = false

    @Option(name: .shortAndLong, help: "The input. May be PNG or SNI (detected by magic number)")
    var input: String
    
    @Option(name: .shortAndLong, help: "The output, an SNI file (default: just adding .sni)")
    var output: String?
    
    @Flag(name: .long, help: "Overwrite the output file if it already exists")
    var overwrite: Bool = false
    
    @Option(name: .long, help: "The way to encode the SNI. Choses the smallest output if not provided")
    var metadata: UInt8?
    
    func validate() throws {
        if verbose > 0 && quiet {
            throw ValidationError("Verbose and Quiet are mutually exclusive")
        }
        if let metadata = metadata,
           !SnowMetadata(rawValue: metadata).validate() {
            throw ValidationError("Provided metadata is invalid")
        }
    }

    func run() throws {
        var error: Error?
        runAsyncAndBlock {
            do {
                // If more than the max, use max verbosity
                let verbosity = quiet ? .quiet : VerbosityLevel(rawValue: verbose + 1) ?? .debug
                
                let input = try Data(contentsOf: URL(fileURLWithPath: input, relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)))
                
                let image: CGImage
                if input[0...7] == Data([137, 80, 78, 71, 13, 10, 26, 10]) { // PNG magic number
                    
                    if verbosity >= .debug {
                        print("PNG input detected")
                    }
                    
                    // Parse PNG with Core Graphics
                    guard let provider = CGDataProvider(data: input as CFData),
                          let img = CGImage(pngDataProviderSource: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent) else {
                        throw CocoaError(.fileReadCorruptFile)
                    }
                    image = img
                    
                } else if input[0...1] == Data([0x53, 0x4d]) { // SNI magic number
                    
                    if verbosity >= .debug {
                        print("SNI input detected")
                    }
                    
                    var reader = SnowReader(source: input, verbosity: verbosity)
                    image = try reader.read()
                } else {
                    if verbosity >= .error {
                        print("Invalid input file type")
                    }
                    throw ExitCode.failure
                }
                
                // Encode the image in SNI
                
                let output: Data
                if let metadata = metadata {
                    var writer = try SnowWriter(source: image, metadata: SnowMetadata(rawValue: metadata), verbosity: verbosity)
                    output = try writer.write()
                } else {
                    guard let result = try await SnowWriter.best(source: image, verbosity: verbosity) else {
                        throw ExitCode.failure
                    }
                    output = result
                }
                
                var url: String
                if let loc = self.output {
                    url = loc
                } else {
                    url = self.input + ".sni"
                }
                
                try output.write(to: URL(fileURLWithPath: url, relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)), options: overwrite ? [] : .withoutOverwriting)
                
            } catch let e {
                error = e
            }
        }
        if let error = error {
            throw error
        }
    }
}

struct PNGConverter: ParsableCommand {
    
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "to-png", abstract: "Converts from SNI to PNG")
    }
    
    @Flag(name: .shortAndLong, help: "The verbosity level")
    var verbose: Int

    @Flag(name: .shortAndLong, help: "Quiet execution")
    var quiet: Bool = false

    @Option(name: .shortAndLong, help: "The input, an SNI file")
    var input: String
    
    @Option(name: .shortAndLong, help: "The output, a PNG file")
    var output: String
    
    @Flag(name: .long, help: "Overwrite the output file if it already exists")
    var overwrite: Bool = false
    
    func validate() throws {
        if verbose > 0 && quiet {
            throw ValidationError("Verbose and Quiet are mutually exclusive")
        }
    }

    func run() throws {
        // If more than the max, use max verbosity
        let verbosity = quiet ? .quiet : VerbosityLevel(rawValue: verbose + 1) ?? .debug
        
        let input = try Data(contentsOf: URL(fileURLWithPath: input, relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)))
        
        var reader = SnowReader(source: input, verbosity: verbosity)
        let image = try reader.read()
        
        
        // Encode the image to PNG
        
        guard let data = CFDataCreateMutable(nil, 0) else {
            throw CocoaError(.fileWriteOutOfSpace)
        }
        guard let dest = CGImageDestinationCreateWithData(data, "public.png" as CFString, 1, nil) else {
            throw CocoaError(.fileWriteUnsupportedScheme)
        }
        CGImageDestinationAddImage(dest, image, nil)
        guard CGImageDestinationFinalize(dest) else {
            throw CocoaError(.fileWriteUnknown)
        }
        
        try (data as Data).write(to: URL(fileURLWithPath: self.output, relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)), options: overwrite ? [] : .withoutOverwriting)
    }
}

Converter.main()
