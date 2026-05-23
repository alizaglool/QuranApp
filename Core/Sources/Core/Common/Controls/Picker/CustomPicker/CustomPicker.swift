//
//  CustomPicker.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI

public struct CustomPicker<Item: CustomPickerItem>: View {
    
    @Binding var selectedItem: Item
    var items: [Item]
    
    var selectedColor: ColorStyle
    
    public init(selectedItem: Binding<Item>,
                items: [Item],
                selectedColor: ColorStyle = .primary) {
        self._selectedItem = selectedItem
        self.items = items
        self.selectedColor = selectedColor
    }
    
    @Namespace private var namespace
    @Namespace private var backgroundRectangle
    
    public var body: some View {
        VStack(spacing: 8) {
            ForEach(items) { item in
                
                getItemView(item)
            }
        }
    }
    
    private func getItemView(_ item: Item) -> some View {
        
        Button(action: {
            selectedItem = item
        }, label: {
            
            Text(item.displayName)
                .customStyle(isSelected(item: item) ? .buttonText : .bodySmall,
                             .onSurface)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background {
                    if isSelected(item: item) {
                        RoundedRectangle(cornerRadius: 5)
                            .customFill(selectedColor)
                            .matchedGeometryEffect(id: backgroundRectangle, in: namespace)
                    }
                }
        })
    }
    
    private func isSelected(item: Item) -> Bool {
        selectedItem == item
    }
}

#Preview {
    CustomPickerTest()
}

struct CustomPickerTest: View {
    
    @State var model: [CustomPickerItemModel] = ["Option 1", "Option 2", "Option 3", "Option 4", "Option 5", "Option 6"].map { CustomPickerItemModel(displayName: $0)
    }
    
    @State var selectedModel: CustomPickerItemModel = .init(displayName: "")
    
    var body: some View {
        VStack {
            
            Spacer()
            
            CustomPicker(selectedItem: $selectedModel,
                         items: model)
            
            Spacer()
        }
        .customBackground(.surface)
        .onAppear {
            selectedModel = model[0]
        }
    }
}
