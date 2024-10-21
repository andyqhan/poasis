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
    @State private var offsetY: CGFloat = 0
    @State private var contentHeight: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .offset(y: offsetY)
        .onAppear {
            // Start the animation after the content height is measured
            if contentHeight > 0 {
                startAnimation()
            }
        }
        .onChange(of: contentHeight) { _, _ in
            // Restart the animation if the content height changes
            if contentHeight > 0 {
                startAnimation()
            }
        }
    }

    var content: some View {
        VStack(spacing: 0) {
            ForEach(strings.indices, id: \.self) { index in
                Text(strings[index])
                    .frame(maxWidth: .infinity)
            }
        }
        .background(
            GeometryReader { geometry in
                Color.clear.preference(key: ContentHeightPreferenceKey.self, value: geometry.size.height)
            }
        )
        .onPreferenceChange(ContentHeightPreferenceKey.self) { value in
            contentHeight = value
        }
    }

    func startAnimation() {
        // Reset offset to 0 before starting the animation
        offsetY = 0
        let animation = Animation.linear(duration: Double(contentHeight) / 50) // Adjust speed by changing the divisor
            .repeatForever(autoreverses: true)
        withAnimation(animation) {
            offsetY = -contentHeight
        }
    }
}

//struct ScrollingWordsView: View {
//    let words: [String]
//    @State private var scrollOffset: CGFloat = 0
//    @State private var timer: Timer? = nil
//    
//    var loopedWords: [String] {
//        words + words
//    }
//    
//    var body: some View {
//        GeometryReader { geometry in
//            ScrollView(.vertical, showsIndicators: false) {
//                VStack(spacing: 10) {
//                    ForEach(loopedWords, id: \.self) { word in
//                        Text(word)
//                            .font(.body)
//                    }
//                }
//                .padding()
//                .offset(y: scrollOffset)
//                .onAppear {
//                    // Start the scrolling animation when the view appears
//                    startScrolling(wordCount: words.count)
//                }
//                .onDisappear {
//                    // Stop the timer when the view disappears
//                    stopScrolling()
//                }
//            }
//        }
//        .frame(height: 50) // Adjust frame height as needed
//    }
//    
//    // Method to start the scrolling animation
//    func startScrolling(wordCount: Int) {
//        let totalContentHeight = wordCount * (15 + 10)
//        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
//            withAnimation(.linear(duration: 0.2)) {
//                scrollOffset -= 1 // Adjust scrolling speed here
//                if Int(scrollOffset) < -totalContentHeight {
//                    scrollOffset = 0 // Reset offset to create a continuous scroll
//                }
//            }
//        }
//    }
//    
//    // Method to stop the scrolling when the view disappears
//    func stopScrolling() {
//        timer?.invalidate()
//        timer = nil
//    }
//}


struct ChevronShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Start at the top-left of the rect
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        
        // Inverted curve from top-left to middle-right (convex side up)
        
        let xControl = rect.midX * 0.7
        let yOffset = rect.midY * 0.3

        let topControl = CGPoint(x: xControl, y: rect.midY - yOffset)
        let botControl = CGPoint(x: xControl, y: rect.midY + yOffset)
        
        path.addCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control1: topControl, control2: topControl)
        
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        
        path.addCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control1: botControl, control2: botControl)

        return path
    }
}

struct Chip: View {
    let category: Category
    let wordlist: WordList
    let action: () -> Void
    
    var emoji: String {
        switch category.category {
        default:
            return "📦"
        }
    }
    
    var body: some View {
        Button (action: {
            action()
        }) {
            HStack {
                Spacer()
                
                // emoji
                Text(emoji)
                    .font(.system(size: 50))
                
                // chevron shape
                GeometryReader { geometry in
                    ChevronShape()
                        .stroke(Color.black, lineWidth: 2) // Change color and line width as needed
                        .frame(width: geometry.size.width * 0.75, height: geometry.size.height)
                }
                .frame(width: 30) // Adjust size of chevron as needed
                
                // title
                Text(wordlist.title)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                
                // chevron shape
                GeometryReader { geometry in
                    ChevronShape()
                        .stroke(Color.black, lineWidth: 2) // Change color and line width as needed
                        .frame(width: geometry.size.width * 0.75, height: geometry.size.height)
                }
                .frame(width: 30) // Adjust size of chevron as needed
                
                // scrolling thing
                InfiniteVerticalScrollView(strings: wordlist.words)
                Spacer()
                    .frame(maxWidth: .infinity)
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
