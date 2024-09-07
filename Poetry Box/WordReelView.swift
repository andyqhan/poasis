//
//  WordReelView.swift
//  Poetry Box
//
//  Created by Andy Han on 5/18/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct WordReelView: View {
    @Environment(AppState.self) private var appState
    @ObservedObject var wordReel: WordReel
    
    @State private var lastReelDragValue: CGFloat = 0
    @State private var rootDragStart: SIMD3<Float> = .zero
    @State private var isDragging = false
    
    private var rootEntity = Entity()
    private var plinthEntity = Entity()
    
    private var title: String
    private var color: Color
    
    var selectWordCard: (WordCard) -> Void
    
    init(wordStrings: [String], title: String, color: Color, selectWordCard: @escaping (WordCard) -> Void) {
        self.wordReel = WordReel(wordStrings: wordStrings)
        self.selectWordCard = selectWordCard
        
        self.plinthEntity = try! Entity.load(named: "Plinth", in: RealityKitContent.realityKitContentBundle)
        self.plinthEntity.name = "Plinth"
        
        self.title = title
        self.color = color
        
        wordReel.updateHighlights()
    }
    
    var body: some View {
            RealityView { content, attachments in
                // Compute position to create word reel at
                // TODO: Zero out the rotation with respect to the window. Currently it opens at whatever angle (up or down, sideways) that your head is at.
//                guard let anchor = appState.worldInfo.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else { return }
//                var cameraTransform = Transform(matrix: anchor.originFromAnchorTransform)
//                cameraTransform.translation += SIMD3(0, 0, -2)
//                rootEntity.transform = cameraTransform
                
                content.add(rootEntity)
                rootEntity.addChild(plinthEntity)
                rootEntity.addChild(wordReel.reelEntity)
                wordReel.reelEntity.transform.translation.y += 0.25 // scooch it down
                print(plinthEntity)
                if let label = attachments.entity(for: "label") {
                    // bro this is so hacky lol
                    label.transform.translation.y -= 0.15
                    label.transform.rotation = simd_quatf(real: cos(.pi/4), imag: SIMD3<Float>(sin(.pi/4), 0.0, 0.0))
                    plinthEntity.addChild(label)
                }
            } attachments: {
                Attachment(id: "label") {
                    Text(self.title)
                        .font(.largeTitle)
                        .padding()
                        .background(self.color)
                        .glassBackgroundEffect()
                }
            }
            .gesture(DragGesture()
                .targetedToEntity(plinthEntity)
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
                    
                    rootEntity.lookAtCamera(worldInfo: appState.worldInfo)
                }
                .onEnded { value in
                    isDragging = false
                    rootDragStart = .zero
                }
            )
            .gesture(DragGesture()
                //.targetedToEntity(wordReel.reelEntity)
                .onChanged { value in
                    let dragDelta = value.translation.height - lastReelDragValue
                    lastReelDragValue = value.translation.height
                    wordReel.spinReel(by: dragDelta)
                    wordReel.updateVisibleCards()
                    wordReel.updateHighlights()
                }
                .onEnded { _ in
                    lastReelDragValue = 0
                }
            )

            .gesture(TapGesture()
                .targetedToEntity(wordReel.reelEntity)
                .onEnded { _ in
                    if let newCard = wordReel.selectMiddleCard() {
                        selectWordCard(newCard)
                        var targetPosition = self.wordReel.reelEntity.scenePosition
                        targetPosition.z += 0.2
                        newCard.modelEntity.scenePosition = targetPosition
                        newCard.modelEntity.lookAtCamera(worldInfo: appState.worldInfo)
                    }
                }
            )
        }
        
}

#Preview(windowStyle: .volumetric) {
    let words = ["shall", "i", "compare", "thee", "to", "a", "summer's", "day", "?", "thou", "art", "more", "lovely", "and", "more", "temperate", "rough", "winds", "do", "shake", "the", "darling", "buds", "of", "may", "and", "summer's", "lease", "hath", "all", "too", "short", "a", "date"]
    let rootEntity = ModelEntity()
    RealityView { content in
        content.add(rootEntity)
    }
    WordReelView(wordStrings: words, title: "Test label", color: Color.blue) {wordCard in
        rootEntity.addChild(wordCard.modelEntity)
    }
    .environment(AppState())
}
