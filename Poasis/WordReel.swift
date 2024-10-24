//
//  WordReel.swift
//
//  Created by Andy Han on 5/18/24.
//
import SwiftUI
import RealityKit
import RealityKitContent


class WordReel: ObservableObject {
    @Published var wordCards: [WordCard] = []
    @Published var reelEntity: Entity = Entity()
    @Published var currentRotation: Float = 0.0  // Keeps track of the Reel's rotation
    @Published var cardRotationDict: [UUID: Angle] = [:]
    var replaceWords: Bool
    
    let anglePerCard = Angle(radians: .pi / Double(6))  // 30 degrees
    
    // replaceWords controls whether a wordcard should be replaced when it's selected
    init(wordStrings: [String], replaceWords: Bool = true) {
        //super.init()
        self.replaceWords = replaceWords
        
        for wordString in wordStrings {
            let wordCard = WordCard(with: wordString, draggable: false)
            addCard(wordCard)
        }
        
        positionCards()

        updateVisibleCards()
    }
    
    func addCard(_ wordCard: WordCard) {
        wordCards.append(wordCard)
        reelEntity.addChild(wordCard.modelEntity)
    }

    func removeCard(_ wordCard: WordCard) {
        if let index = wordCards.firstIndex(where: { $0.id == wordCard.id }) {
            print("Removing card \(wordCard.word)")
            wordCards.remove(at: index)
            wordCard.modelEntity.removeFromParent()
        }
    }
    
    func updateVisibleCards() {
        for card in wordCards {
            let isVisible = calculateVisibility(for: card)
            if isVisible {
                if card.modelEntity.parent == nil {
                    reelEntity.addChild(card.modelEntity)
                }
                // Rotate card to face front
                card.modelEntity.transform.rotation = simd_quatf(angle: -currentRotation, axis: [1, 0, 0])
            } else {
                card.modelEntity.removeFromParent()
            }
        }
    }
    
    func calculateVisibility(for card: WordCard) -> Bool {
        guard let cardRotationD = cardRotationDict[card.id]?.radians else {
            return false
        }
        let cardRotation = Float(cardRotationD)
        //let maxRotation = Float(anglePerCard.radians * Double(wordCards.count))
        let lowerBound = currentRotation - .pi / 2
        let upperBound = currentRotation + .pi / 2
        
        // Normalize the card rotation to be within 0 to whatever the max degree is, to allow wraparound. (Not implemented yet cause i can't figure out the math lol)
//        let normalizedCardRotation = fmod(cardRotation + maxRotation, maxRotation)
//        let normalizedLowerBound = fmod(lowerBound + 2 * .pi, 2 * .pi)
//        let normalizedUpperBound = fmod(upperBound + 2 * .pi, 2 * .pi)
        
//        print("Calculating visibility for card \(card.word). cardRotation \(cardRotation) (normalized \(normalizedCardRotation)), maxRotation \(maxRotation), normalized lower bound \(normalizedLowerBound), upper \(normalizedUpperBound)")
        
        if lowerBound < upperBound {
            return cardRotation >= lowerBound && cardRotation <= upperBound
        } else {
            return cardRotation >= lowerBound || cardRotation <= upperBound
        }
    }
    
    func updateHighlights() {
        guard let middleCardIndex = getMiddleCardIndex() else {
            return
        }
        for (i, card) in wordCards.enumerated() {
            if (i == middleCardIndex) {
                card.highlight()
            } else {
                card.unhighlight()
            }
        }
    }
    
    func spinReel(by delta: CGFloat) {
        let rotationAngle = Float(delta / 100)  // Adjust the divisor for sensitivity
        currentRotation += rotationAngle
        reelEntity.transform.rotation *= simd_quatf(angle: rotationAngle, axis: [1, 0, 0])
//        print("currentRotation now \(currentRotation * (180.0 / .pi)) deg, entity's rotation \(reelEntity.transform.rotation)")
        
        // Call updateVisibleCards to manage the visibility of cards during spinning
        updateVisibleCards()
    }
    
    // This function is called when the "select" action (currently long-press) is detected on the wordReel.
    // It should give the user a card that they can put on a Board.
    func selectMiddleCard() -> WordCard? {
        // Calculate middle card
        guard let middleCardIndex = getMiddleCardIndex() else {
            return nil
        }
        let middleCard = wordCards[middleCardIndex]

        // Remove the middle card if replaceWords is false
        if !replaceWords {
            removeCard(middleCard)
        }
        // Return a copy of the middle card
        return WordCard(with: middleCard.word, draggable: true)
    }
    
    // Return the middle card entity.
    private func getMiddleCardIndex() -> Int? {
        let middleRotation = currentRotation
        var closestIndex: Int? = nil
        var closestDistance: Float = .infinity

        for (i, card) in wordCards.enumerated() {
            guard let cardRotationD = cardRotationDict[card.id]?.radians else {
                continue
            }
            let cardRotation = Float(cardRotationD)
            let distance = abs(cardRotation - middleRotation)
            if distance < closestDistance {
                closestDistance = distance
                closestIndex = i
            }
        }
        return closestIndex
    }
    
    private func positionCards() {
        // The cards should be evenly spaced out. We place them in an overlapping circle (so some cards have angles of more than 2pi), and choose which are visible based on the rotation of the Reel.
        for (index, card) in wordCards.enumerated() {
            let angle = Angle(radians: anglePerCard.radians * Double(index))
            let radius: Double = 0.15 // Adjust as needed
            // z is up and y is toward viewer
            let z = radius * cos(angle.radians)
            let y = radius * sin(angle.radians)
            card.modelEntity.position = [0, Float(y), Float(z)] // Adjust positioning as needed
            
            // Record the rotation in the angle dictionary for later
            cardRotationDict[card.id] = angle
        }
    }
}
