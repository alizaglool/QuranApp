//
//  CustomRadioPicker.swift
//
//
//  Created by Ali M. Zaghloul on 8/16/24.
//

import SwiftUI

public struct CustomRadioPicker<Item: CustomRadioPickerItem>: View {
    
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
    
    public var body: some View {
        VStack(spacing: 16) {
            ForEach(items) { item in
                
                getItemView(item)
            }
        }
    }
    
    private func getItemView(_ item: Item) -> some View {
        Button(action: {
            selectedItem = item
        }, label: {
            
            HStack(spacing: 8) {
                
                selectionCircle(item)
                
                textView(item)
            }
        })
    }
    
    private func selectionCircle(_ item: Item) -> some View {
        Circle()
            .customFill(isSelected(item: item) ? selectedColor : .clear)
            .frame(width: 11, height: 11)
            .padding(.all, 2)
            .overlay {
                Circle()
                    .customStroke(isSelected(item: item) ? selectedColor : .neutral, lineWidth: 1.5)
            }
    }
    
    private func textView(_ item: Item) -> some View {
        Text(item.displayName)
            .customStyle(.bodySmall,
                         .onSurface)
    }
    
    private func isSelected(item: Item) -> Bool {
        selectedItem == item
    }
}

#Preview {
    CustomRadioPickerTest()
}

struct CustomRadioPickerTest: View {
    
    @State var model: [CustomRadioPickerItemModel] = ["Option 1", "Option 2", "Option 3", "Option 4", "Option 5", "Option 6"].map { CustomRadioPickerItemModel(displayName: $0)
    }
    
    @State var selectedModel: CustomRadioPickerItemModel = .init(displayName: "")
    
    var body: some View {
        VStack {
            
            Spacer()
            
            CustomRadioPicker(selectedItem: $selectedModel,
                              items: model)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .customBackground(.surface)
        .onAppear {
            selectedModel = model[0]
        }
    }
}
