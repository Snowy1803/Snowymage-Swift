#  Snowymage Swift

This project includes a reader and a writer for SNI files (Snowymage files). It can show them in an iOS and macOS.

Those files also gain a thumbnail in the Finder, and support for Quick Look.

## How it works

The app uses Core Graphics to make the images. Therefore, the parsing logic can be shared between iOS and macOS. However, it can't be used on non-Apple platforms.

## Build

This project depends on Swift Concurrency features. It requires the Swift Development Snapshot toolchain, on the newest Xcode.
The app was built with Swift Development Snapshot 2021-02-09-a on Xcode 12.5.

The app has a deployment target of macOS 11 and iOS 14 as it uses the SwiftUI app lifecycle with the DocumentGroup feature. This was only used to speed up things, but the app only is an image viewer.

## Run

The macOS and iOS just have to be opened once for it to be registered, and SNI files will gain thumbnail and quick look support.

The apps seem to only be openable via Xcode, as it depends on Swift Concurrency, which is not available in the default Swift Toolchain.

## Targets

- iOS: An iOS document-based SwiftUI app, that can open and save SNI and PNG
- macOS: A macOS document-based SwiftUI app, that can open and save SNI and PNG
- QuickLook: A macOS AppKit-based image view
- QuickLook iOS: An iOS UIKit-based image view
- Thumbnail iOS/Mac: A Core Graphics based thumbnail maker
- SNIConverter: A macOS command-line tool to convert between PNG and SNI
