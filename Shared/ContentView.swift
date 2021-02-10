//
//  ContentView.swift
//  Shared
//
//  Created by Emil Pedersen on 10/02/2021.
//

import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct ContentView: View {
    @Binding var document: SnowymageDocument

    var body: some View {
        Group {
            #if os(iOS)
            Image(UIImage(document.image))
            #else
            Image(nsImage: NSImage(cgImage: document.image, size: NSSize(width: document.image.width / 4, height: document.image.height / 4)))
            #endif
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView(document: .constant(SnowymageDocument(im)))
//    }
//}
