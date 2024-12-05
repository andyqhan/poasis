//
//  BoxSelectionView.swift
//
//  Created by Andy Han on 8/17/24.
//

import Foundation
import SwiftUI
import RealityKit

struct WordList: Codable, Identifiable {
    var id: String { name }
    let category: String
    let name: String
    let color: String  // hex color code
    let words: [String]
    let sorted: Bool
    
    var swiftUIColor: Color {
        // Remove the '#' if present
        let hexString = color.hasPrefix("#") ? String(color.dropFirst()) : color
        // Convert hex to integer
        guard let hexInt = UInt32(hexString, radix: 16) else {
            return .gray // Default color in case of invalid hex
        }
        let red = Double((hexInt & 0xFF0000) >> 16) / 255.0
        let green = Double((hexInt & 0x00FF00) >> 8) / 255.0
        let blue = Double(hexInt & 0x0000FF) / 255.0
        return Color(red: red, green: green, blue: blue)
    }
    
    enum Selectors: String, Codable {
        case top100 = "Top 100"
        case rand100 = "Random 100"
        case all = "All"
    }
    
    func getListFromSelector(selectorString: String) -> [String] {
        if let selector = Selectors(rawValue: selectorString) {
            switch selector {
            case .top100:
                return Array(words.prefix(100))
            case .rand100:
                var rands: [String] = []
                for _ in 0...99 {
                    // TODO: needs to be without replacement
                    rands.append(words.randomElement()!)
                }
                return rands
            case .all:
                if sorted {
                    return words
                }
                return words.shuffled()
            }
        } else {
            return []
        }
    }
}

struct Category: Codable, Identifiable {
    var id = UUID()
    let category: String
    let wordlists: [WordList]
    
    private enum CodingKeys: CodingKey {
        case category
        case wordlists
    }
}

class DataLoader: ObservableObject {
    @Published var wordlists: [WordList] = []
    
    init() {
        // Since we can't make init async directly, we trigger the async load
        Task {
            await loadAll()
        }
    }
    
    private func loadAll() async {
        // Load both files concurrently
        async let list1 = load(name: "pf_wordlist")
        async let list2 = load(name: "gut_wordlist")
        async let list3 = load(name: "magnetic_poetry")
        
        // Wait for both loads to complete and handle any errors
        do {
            let (pfList, gutList, mpList) = try await (list1, list2, list3)
            // Update UI on main thread since we're modifying @Published property
            await MainActor.run {
                wordlists.append(contentsOf: pfList)
                wordlists.append(contentsOf: gutList)
                wordlists.append(contentsOf: mpList)
            }
        } catch {
            print("Error loading JSON: \(error)")
        }
    }
    
    private func load(name: String) async throws -> [WordList] {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            throw LoadError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode([WordList].self, from: data)
    }
    
    enum LoadError: Error {
        case fileNotFound
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
                    VStack(spacing: 10) {
                        ForEach(dataLoader.wordlists) { wordlist in
                            Chip(wordlist: wordlist) { selectedOption in
                                if let translation = proxy.transform(in: .immersiveSpace)?.translation {
                                    let newWordReelView = WordReelView(
                                        wordStrings: wordlist.getListFromSelector(selectorString: selectedOption),
                                        title: wordlist.name,
                                        color: wordlist.swiftUIColor,
                                        position: translation
                                    ) { newCard in
                                        appState.rootEntity.addChild(newCard.modelEntity)
                                    }
                                    appState.wordReelViews.append(newWordReelView)
                                }
                            }
                        }
                    }
                    
                }
            }
            .task {
                await openImmersiveSpace(id: "ImmersiveSpace")
                appState.isImmersiveSpaceOpen = true
            }
        }
        .frame(width: 400)  // the Chips are width 400
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
}
