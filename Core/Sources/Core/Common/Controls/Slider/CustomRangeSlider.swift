//
//  CustomRangeSlider.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI

public struct CustomRangeSlider: View {
    
    @Binding var value: ClosedRange<Int>
    var range: ClosedRange<Int>
    
    var thumbDimension: CGFloat
    var sliderHeight: CGFloat
    
    var backgroundColor: ColorStyle
    var progressColor: ColorStyle
    var thumbColor: ColorStyle
    
    @State private var size: CGSize = .zero
    
    public init(value: Binding<ClosedRange<Int>>,
                range: ClosedRange<Int>,
                thumbDimension: CGFloat = 16,
                sliderHeight: CGFloat = 10,
                backgroundColor: ColorStyle = .primaryOpacity(opacity: 0.3),
                progressColor: ColorStyle = .primary,
                thumbColor: ColorStyle = .primary) {
        self._value = value
        self.range = range
        self.thumbDimension = thumbDimension
        self.sliderHeight = sliderHeight
        self.backgroundColor = backgroundColor
        self.progressColor = progressColor
        self.thumbColor = thumbColor
    }
    
    public var body: some View {
        sliderView
            .readSize(to: $size)
    }
    
    @ViewBuilder private var sliderView: some View {
        let sliderViewYCenter = size.height / 2
        
        RoundedRectangle(cornerRadius: 5)
            .customFill(backgroundColor)
            .frame(height: sliderHeight)
            .overlay {
                
                ZStack {
                    let sliderBoundDifference = range.count
                    let stepWidthInPixel = CGFloat(size.width) / CGFloat(sliderBoundDifference)
                    
                    // Calculate Left Thumb initial position
                    let leftThumbLocation: CGFloat = value.lowerBound == range.lowerBound
                    ? 0
                    : CGFloat(value.lowerBound - range.lowerBound) * stepWidthInPixel
                    
                    // Calculate right thumb initial position
                    let rightThumbLocation = CGFloat(value.upperBound) * stepWidthInPixel
                    
                    
                    let leftThumbPoint = CGPoint(x: leftThumbLocation, y: sliderViewYCenter)
                    let rightThumbPoint = CGPoint(x: rightThumbLocation, y: sliderViewYCenter)
                    
                    lineBetweenThumbs(from: CGPoint(x: leftThumbLocation, y: sliderViewYCenter),
                                      to: CGPoint(x: rightThumbLocation, y: sliderViewYCenter))
                    
                    thumbView(position: leftThumbPoint,
                              value: value.lowerBound)
                    .highPriorityGesture(DragGesture().onChanged { dragValue in
                        
                        let dragLocation = dragValue.location
                        let xThumbOffset = min(max(0, dragLocation.x), size.width)
                        
                        let newValue = range.lowerBound + Int(xThumbOffset / stepWidthInPixel)
                        
                        // Stop the range thumbs from colliding each other
                        if newValue < value.upperBound {
                            value = newValue...value.upperBound
                        }
                    })
                    
                    // Right Thumb Handle
                    thumbView(position: rightThumbPoint,
                              value: value.upperBound)
                    .highPriorityGesture(DragGesture().onChanged { dragValue in
                        let dragLocation = dragValue.location
                        let xThumbOffset = min(max(CGFloat(leftThumbLocation), dragLocation.x), size.width)
                        
                        var newValue = Int(xThumbOffset / stepWidthInPixel) // convert back the value bound
                        newValue = min(newValue, range.upperBound)
                        
                        // Stop the range thumbs from colliding each other
                        if newValue > value.lowerBound {
                            value = value.lowerBound...newValue
                        }
                    })
                }
            }
    }
    
    func lineBetweenThumbs(from: CGPoint, to: CGPoint) -> some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
        .customStroke(progressColor, lineWidth: sliderHeight)
    }
    
    func thumbView(position: CGPoint, value: Int) -> some View {
        
        Circle()
            .customFill(thumbColor)
            .frame(width: thumbDimension, height: thumbDimension)
            .position(x: position.x, y: position.y)
    }
}

#Preview {
    CustomRangeSliderTest()
}

struct CustomRangeSliderTest: View {
    
    @State private var value: ClosedRange<Int> = 1...10
    private var range: ClosedRange<Int> = 1...100
    
    var body: some View {
        CustomRangeSlider(value: $value,
                          range: range)
        .padding(.horizontal, 16)
    }
}
