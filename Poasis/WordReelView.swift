//
//  WordReelView.swift
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
    @State private var isDragging = false
    @State private var rootDragStart = SIMD3<Float>()
    @State private var dragOffset = Vector3D()
    
    let id = UUID()

    private var rootEntity = Entity()
    private var plinthEntity = Entity()
    
    private var title: String
    private var color: Color
    private var initialPosition: Vector3D
    
    @State private var isCollapsed: Bool
    
    var selectWordCard: (WordCard) -> Void
    
    init(wordStrings: [String], title: String, color: Color, position: Vector3D, selectWordCard: @escaping (WordCard) -> Void) {
        self.wordReel = WordReel(wordStrings: wordStrings)
        self.selectWordCard = selectWordCard
        
        self.plinthEntity = try! Entity.load(named: "Plinth", in: RealityKitContent.realityKitContentBundle)
        self.plinthEntity.name = "Plinth"
        
        self.title = title
        self.color = color
        
        self.isCollapsed = false
        
        self.initialPosition = position
        self.rootDragStart = .zero
        
        wordReel.updateHighlights()
    }
    
    func closeButtonTapped() {
        // hide the box
        print("close button")
        // Remove this WordReelView from appState
        appState.removeWordReelView(id: self.id)
    }
    
    func collapseButtonTapped() {
        // Collapse the box
        print("hide words")
        self.isCollapsed = !self.isCollapsed
        wordReel.reelEntity.isEnabled = !self.isCollapsed
    }
    
    var body: some View {
        RealityView { content, attachments in
            // Compute position to create word reel at
            let convertedPosition = content.convert(self.initialPosition, from: .immersiveSpace, to: .scene)
            rootEntity.scenePosition = convertedPosition
            rootDragStart = convertedPosition

            content.add(rootEntity)
            rootEntity.addChild(plinthEntity)
            rootEntity.addChild(wordReel.reelEntity)
            wordReel.reelEntity.transform.translation.y += 0.25 // scooch it down
            if let label = attachments.entity(for: "label") {
                rootEntity.addChild(label)
                label.position.z += 0.15
                label.position.y -= 0.1
            }
            print("Finished init")
        } update: { content, attachments in
            if !isDragging { return }  // dirty hack to prevent this from running before init is done
            let convertedDrag = content.convert(dragOffset, from: .local, to: .scene)
            rootEntity.scenePosition = rootDragStart + convertedDrag

        } attachments: {
            Attachment(id: "label") {
                    HStack {
                        
                        Button(action: {
                            self.closeButtonTapped()
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                        }
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                        
                        
                        Text(self.title)
                            .font(.largeTitle)
                            .lineLimit(1)
                            .padding(.horizontal, 2)
                        
                        Button(action: {
                            self.collapseButtonTapped()
                        }) {
                            Image(systemName: self.isCollapsed ? "chevron.up" : "chevron.down")
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                        }
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .background(self.color)
                    .glassBackgroundEffect()
                    
                }
            }
        .gesture(DragGesture()
            .targetedToEntity(plinthEntity)
            .onChanged { value in
                print("in drag gesture got value")
                if !isDragging {
                    isDragging = true
                    rootDragStart = value.entity.scenePosition
                }
                
                let translation3D = value.convert(value.gestureValue.translation3D, from: .local, to: .scene)

                rootEntity.scenePosition = rootDragStart + translation3D
                rootEntity.lookAtCamera(worldInfo: appState.worldInfo)
            }
            .onEnded { value in
                isDragging = false
                rootDragStart = .zero
            }
        )
        
        .gesture(DragGesture()
//                 .targetedToEntity(wordReel.reelEntity)
            .onChanged { value in
                print("drag gesture on reel")
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
        
    static func == (l: WordReelView, r: WordReelView) -> Bool {
        return l.id == r.id
    }
}

#Preview(windowStyle: .volumetric) {
    let words = ["shall", "i", "compare", "thee", "to", "a", "summer's", "day", "?", "thou", "art", "more", "lovely", "and", "more", "temperate", "rough", "winds", "do", "shake", "the", "darling", "buds", "of", "may", "and", "summer's", "lease", "hath", "all", "too", "short", "a", "date"]
    let rootEntity = ModelEntity()
    RealityView { content in
        content.add(rootEntity)
    }
    WordReelView(wordStrings: words, title: "text label", color: Color.blue, position: Vector3D()) {wordCard in
        rootEntity.addChild(wordCard.modelEntity)
    }
    .environment(AppState())
}
