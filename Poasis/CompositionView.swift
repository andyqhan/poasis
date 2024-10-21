//
//  ContentView.swift
//
//  The main view.
//
//  Created by Andy Han on 4/20/24.
//

import ARKit
import SwiftUI
import RealityKit
import RealityKitContent

struct CompositionView: View {
    @State private var dragStart = SIMD3<Float>.zero
    @State private var isDragging = false
    @Environment(AppState.self) private var appState
    
    var body: some View {
        ZStack {
            RealityView { content in
                content.add(appState.rootEntity)
            }
            .gesture(DragGesture()
                .targetedToAnyEntity()  // TODO maybe limit this to WordCards
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                        dragStart = value.entity.scenePosition
                    }
                    
                    let translation3D = value.convert(value.gestureValue.translation3D, from: .local, to: .scene)
                    
                    let offset = SIMD3<Float>(x: Float(translation3D.x),
                                              y: Float(translation3D.y),
                                              z: Float(translation3D.z))
                    
                    
                    value.entity.scenePosition = dragStart + offset
                    value.entity.lookAtCamera(worldInfo: appState.worldInfo)
                }
                .onEnded { value in
                    //                let snapInfo = DragSnapInfo(entity: value.entity, otherSelectedEntities: Array())
                    //                let boardQuery = EntityQuery(where: .has(RealityKitContent.BoardComponent.self))
                    //                guard let others = value.entity.scene?.performQuery(boardQuery) else {
                    //                    print("No entities to snap to, returning.")
                    //                    isDragging = false
                    //                    return
                    //                }
                    //                handleSnap(snapInfo, allConnectableEntities: others)
                    
                    isDragging = false
                    dragStart = .zero
                }
            )
            
        }
        .overlay(
            ForEach(appState.wordReelViews.indices, id: \.self) { index in
                appState.wordReelViews[index]
                    .environment(appState)
            }, alignment: .topTrailing
        )
        
        
        
    }
}
            
    //        BoardView()

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


#Preview(windowStyle: .volumetric) {
    CompositionView()
        .environment(AppState())
}
