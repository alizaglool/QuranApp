//
//  StarRatingView.swift
//  Core
//
//  Created by Ali M. Zaghloul on 30/06/2025.
//


import SwiftUI

public struct StarRatingView: View {
    @Binding var rating: Int
    let maxRating: Int
    let starSize: CGFloat
    let starSpacing: CGFloat
    let fillColor: Color
    let strokeColor: Color
    let isInteractive: Bool
    
    @State private var tempRating: Int = 0
    
    public init(
        rating: Binding<Int>,
        maxRating: Int = 5,
        starSize: CGFloat = 40,
        starSpacing: CGFloat = 8,
        fillColor: Color = .yellow,
        strokeColor: Color = .gray.opacity(0.3),
        isInteractive: Bool = true
    ) {
        self._rating = rating
        self.maxRating = maxRating
        self.starSize = starSize
        self.starSpacing = starSpacing
        self.fillColor = fillColor
        self.strokeColor = strokeColor
        self.isInteractive = isInteractive
    }
    
    public var body: some View {
        HStack(spacing: starSpacing) {
            ForEach(1...maxRating, id: \.self) { star in
                starView(for: star)
            }
        }
    }
    
    private func starView(for star: Int) -> some View {
        ZStack {
            // Background star (stroke/border)
            StarShape()
                .fill(strokeColor)
                .frame(width: starSize, height: starSize)
            
            // Foreground star (filled)
            StarShape()
                .fill(star <= (tempRating > 0 ? tempRating : rating) ? fillColor : Color.clear)
                .frame(width: starSize - 4, height: starSize - 4) // Slightly smaller for border effect
        }
        .scaleEffect(star <= (tempRating > 0 ? tempRating : rating) ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: tempRating)
        .animation(.easeInOut(duration: 0.2), value: rating)
        .onTapGesture {
            if isInteractive {
                rating = star
                hapticFeedback()
            }
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0)
                .onChanged { _ in
                    if isInteractive {
                        tempRating = star
                    }
                }
                .onEnded { _ in
                    if isInteractive {
                        tempRating = 0
                        rating = star
                        hapticFeedback()
                    }
                }
        )
    }
    
    private func hapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius * 0.4
        
        let angle = -Double.pi / 2
        let angleIncrement = Double.pi * 2 / 5
        
        for i in 0..<10 {
            let isOuter = i % 2 == 0
            let currentRadius = isOuter ? radius : innerRadius
            let currentAngle = angle + (angleIncrement * Double(i) / 2)
            
            let x = center.x + cos(currentAngle) * currentRadius
            let y = center.y + sin(currentAngle) * currentRadius
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
}

#Preview {
    VStack(spacing: 30) {
        StarRatingView(rating: .constant(3))
        
        StarRatingView(
            rating: .constant(4),
            starSize: 30,
            fillColor: .orange
        )
        
        StarRatingView(
            rating: .constant(5),
            starSize: 35,
            fillColor: .red,
            isInteractive: false
        )
    }
    .padding()
}
