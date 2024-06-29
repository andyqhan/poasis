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
    
    @State private var lastDragValue: CGFloat = 0
    
    private var rootEntity = Entity()
    
    var selectWordCard: (WordCard) -> Void
    
    init(wordStrings: [String], selectWordCard: @escaping (WordCard) -> Void) {
        self.wordReel = WordReel(wordStrings: wordStrings)
        self.selectWordCard = selectWordCard
        wordReel.updateHighlights()
    }
    
    var body: some View {
            RealityView { content in
                content.add(rootEntity)
                rootEntity.addChild(wordReel.reelEntity)
                if let plinth = try? await Entity.load(named: "Plinth", in: RealityKitContent.realityKitContentBundle) {
                    rootEntity.addChild(plinth)
                    plinth.transform.translation.y -= 0.25
                }
            }
            .gesture(DragGesture()
                .onChanged { value in
                    let dragDelta = value.translation.height - lastDragValue
                    lastDragValue = value.translation.height
                    wordReel.spinReel(by: dragDelta)
                    wordReel.updateVisibleCards()
                    wordReel.updateHighlights()
                }
                .onEnded { _ in
                    lastDragValue = 0
                }
            )
            .gesture(TapGesture()
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
