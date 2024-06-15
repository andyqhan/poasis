//
//  WordCard.swift
//  Poetry Box
//
//  Created by Andy Han on 4/28/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

func generateTextMesh(drawText text: String) -> MeshResource {
    return .generateText(text,
                         extrusionDepth: 0.01,
                         font: .systemFont(ofSize: 0.05),
                         alignment: .center
    )
}

func createWordCardEntity(word: String) -> ModelEntity? {
    // Create a shallow box with the width based on the text size
    let textMesh = generateTextMesh(drawText: word)
    let textBounds = textMesh.bounds
    let textMaterial = SimpleMaterial(color: .black, isMetallic: true)
    let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])

    // Generate the card entity
    let padding = SIMD3<Float>(x: 0.05, y: 0.02, z: -0.005)
    var size = textBounds.extents
    size += padding
    
    let boxMesh = MeshResource.generateBox(size: size)
    
    let boxMaterial = SimpleMaterial(color: .white, isMetallic: false)
    
    let boxEntity = ModelEntity(mesh: boxMesh, materials: [boxMaterial])
    
    boxEntity.addChild(textEntity)
    
    // Add gestures to the Anchor
    boxEntity.components.set(InputTargetComponent())
    
    let shapeResource = ShapeResource.generateBox(size: size)
    boxEntity.components.set(CollisionComponent(shapes: [shapeResource]))
    
    var component = GestureComponent()
    component.canDrag = true
    component.canScale = false
    component.canRotate = false
    boxEntity.components.set(component)
    
    // scooch the textEntity so that it's centered
    // TODO this so brittle and hacky and there's definitely a more precise/correct way of doing this
    textEntity.transform.translation.x -= textBounds.extents.x/2
    textEntity.transform.translation.y -= textBounds.extents.y/1.5

    return boxEntity
}
