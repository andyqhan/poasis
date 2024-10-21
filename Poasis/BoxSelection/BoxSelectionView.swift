//
//  BoxSelectionView.swift
//
//  Created by Andy Han on 8/17/24.
//

import Foundation
import SwiftUI
import RealityKit

struct WordList: Codable, Identifiable {
    var id: String { title }
    let title: String
    let color: String
    let words: [String]
    let sorted: Bool
    
    var swiftUIColor: Color {
        switch color.lowercased() {
        case "red":
            return .red
        case "green":
            return .green
        case "blue":
            return .blue
        case "orange":
            return .orange
        case "purple":
            return .purple
        case "pink":
            return .pink
        case "yellow":
            return .yellow
        case "gray":
            return .gray
        case "brown":
            return .brown
        default:
            print("Couldn't find color for: \(color)")
            return .gray // Fallback color
        }
    }
}

struct Category: Codable, Identifiable {
    var id = UUID()
    let category: String
    let wordlists: [WordList]
}

class DataLoader: ObservableObject {
    @Published var categories: [Category] = []
    
    init() {
        load()
    }
    
    func load() {
        if let url = Bundle.main.url(forResource: "WordData", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                categories = try decoder.decode([Category].self, from: data)
            } catch {
                print("Error loading JSON: \(error)")
            }
        }
    }
}

struct BoxSelectionView: View {
    @ObservedObject var dataLoader = DataLoader()
    @Environment(AppState.self) private var appState
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        GeometryReader3D { proxy in
            VStack {
                Spacer()
                Text("Poasis")
                    .font(.largeTitle)
                    .padding()
                
                ScrollView(.vertical, showsIndicators: false) {
                    ForEach(dataLoader.categories) { category in
                        ForEach(category.wordlists) { wordlist in
                            Chip(category: category, wordlist: wordlist) {
                                print("action")
                            }
                        }
                    }
//                        ForEach(dataLoader.categories.flatMap { $0.wordlists }, id: \.title) { wordlist in
//                            Chip(title: wordlist.title, color: wordlist.swiftUIColor) {
//                                let words = deduplicate(array: wordlist.words)
//                                if let translation = proxy.transform(in: .immersiveSpace)?.translation {
//                                    if wordlist.sorted {
//                                        let newWordReelView = WordReelView(wordStrings: words, title: wordlist.title, color: wordlist.swiftUIColor, position: translation) { newCard in
//                                            appState.rootEntity.addChild(newCard.modelEntity)
//                                        }
//                                        appState.wordReelViews.append(newWordReelView)
//                                    } else {
//                                        // randomize
//                                        let newWordReelView = WordReelView(wordStrings: words.shuffled(), title: wordlist.title, color: wordlist.swiftUIColor, position: translation) { newCard in
//                                            appState.rootEntity.addChild(newCard.modelEntity)
//                                        }
//                                        appState.wordReelViews.append(newWordReelView)
//                                    }
//                                }
//                            }
//                        }
                    }
                    .frame(maxWidth: .infinity) // Ensures it takes as much space as needed
                    .fixedSize(horizontal: true, vertical: false)
            }
            .task {
                await openImmersiveSpace(id: "ImmersiveSpace")
                appState.isImmersiveSpaceOpen = true
            }
        }
        .padding()
        .glassBackgroundEffect()
    }
    
    private func calculateGridWidth() -> CGFloat {
        let chipWidth: CGFloat = 100
        let spacing: CGFloat = 15
        let totalWidth = (chipWidth * CGFloat(columns.count)) + (spacing * CGFloat(columns.count - 1))
        return totalWidth
    }
    
    private func deduplicate<T: Hashable>(array: [T]) -> [T] {
        var seen = Set<T>()
        var result = [T]()
        
        for element in array {
            if !seen.contains(element) {
                seen.insert(element)
                result.append(element)
            }
        }
        
        return result
    }
}

#Preview {
    BoxSelectionView()
        .environment(AppState())
        .frame(minWidth: 200, maxWidth: .infinity) // Sets the frame to a minimum and maximum
        .fixedSize(horizontal: true, vertical: false)
}
