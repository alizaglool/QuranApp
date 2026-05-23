//
//  CustomCheckBoxPicker.swift
//
//
//  Created by Ali M. Zaghloul on 8/16/24.
//

import SwiftUI

public struct CustomCheckBoxPicker<Item: CustomCheckBoxPickerItem>: View {
    
    @Binding var items: [Item]
    
    var onColor: ColorStyle
    
    public init(items: Binding<[Item]>,
                onColor: ColorStyle = .primary) {
        self._items = items
        self.onColor = onColor
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            ForEach(items) { item in
                
                getItemView(item: item)
            }
        }
    }
    
    private func getItemView(item: Item) -> some View {
        Button(action: {
            selectedItem(item: item)
        }, label: {
            HStack(spacing: 8) {
                
                if item.isOn {
                    on
                }
                else {
                    off
                }
                
                titleView(item)
            }
        })
    }
    
    private func titleView(_ item: Item) -> some View {
        Text(item.displayName)
            .customStyle(.bodySmall, .onSurface)
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
    
    private func selectedItem(item: Item) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            
            withOptionalAnimation {
                items[index].isOn.toggle()
            }
        }
    }
}

#Preview {
    CustomCheckBoxPickerTest()
}

struct CustomCheckBoxPickerTest: View {
    
    @State var model: [CustomCheckBoxPickerItemModel] = ["Option 1", "Option 2", "Option 3", "Option 4", "Option 5", "Option 6"].map { CustomCheckBoxPickerItemModel(displayName: $0)
    }
    
    var body: some View {
        VStack {
            
            Spacer()
            
            CustomCheckBoxPicker(items: $model)
            
            Spacer()
        }
        .customBackground(.surface)
    }
}
