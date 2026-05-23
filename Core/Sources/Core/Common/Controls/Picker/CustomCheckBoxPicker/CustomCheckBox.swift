//
//  CustomCheckBox.swift
//
//
//  Created by Ali M. Zaghloul on 8/16/24.
//

import SwiftUI

public struct CustomCheckBox: View {
    
    @Binding var isOn: Bool
    var title: String
    
    var onColor: ColorStyle
    
    public init(isOn: Binding<Bool>,
                title: String,
                onColor: ColorStyle = .primary) {
        self._isOn = isOn
        self.title = title
        self.onColor = onColor
    }
    
    public var body: some View {
        Button(action: {
            isOn.toggle()
        }, label: {
            HStack(spacing: 8) {
                
                if isOn {
                    on
                }
                else {
                    off
                }
                
                titleView
            }
        })
    }
    
    private var on: some View {
        RoundedRectangle(cornerRadius: 4)
            .customFill(onColor)
            .frame(width: 16, height: 16)
            .overlay {
                
                Image.check
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 10, height: 10)
                    .customForeground(.onPrimary)
            }
    }
    
    private var off: some View {
        RoundedRectangle(cornerRadius: 4)
            .customStroke(.neutral)
            .frame(width: 16, height: 16)
    }
    
    private var titleView: some View {
        Text(title)
            .customStyle(.bodySmall,
                         .onSurface)
    }
}

#Preview {
    CustomCheckBoxTest()
}

struct CustomCheckBoxTest: View {
    
    @State var isOn: Bool = false
    
    var body: some View {
        VStack {
            
            CustomCheckBox(isOn: $isOn,
                           title: "Option")
        }
    }
}
