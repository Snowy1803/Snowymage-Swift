//
//  SnowymageApp.swift
//  Shared
//
//  Created by Emil Pedersen on 10/02/2021.
//

import SwiftUI

@main
struct SnowymageApp: App {
    var body: some Scene {
        DocumentGroup(viewing: SnowymageDocument.self) { file in
            ContentView(document: file.$document)
        }
    }
}
