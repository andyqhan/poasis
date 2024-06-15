//
//  Poetry_BoxApp.swift
//  Poetry Box
//
//  Created by Andy Han on 4/20/24.
//

import SwiftUI
import RealityKitContent

@main
struct Poetry_BoxApp: App {
    init() {
        RealityKitContent.GestureComponent.registerComponent()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }.windowStyle(.volumetric)

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }
    }
}
