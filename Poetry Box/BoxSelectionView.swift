//
//  BoxSelectionView.swift
//  Poetry Box
//
//  Created by Andy Han on 8/17/24.
//

import Foundation
import SwiftUI

struct WordList: Codable {
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

struct Category: Codable {
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


struct Chip: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button (action: {
            action()
        }) {
            VStack {
                HStack {
                    Text(title)
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding([.top, .leading], 10)
                    Spacer()
                }
                
                Spacer()
            }
           
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 150, height: 100)
        .background(color)
        .cornerRadius(10)

        
    }
}

struct BoxSelectionView: View {
    @ObservedObject var dataLoader = DataLoader()
    var onSelected: (([String], String, Color) -> Void) // callback closure
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack {

            Text("Pick a box!")
                .font(.largeTitle)
                .padding()
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach(dataLoader.categories.flatMap { $0.wordlists }, id: \.title) { wordlist in
                        Chip(title: wordlist.title, color: wordlist.swiftUIColor) {
                            let words = deduplicate(array: wordlist.words)
                            if wordlist.sorted {
                                onSelected(words, wordlist.title, wordlist.swiftUIColor)
                            } else {
                                // randomize
                                onSelected(words.shuffled(), wordlist.title, wordlist.swiftUIColor)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .frame(width: 700, height: 500)
        .cornerRadius(20)
        .shadow(radius: 10)
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
    BoxSelectionView() { wordlist, title, color in
        print("Selected wordlist \(wordlist)")
    }
}
