//
//  BoxChipView.swift
//  Poasis
//
//  Created by Andy Han on 10/21/24.
//

import Foundation
import SwiftUI

struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        // We only need the first value, as all contents have the same height
        if value == 0 {
            value = nextValue()
        }
    }
}

struct InfiniteVerticalScrollView: View {
    let strings: [String]
    let width: CGFloat
    let bgColor: Color
    @State private var offset: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    private let scrollSpeed: Double = 50
    private let fadeHeight: CGFloat = 20  // Height of fade effect
    
    private let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Main scrolling content
                VStack(spacing: 6) {
                    ForEach(strings, id: \.self) { string in
                        Text(string)
                            .padding(.vertical, 5)
                            .frame(width: width, alignment: .center)
                            .lineLimit(1)
                    }
                    
                    ForEach(strings, id: \.self) { string in
                        Text(string)
                            .padding(.vertical, 5)
                            .frame(width: width, alignment: .center)
                            .lineLimit(1)
                    }
                }
                .background(
                    GeometryReader { contentGeometry in
                        Color.clear.onAppear {
                            contentHeight = contentGeometry.size.height / 2
                        }
                    }
                )
                .offset(y: offset)
                .onReceive(timer) { _ in
                    offset -= scrollSpeed / 60
                    if -offset >= contentHeight {
                        offset = 0
                    }
                }
                
                // Top fade gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        bgColor,
                        bgColor.opacity(0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: fadeHeight)
                
                // Bottom fade gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        bgColor.opacity(0),
                        bgColor
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: fadeHeight)
                .position(x: geometry.size.width / 2, y: geometry.size.height - fadeHeight / 2)
            }
        }
        .frame(width: width)
        .clipped()
    }
}


struct ChevronShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Start at the top-left of the rect
        path.move(to: CGPoint(x: rect.minX - 5, y: rect.minY - 5))
        
        let xControl = rect.midX * 0.7
        let yOffset = rect.midY * 0.3
        
        let topControl = CGPoint(x: xControl, y: rect.midY - yOffset)
        let botControl = CGPoint(x: xControl, y: rect.midY + yOffset)
        
        // Create a continuous path that forms the chevron
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control1: topControl,
            control2: topControl
        )
        
        // Continue the path downward, no need to move
        path.addCurve(
            to: CGPoint(x: rect.minX - 5, y: rect.maxY + 5),
            control1: botControl,
            control2: botControl
        )
        
        return path
    }
}

extension Color {
    /// Creates a darker version of the color by reducing its brightness
    /// - Parameter percentage: Amount to darken the color by (0-100)
    /// - Returns: A new Color that's darker than the original
    func darker(by percentage: Double = 30) -> Color {
        guard percentage > 0, percentage <= 100 else {
            return self
        }
        
        // Convert Color to UIColor for color space manipulation
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        // Get the HSB values from the color
        uiColor.getHue(&hue,
                      saturation: &saturation,
                      brightness: &brightness,
                      alpha: &alpha)
        
        // Reduce brightness by the specified percentage
        let newBrightness = max(0, brightness * (1 - percentage/100))
        
        // Create new UIColor with adjusted brightness
        let darkerColor = UIColor(hue: hue,
                                saturation: saturation,
                                brightness: newBrightness,
                                alpha: alpha)
        
        // Convert back to SwiftUI Color
        return Color(uiColor: darkerColor)
    }
}

struct Chip: View {
    let category: Category
    let wordlist: WordList
    let action: () -> Void
    
    var emoji: String {
        switch category.category {
        case "nouns":
            return "📦"
        case "verbs":
            return ""
        case "utilities":
            return "🔧"
        default:
            return "📦"
        }
    }
    
    var body: some View {
        Button(action: {
            action()
        }) {
            HStack(spacing: 0) {  // Set spacing to 0 for precise control
                Spacer()
                    .frame(width: 20)  // Adjust left padding as needed
                
                Text(emoji)
                    .font(.system(size: 50))
                
                GeometryReader { geometry in
                    ChevronShape()
                        .stroke(wordlist.swiftUIColor.darker(), lineWidth: 5)
                        .frame(width: geometry.size.width * 0.75, height: geometry.size.height)
                }
                .frame(width: 30)
                
                Text(wordlist.title)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                
                GeometryReader { geometry in
                    ChevronShape()
                        .stroke(wordlist.swiftUIColor.darker(), lineWidth: 5)
                        .frame(width: geometry.size.width * 0.75, height: geometry.size.height)
                }
                .frame(width: 30)
                
                // Use GeometryReader to calculate remaining space
                GeometryReader { geometry in
                    InfiniteVerticalScrollView(strings: wordlist.words, width: geometry.size.width, bgColor: wordlist.swiftUIColor)
                        .frame(width: geometry.size.width)
                }
                
                Spacer()
                    .frame(width: 20)  // Adjust right padding as needed
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 400, height: 100)
        .background(wordlist.swiftUIColor)
        .cornerRadius(10)
    }
}

#Preview {
    let wordlist = WordList(title: "Test wordlist", color: "blue", words: "oh might those sighs and tears return again into my brest and eyes which i have spent".split(separator: " ").map(String.init), sorted: false)
    let category = Category(category: "Test category", wordlists: [wordlist])
    
    return Chip(category: category, wordlist: wordlist) {
        print("action")
        return
    }
}
