//
//  WordCard.swift
//  Poetry Box
//
//  Created by Andy Han on 4/28/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct WordCard {
    let id: UUID
    let modelEntity: ModelEntity
    let word: String
    var draggable: Bool
    
    init(with wordString: String, draggable: Bool = false) {
        self.id = UUID()
        self.word = wordString
        self.draggable = draggable
        guard let entity = createWordCardEntity(word: wordString, draggable: draggable) else {
            print("Couldn't generate wordCardentity!")
            self.modelEntity = ModelEntity()
            return
        }
        self.modelEntity = entity
    }
    
    func highlight() {
        // TODO if i add a light source i think i can make it metallic
        self.modelEntity.model?.materials = [SimpleMaterial(color: .yellow, isMetallic: false)]
    }
    
    func unhighlight() {
        self.modelEntity.model?.materials = [SimpleMaterial(color: .white, isMetallic: false)]
    }
}

func generateTextMesh(drawText text: String) -> MeshResource {
    return .generateText(text,
                         extrusionDepth: 0.01,
                         font: .systemFont(ofSize: 0.05),
                         alignment: .center
    )
}

func createWordCardEntity(word: String, draggable: Bool) -> ModelEntity? {
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
    component.canDrag = draggable
    component.canScale = false
    component.canRotate = false
    boxEntity.components.set(component)
    
    // scooch the textEntity so that it's centered
    // TODO this so brittle and hacky and there's definitely a more precise/correct way of doing this
    textEntity.transform.translation.x -= textBounds.extents.x/2
    textEntity.transform.translation.y -= textBounds.extents.y/1.5

    return boxEntity
}
