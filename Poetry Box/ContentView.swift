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

//    @State private var enlarge = false
//    @State private var showImmersiveSpace = false
//    @State private var immersiveSpaceIsShown = false
//    @State private var clickedNew = false
    
    //    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    //    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @State private var wordCardToAdd: WordCard?


    var body: some View {
        VStack {
            RealityView { content in
                content.add(WordCard(with: "foobar", draggable: true).modelEntity)
            } update: { content in
                // Update the RealityKit content when SwiftUI state changes
                if let wordCard = wordCardToAdd {
                    content.add(wordCard.modelEntity)
                    DispatchQueue.main.async {
                        wordCardToAdd = nil
                    }
                }
            }
            .installGestures()

        }
        WordReelView(wordStrings: ["oh", "thou", "that", "with", "surpassing", "glory", "crown'd"]) 
            .gesture(TapGesture()
                .onEnded {_ in
                    print("TapGesture onended")
                })
//        { newCard in
//            print("in closure from parent with newCard \(newCard)")
//            wordCardToAdd = newCard
//        }

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
//        .toolbar {
//            ToolbarItemGroup(placement: .bottomOrnament) {
//                VStack (spacing: 12) {
//                    Toggle("Enlarge RealityView Content", isOn: $enlarge)
//                    Toggle("Show ImmersiveSpace", isOn: $showImmersiveSpace)
//                    Button("Add new card") {
//                        clickedNew = true
//                        Task {
//                             try await Task.sleep(nanoseconds: 10_000)
//                             clickedNew = false
//                        }
//                    }
//                }
//            }
//        }
    }
}

#Preview(windowStyle: .volumetric) {
    ContentView()
}
