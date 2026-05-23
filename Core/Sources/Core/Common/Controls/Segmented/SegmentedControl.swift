//
//  SegmentedControl.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI

public struct SegmentedControl: View {
    
    @Namespace private var namespace
    @Namespace private var backgroundRectangleId
    
    @Binding var selectedIndex: Int
    
    @State var selectedIndexForAnimation: Int = 0
    
    var options: [String]
    
    var selectedTextColor: ColorStyle
    var notSelectedTextColor: ColorStyle
    var selectedSegmentedColor: ColorStyle
    var backgroundColor: ColorStyle
    
    var withAnimation: Bool
    var animationDuration: Double
    
    public init(selectedIndex: Binding<Int>,
                options: [String] = [],
                selectedTextColor: ColorStyle = .onPrimary,
                notSelectedTextColor: ColorStyle = .subtitle,
                selectedSegmentedColor: ColorStyle = .primary,
                backgroundColor: ColorStyle = .container,
                withAnimation: Bool = true,
                animationDuration: Double = 0.1) {
        self._selectedIndex = selectedIndex
        self.options = options
        self.selectedTextColor = selectedTextColor
        self.notSelectedTextColor = notSelectedTextColor
        self.selectedSegmentedColor = selectedSegmentedColor
        self.backgroundColor = backgroundColor
        self.withAnimation = withAnimation
        self.animationDuration = animationDuration
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            
            ForEach(options.indices, id: \.self) { index in
                let isSelected = selectedIndexForAnimation == index
                
                Button(action: {
                    updateSelectedTab(to: index)
                }, label: {
                    
                    Text(options[index])
                        .customFont(isSelected ? .subheadline : .bodySmall)
                        .customForeground(isSelected ? selectedTextColor : notSelectedTextColor)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: isSelected ? .infinity : .none)
                })
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 6)
                            .customFill(selectedSegmentedColor)
                            .matchedGeometryEffect(id: backgroundRectangleId, in: namespace)
                    }
                }
            }
        }
        .padding(.all, 6)
        .customBackground(backgroundColor)
        .customCornerRadius(12)
        .onAppear {
            selectedIndexForAnimation = selectedIndex
        }
    }
    
    private func updateSelectedTab(to index: Int) {
        if selectedIndex == index {
            return
        }
        
        selectedIndex = index
        
        if withAnimation {
            withOptionalAnimation(Animation.linear(duration: animationDuration)) {
                selectedIndexForAnimation = index
            }
        }
        else {
            selectedIndexForAnimation = index
        }
    }
}

#Preview {
    SegmentedControlTest()
}

struct SegmentedControlTest: View {
    
    @State var index: Int = 0
    
    var options: [String] = ["Option 1",
                             "Option 2",
                             "Option 3"]
    
    var body: some View {
        VStack {
            
            SegmentedControl(selectedIndex: $index,
                             options: options)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .customBackground(.surface)
    }
}
