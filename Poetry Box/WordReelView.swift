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
    @State private var selectedWordCard: WordCard?
    
    init(wordStrings: [String]) {
        self.wordReel = WordReel(wordStrings: wordStrings)
    }
    
    var body: some View {
        RealityView { content in
            content.add(wordReel.reelEntity)
        } update: { content in
            print("adding selectedWordCard with word \(selectedWordCard?.word)")
            if let selectedWordCard = selectedWordCard {
                content.add(selectedWordCard.modelEntity)
            }
        }
        .gesture(DragGesture()
            .onChanged { value in
                let dragDelta = value.translation.height - lastDragValue
                lastDragValue = value.translation.height
                spinReel(by: dragDelta)
                // TODO highlight
            }
            .onEnded { _ in
                lastDragValue = 0
                wordReel.updateVisibleCards()
            }
        )
        .gesture(TapGesture()
            .onEnded { _ in
                print("long press on ended")
                selectedWordCard = wordReel.selectMiddleCard()
            }
        )
    }
    
    func spinReel(by delta: CGFloat) {
        let rotationAngle = Float(delta / 100)  // Adjust the divisor for sensitivity
        wordReel.currentRotation += rotationAngle
        wordReel.reelEntity.transform.rotation *= simd_quatf(angle: rotationAngle, axis: [1, 0, 0])
        //print("currentRotation now \(wordReel.currentRotation * (180.0 / .pi)) deg")
        
        // Call updateVisibleCards to manage the visibility of cards during spinning
        wordReel.updateVisibleCards()
    }
}

#Preview(windowStyle: .volumetric) {
    let words = ["shall", "i", "compare", "thee", "to", "a", "summer's", "day", "?", "thou", "art", "more", "lovely", "and", "more", "temperate", "rough", "winds", "do", "shake", "the", "darling", "buds", "of", "may", "and", "summer's", "lease", "hath", "all", "too", "short", "a", "date"]
    WordReelView(wordStrings: words)
}
