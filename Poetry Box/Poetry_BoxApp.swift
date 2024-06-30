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
    @State private var immersionStyle: ImmersionStyle = .mixed
    
    init() {
        RealityKitContent.GestureComponent.registerComponent()
    }
    var body: some Scene {
        ImmersiveSpace(id: "ImmersiveSpace") {
            ContentView()
        }
        .immersionStyle(selection: $immersionStyle, in: .mixed)
    }
}
