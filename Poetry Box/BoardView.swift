//
//  BoardView.swift
//  Poetry Box
//
//  Created by Andy Han on 7/14/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct BoardView: View {
    @State private var rootDragStart: SIMD3<Float> = .zero
    @State private var isDragging = false
    
    private var rootEntity = Entity()
    private var boardEntity = Entity()
    
    init() {
        self.boardEntity = try! Entity.load(named: "Board", in: RealityKitContent.realityKitContentBundle)
        self.boardEntity.name = "Board"
    }
    
    var body: some View {
        RealityView { content in
            rootEntity.addChild(boardEntity)
            content.add(rootEntity)
        }
        .gesture(DragGesture()
            .targetedToEntity(boardEntity)
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    rootDragStart = rootEntity.scenePosition
                }
                
                let translation3D = value.convert(value.gestureValue.translation3D, from: .local, to: .scene)
                
                let offset = SIMD3<Float>(x: Float(translation3D.x),
                                          y: Float(translation3D.y),
                                          z: Float(translation3D.z))
                
                
                rootEntity.scenePosition = rootDragStart + offset
            }
            .onEnded { value in
                isDragging = false
                rootDragStart = .zero
            }
        )
        // TODO on long-tap gesture, detect if WordCard is under point, if so, unsnap it
    }
}

#Preview(windowStyle: .volumetric) {
    BoardView()
}
