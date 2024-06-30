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
    @ObservedObject var wordReel: WordReel
    
    @State private var lastReelDragValue: CGFloat = 0
    @State private var rootDragStart: SIMD3<Float> = .zero
    @State private var isDragging = false
    
    private var rootEntity = Entity()
    private var plinthEntity = Entity()
    
    var selectWordCard: (WordCard) -> Void
    
    init(wordStrings: [String], selectWordCard: @escaping (WordCard) -> Void) {
        self.wordReel = WordReel(wordStrings: wordStrings)
        self.selectWordCard = selectWordCard
        
        self.plinthEntity = try! Entity.load(named: "Plinth", in: RealityKitContent.realityKitContentBundle)
        self.plinthEntity.name = "Plinth"
        
        wordReel.updateHighlights()
    }
    
    var body: some View {
            RealityView { content in
                content.add(rootEntity)
                rootEntity.addChild(plinthEntity)
                rootEntity.addChild(wordReel.reelEntity)
                wordReel.reelEntity.transform.translation.y += 0.25 // scooch it down
                print(plinthEntity)
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
                    
                    
                    rootEntity.transform.translation = rootDragStart + offset
                }
                .onEnded { value in
                    isDragging = false
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
                    print("long press on ended")
                    if let newCard = wordReel.selectMiddleCard() {
                        selectWordCard(newCard)
                    }

                }
            )
        }
        
}

#Preview(windowStyle: .volumetric) {
    let words = ["shall", "i", "compare", "thee", "to", "a", "summer's", "day", "?", "thou", "art", "more", "lovely", "and", "more", "temperate", "rough", "winds", "do", "shake", "the", "darling", "buds", "of", "may", "and", "summer's", "lease", "hath", "all", "too", "short", "a", "date"]
    WordReelView(wordStrings: words) {_ in }
}
