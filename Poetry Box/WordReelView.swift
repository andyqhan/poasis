//
//  WordReelView.swift
//  Poetry Box
//
//  Created by Andy Han on 5/18/24.
//

import SwiftUI
import RealityKit

struct WordReelView: View {
    @ObservedObject var wordReel: WordReel
    
    @State private var lastDragValue: CGFloat = 0
    
    var selectWordCard: (WordCard) -> Void
    
    init(wordStrings: [String], selectWordCard: @escaping (WordCard) -> Void) {
        self.wordReel = WordReel(wordStrings: wordStrings)
        self.selectWordCard = selectWordCard
    }
    
    var body: some View {
        RealityView { content in
            content.add(wordReel.reelEntity)
        }
        .gesture(DragGesture()
            .onChanged { value in
                print("Dragging...")
                let dragDelta = value.translation.height - lastDragValue
                lastDragValue = value.translation.height
                spinReel(by: dragDelta)
                // TODO highlight
            }
            .onEnded { _ in
                print("drag onended")
                lastDragValue = 0
                wordReel.updateVisibleCards()
            }
        )
        .simultaneousGesture(TapGesture()
            .onEnded { _ in
                print("long press on ended")
                if let newCard = wordReel.selectMiddleCard() {
                    selectWordCard(newCard)
                }

            }
        )
    }
    
    func spinReel(by delta: CGFloat) {
        print("Spinning reel by \(delta)")
        let rotationAngle = Float(delta / 100)  // Adjust the divisor for sensitivity
        wordReel.currentRotation += rotationAngle
        wordReel.reelEntity.transform.rotation *= simd_quatf(angle: rotationAngle, axis: [1, 0, 0])
        print("currentRotation now \(wordReel.currentRotation * (180.0 / .pi)) deg, entity's rotation \(wordReel.reelEntity.transform.rotation)")
        
        // Call updateVisibleCards to manage the visibility of cards during spinning
        wordReel.updateVisibleCards()
    }
}

#Preview(windowStyle: .volumetric) {
    let words = ["shall", "i", "compare", "thee", "to", "a", "summer's", "day", "?", "thou", "art", "more", "lovely", "and", "more", "temperate", "rough", "winds", "do", "shake", "the", "darling", "buds", "of", "may", "and", "summer's", "lease", "hath", "all", "too", "short", "a", "date"]
    WordReelView(wordStrings: words) {_ in }
}
