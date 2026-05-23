//
//  CustomSlider.swift
//  
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI

public struct CustomSlider: View {
    
    @Binding var value: Double
    var range: ClosedRange<Double>
    var secondaryValue: Double
    
    var axis: Axis
    var thumbDimension: CGFloat?
    
    var backgroundColor: ColorStyle
    var progressColor: ColorStyle
    var secondaryProgressColor: ColorStyle
    var thumbColor: ColorStyle
    
    var onChangingValue: GenericAction<Double>
    var onChangingEnded: EmptyAction
    
    @State var size: CGSize = .zero
    
    @State var isSliding: Bool = false
    
    @State private var progress: CGFloat = .zero
    @State private var dragOffset: CGFloat = .zero
    @State private var lastDragOffset: CGFloat = .zero
    
    private var lower: Double { range.lowerBound }
    private var upper: Double { range.upperBound }
    private var scaleFactor: Double { upper - lower }
    
    private var isHorizontal: Bool { axis == .horizontal }
    private var isVertical: Bool { axis == .vertical }
    private var alignment: Alignment { isHorizontal ? .leading : .bottom }
    
    private var thumbActualDimension: CGFloat {
        thumbDimension != nil ? thumbDimension! : (isHorizontal ? size.height : size.width)
    }
    
    private var orientationSize: Double { isHorizontal ? size.width : size.height }
    private var progressValue: Double { progress * orientationSize }
    
    private var thumbOffsetValue: Double { progressValue - (thumbActualDimension / 2) }
    
    private var secondaryProgress: CGFloat { scaleFactor != 0 ? secondaryValue / scaleFactor : 0 }
    private var secondaryProgressValue: Double { secondaryProgress * orientationSize }
    
    public init(value: Binding<Double>,
                range: ClosedRange<Double>,
                secondaryValue: Double = 0,
                axis: Axis = .horizontal,
                thumbDimension: CGFloat? = nil,
                backgroundColor: ColorStyle = .neutral,
                progressColor: ColorStyle = .primary,
                secondaryProgressColor: ColorStyle = .subtitle,
                thumbColor: ColorStyle = .primary,
                onChangingValue: GenericAction<Double> = nil,
                onChangingEnded: EmptyAction = nil) {
        self._value = value
        self.range = range
        self.secondaryValue = secondaryValue
        self.axis = axis
        self.thumbDimension = thumbDimension
        self.backgroundColor = backgroundColor
        self.progressColor = progressColor
        self.secondaryProgressColor = secondaryProgressColor
        self.thumbColor = thumbColor
        self.onChangingValue = onChangingValue
        self.onChangingEnded = onChangingEnded
    }
    
    public var body: some View {
        ZStack(alignment: alignment) {
            
            Rectangle()
                .customFill(backgroundColor)
            
            Rectangle()
                .customFill(secondaryProgressColor)
                .frame(width: isHorizontal ? secondaryProgressValue : nil,
                       height: isVertical ? secondaryProgressValue : nil)
            
            Rectangle()
                .customFill(progressColor)
                .frame(width: isHorizontal ? progressValue : nil,
                       height: isVertical ? progressValue : nil)
        }
        .onChange(of: value, perform: { value in
            // Changes from outside the view
            
            updateProgress()
        })
        .readSize(to: $size)
        .overlay(alignment: alignment) {
            
            Circle()
                .customFill(thumbColor)
                .frame(width: thumbActualDimension, height: thumbActualDimension)
                .frame(width: 32, height: 32)
                .contentShape(.rect)
                .offset(x: isHorizontal ? thumbOffsetValue : 0)
                .offset(y: isVertical ? -thumbOffsetValue : 0)
                .gesture(DragGesture()
                    .onChanged { value in
                        
                        isSliding = true
                        
                        let change: CGFloat = (isHorizontal ? value.translation.width : -value.translation.height)
                        
                        dragOffset = change + lastDragOffset
                        
                        let progress = dragOffset / orientationSize
                        
                        self.progress = max(min(progress, 1), 0)
                        
                        self.value = self.progress * scaleFactor + lower
                        
                        onChangingValue?(self.value)
                    }
                    .onEnded { _ in
                        
                        lastDragOffset = dragOffset
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            isSliding = false
                        }
                        
                        onChangingEnded?()
                    }
                )
                .frame(width: thumbActualDimension, height: thumbActualDimension)
        }
        .onAppear {
            updateProgress()
        }
    }
    
    private func updateProgress() {
        if !isSliding {
            progress = value / (scaleFactor != 0 ? scaleFactor : 1)
            lastDragOffset = progressValue
        }
    }
}

#Preview {
    CustomSliderTest()
}

struct CustomSliderTest: View {
    
    @State var progress: Double = 6
    @State var range = 0.0...10.0
    @State var secondaryValue: Double = 5
    
    var body: some View {
        VStack {
            
            CustomSlider(value: $progress,
                         range: range,
                         secondaryValue: secondaryValue,
                         axis: .vertical,
                         thumbDimension: 8)
            .frame(width: 3)
            .padding(.all, 60)
            
            CustomSlider(value: $progress,
                         range: range,
                         secondaryValue: secondaryValue,
                         thumbDimension: 8)
            .frame(height: 3)
            .padding(.all, 60)
            .disabled(true)
            
            CustomSlider(value: $progress,
                         range: range,
                         secondaryValue: secondaryValue,
                         thumbDimension: 8)
            .frame(height: 3)
            .padding(.all, 60)
        }
        .onAppear(perform: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                progress = 5
                secondaryValue = 6
            })
        })
    }
}
