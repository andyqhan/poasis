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
        .allowsHitTesting(false)
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
    let wordlist: WordList
    let action: (String) -> Void
    @State private var isExpanded = false
    @State private var selectedOption = 0
    @GestureState private var translation: CGFloat = 0
    
    private let buttonWidth: CGFloat = 120
    private let buttonHeight: CGFloat = 70
    
    var options: [String] {
        if wordlist.sorted {
            return ["Top 100", "Random 100", "All"]
        } else {
            return ["Random 100", "All"]
        }
    }
    
    var randomWords: [String] {
        // we just pick 100 to scroll through because all of them is often slow
        // TODO: probably be best to use a generator for this in InfiniteScrollView
        var res: [String] = []
        for _ in 0...99 {
            res.append(wordlist.words.randomElement()!)
        }
        return res
    }
    
    var emoji: String {
        switch wordlist.category {
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
        Group {
            if isExpanded {
                HStack(spacing: 8) {
                    // Title section
                    HStack(spacing: 4) {
                        Text(emoji)
                            .font(.system(size: 30))
                        Text(wordlist.name)
                            .font(.headline)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.leading, 20)
                    .frame(width: 150)
                    
                    Spacer()
                    
                    // Button section with arrows
                    HStack(spacing: 10) {
                        // Left arrow button
                        Button(action: {
                            selectedOption = max(0, selectedOption - 1)
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.gray.opacity(0.3)))
                        }
                        .frame(width: buttonWidth/3, height: buttonHeight)
                        .disabled(selectedOption == 0)
                        
                        // Main button
                        Button(action: {
                            print("Calling action with \(options[selectedOption]) on wordlist \(wordlist.name)")
                            action(options[selectedOption])
                            isExpanded = false
                        }) {
                            Text(options[selectedOption])
                                .foregroundColor(.white)
                                .frame(width: buttonWidth, height: buttonHeight)
                                .lineLimit(2)
                                .contentShape(Rectangle())
                        }
                        
                        // Right arrow button
                        Button(action: {
                            selectedOption = min(options.count - 1, selectedOption + 1)
                        }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white)
                                .frame(width: 30, height: 44)
                                .background(Circle().fill(Color.gray.opacity(0.3)))
                        }
                        .frame(width: buttonWidth/3, height: buttonHeight)
                        .disabled(selectedOption == options.count - 1)
                    }
                    .overlay(
                        HStack(spacing: 4) {
                            ForEach(0..<options.count, id: \.self) { index in
                                Circle()
                                    .fill(selectedOption == index ? Color.white : Color.white.opacity(0.5))
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .padding(.bottom, 4),
                        alignment: .bottom
                    )
                    .padding(.trailing, 20)
                    
                }
            } else {
                HStack(spacing: 0) {
                    Spacer()
                        .frame(width: 20)
                    
                    Text(emoji)
                        .font(.system(size: 50))
                    
                    GeometryReader { geometry in
                        ChevronShape()
                            .stroke(wordlist.swiftUIColor.darker(), lineWidth: 5)
                            .frame(width: geometry.size.width * 0.75, height: geometry.size.height)
                    }
                    .frame(width: 30)
                    
                    Text(wordlist.name)
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                    
                    GeometryReader { geometry in
                        ChevronShape()
                            .stroke(wordlist.swiftUIColor.darker(), lineWidth: 5)
                            .frame(width: geometry.size.width * 0.75, height: geometry.size.height)
                    }
                    .frame(width: 30)
                    
                    GeometryReader { geometry in
                        
                        InfiniteVerticalScrollView(strings: randomWords, width: geometry.size.width, bgColor: wordlist.swiftUIColor)
                            .frame(width: geometry.size.width)
                    }
                    
                    Spacer()
                        .frame(width: 20)
                }
            }
        }
        .frame(width: 400, height: 100)
        .background(wordlist.swiftUIColor)
        .cornerRadius(40)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }
    }
}

// Custom button style for the action buttons
struct ChipActionButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color.darker())
            .foregroundColor(.white)
            .cornerRadius(20)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .frame(maxWidth: .infinity)  // Make the button fill its container
            .minimumScaleFactor(0.8)  // Allow text to scale down if needed
    }
}

// Extension to make buttons more compact
extension Button {
    func chipStyle(color: Color) -> some View {
        self.buttonStyle(ChipActionButtonStyle(color: color))
    }
}

#Preview {
    let wordlist = WordList(category: "test category", name: "Test wordlist", color: "blue", words: "oh might those sighs and tears return again into my breast and eyes which i have spent".split(separator: " ").map(String.init), sorted: true)
    
    Chip(wordlist: wordlist) { selectedOption in
        print("action", selectedOption)
        return
    }
}
