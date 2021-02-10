//
//  ContentView.swift
//  Shared
//
//  Created by Emil Pedersen on 10/02/2021.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: SnowymageDocument

    var body: some View {
        TextEditor(text: $document.text)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(SnowymageDocument()))
    }
}
