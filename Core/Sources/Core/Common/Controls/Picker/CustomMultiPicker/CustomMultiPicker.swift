//
//  CustomMultiPicker.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI

public struct CustomMultiPicker<Item: CustomMultiPickerItem>: View {
    
    @Binding var items: [Item]
    
    var selectedColor: ColorStyle
    
    public init(items: Binding<[Item]>,
                selectedColor: ColorStyle = .primary) {
        self._items = items
        self.selectedColor = selectedColor
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            ForEach(items) { item in
                
                getItemView(item: item)
            }
        }
    }
    
    private func getItemView(item: Item) -> some View {
        Button(action: {
            selectedItem(item: item)
        }, label: {
            
            HStack {
                
                titleView(item.displayName)
                
                Spacer()
                
                if item.isSelected {
                    selected
                }
                else {
                    notSelected
                }
            }
        })
        .padding(.vertical, 4)
    }
    
    private func titleView(_ text: String) -> some View {
        Text(text)
            .customStyle(.bodySmall, .subtitle)
            .padding(.vertical, 4)
    }
    
    private var selected: some View {
        RoundedRectangle(cornerRadius: 4)
            .customFill(selectedColor)
            .frame(width: 16, height: 16)
            .overlay {
                
                Image.check
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 10, height: 10)
                    .customForeground(.onPrimary)
            }
    }
    
    private var notSelected: some View {
        RoundedRectangle(cornerRadius: 4)
            .customStroke(.neutral)
            .frame(width: 16, height: 16)
    }
    
    private func selectedItem(item: Item) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            
            withOptionalAnimation {
                items[index].isSelected.toggle()
            }
        }
    }
}

#Preview {
    CustomMultiPickerTest()
}

struct CustomMultiPickerTest: View {
    
    @State var model: [CustomMultiPickerItemModel] = ["Option 1", "Option 2", "Option 3", "Option 4", "Option 5", "Option 6"].map { CustomMultiPickerItemModel(displayName: $0)
    }
    
    var body: some View {
        VStack {
            
            Spacer()
            
            CustomMultiPicker(items: $model)
            
            Spacer()
        }
        .customBackground(.surface)
    }
}
