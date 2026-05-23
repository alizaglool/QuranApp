//
//  CustomMenuPicker.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI

public struct CustomMenuPicker<Item: CustomMenuPickerItem>: View {
    
    @Binding var selectedItem: Item
    var items: [Item]
    
    public init(selectedItem: Binding<Item>,
                items: [Item]) {
        self._selectedItem = selectedItem
        self.items = items
    }
    
    public var body: some View {
        Menu(content: {
            Picker(selection: $selectedItem, label: EmptyView()) {
                
                ForEach(items) { item in
                    
                    Text(item.displayName)
                        .customFont(.buttonText)
                        .tag(item)
                }
            }
        }, label: {
            menuLabel
        })
    }
    
    private var menuLabel: some View {
        HStack(spacing: 0) {
            
            Text(selectedItem.displayName)
                .customStyle(.caption1, .subtitle)
            
            Spacer()
            
            Image.arrowDownFilled
                .customForeground(.subtitle)
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .withCardBorder(cornerRadius: 8,
                        bordered: false)
    }
}

#Preview {
    CustomMenuPickerTest()
}

struct CustomMenuPickerTest: View {
    
    @State var model: [CustomMenuPickerItemModel] = ["Option 1", "Option 2", "Option 3", "Option 4", "Option 5", "Option 6"].map { CustomMenuPickerItemModel(displayName: $0)
    }
    
    @State var selectedModel: CustomMenuPickerItemModel = .init(displayName: "Option 2")
    
    var body: some View {
        VStack {
            
            Spacer()
            
            CustomMenuPicker(selectedItem: $selectedModel, items: model)
            
            Spacer()
        }
        .customBackground(.surface)
    }
}
