//
//  ContentView.swift
//  Poetry Box
//
//  Created by Andy Han on 4/20/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {

    @State private var enlarge = false
    @State private var showImmersiveSpace = false
    @State private var immersiveSpaceIsShown = false
    @State private var clickedNew = false

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    var body: some View {
        RealityView { content in
            guard let wordCard = createWordCardEntity(word: "supercalifragilistic") else {
                print("failed to generate wordcard")
                return
            }
            guard let wordCard2 = createWordCardEntity(word: "i love isabel suh") else {
                print("failed to generate wordcard")
                return
            }
            print("adding wordcard")
            content.add(wordCard)
            content.add(wordCard2)

        } update: { content in
            // Update the RealityKit content when SwiftUI state changes
            if let scene = content.entities.first {
                let uniformScale: Float = enlarge ? 1.4 : 1.0
                scene.transform.scale = [uniformScale, uniformScale, uniformScale]
            }
            
            if clickedNew {
                guard let wordCard = createWordCardEntity(word: "foo") else { return }
                content.add(wordCard)
            }
            
        }
        .installGestures()
//        .onChange(of: showImmersiveSpace) { _, newValue in
//            Task {
//                if newValue {
//                    switch await openImmersiveSpace(id: "ImmersiveSpace") {
//                    case .opened:
//                        immersiveSpaceIsShown = true
//                    case .error, .userCancelled:
//                        fallthrough
//                    @unknown default:
//                        immersiveSpaceIsShown = false
//                        showImmersiveSpace = false
//                    }
//                } else if immersiveSpaceIsShown {
//                    await dismissImmersiveSpace()
//                    immersiveSpaceIsShown = false
//                }
//            }
//        }
        .gesture(TapGesture().targetedToAnyEntity().onEnded { _ in
            enlarge.toggle()
        })
        .toolbar {
            ToolbarItemGroup(placement: .bottomOrnament) {
                VStack (spacing: 12) {
                    Toggle("Enlarge RealityView Content", isOn: $enlarge)
                    Toggle("Show ImmersiveSpace", isOn: $showImmersiveSpace)
                    Button("Add new card") {
                        clickedNew = true
                        Task {
                             try await Task.sleep(nanoseconds: 10_000)
                             clickedNew = false
                        }
                    }
                }
            }
        }
    }
}

#Preview(windowStyle: .volumetric) {
    ContentView()
}
