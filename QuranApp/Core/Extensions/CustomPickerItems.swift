//
//  CustomPickerItems.swift
//  EMLE Teams
//
//  Created by Ali M. Zaghloul on 25/08/2024.
//

import SwiftUI
import Core

struct CustomPickerItems<Item: CustomPickerItem>: View {
    @Binding var selectedItems: [Item]
    var singleSelectedItem: Binding<Item>?
    var items: [Item]
    var selectedColor: ColorStyle
    var onItemSelected: (() -> Void)?
    var areItemsEqual: (Item, Item) -> Bool
    var isMultiSelect: Bool
    
    public init(selectedItems: Binding<[Item]>,
                items: [Item],
                selectedColor: ColorStyle = .primary,
                isMultiSelect: Bool = true,
                areItemsEqual: @escaping (Item, Item) -> Bool,
                onItemSelected: (() -> Void)? = nil) {
        self._selectedItems = selectedItems
        self.singleSelectedItem = nil
        self.items = items
        self.selectedColor = selectedColor
        self.isMultiSelect = isMultiSelect
        self.areItemsEqual = areItemsEqual
        self.onItemSelected = onItemSelected
    }
    
    public init(singleSelectedItem: Binding<Item>,
                items: [Item],
                selectedColor: ColorStyle = .primary,
                areItemsEqual: @escaping (Item, Item) -> Bool,
                onItemSelected: (() -> Void)? = nil) {
        self.singleSelectedItem = singleSelectedItem
        self._selectedItems = .constant([]) // Use a constant empty array when not multi-select
        self.items = items
        self.selectedColor = selectedColor
        self.isMultiSelect = false
        self.areItemsEqual = areItemsEqual
        self.onItemSelected = onItemSelected
    }
    
    @Namespace private var namespace
    
    public var body: some View {
        VStack(spacing: 8) {
            ScrollView {
                ForEach(items) { item in
                    getItemView(item)
                }
            }
        }
    }
    
    private func getItemView(_ item: Item) -> some View {
        Button(action: {
            if isMultiSelect {
                toggleSelection(of: item)
            } else if let singleSelectedItem = singleSelectedItem {
                singleSelectedItem.wrappedValue = item
            }
            onItemSelected?()
        }, label: {
            Text(item.displayName)
                .customStyle(isSelected(item: item) ? .buttonText : .bodySmall, .onSurface)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background {
                    if isSelected(item: item) {
                        RoundedRectangle(cornerRadius: 5)
                            .customFill(selectedColor)
                            .matchedGeometryEffect(id: item.id, in: namespace)
                    }
                }
        })
        .padding(.horizontal)
    }
    
    private func isSelected(item: Item) -> Bool {
        if isMultiSelect {
            return selectedItems.contains { areItemsEqual($0, item) }
        } else if let singleSelectedItem = singleSelectedItem {
            return areItemsEqual(singleSelectedItem.wrappedValue, item)
        }
        return false
    }
    
    private func toggleSelection(of item: Item) {
        // Ensure item is only added once
        if let index = selectedItems.firstIndex(where: { areItemsEqual($0, item) }) {
            // If item is already selected, remove it
            selectedItems.remove(at: index)
        } else {
            // If item is not selected, add it
            selectedItems.append(item)
        }
    }
}


struct CustomPickerTest_Previews: PreviewProvider {
    static var previews: some View {
        CustomPickerTest()
    }
}

struct CustomPickerTest: View {
    @State private var selectedMockItem = MockItem(name: "Regular", value: 400)

    let mockItems = [
        MockItem(name: "Thin", value: 100),
        MockItem(name: "UltraLight", value: 200),
        MockItem(name: "Light", value: 300),
        MockItem(name: "Regular", value: 400),
        MockItem(name: "Medium", value: 500),
        MockItem(name: "SemiBold", value: 600),
        MockItem(name: "Bold", value: 700),
        MockItem(name: "Heavy", value: 800),
        MockItem(name: "Black", value: 900)
    ]

    var body: some View {
        CustomPickerItems(
            singleSelectedItem: $selectedMockItem,
            items: mockItems,
            selectedColor: .primary,
            areItemsEqual: { $0.value == $1.value }
        ) {
            print("Selected item: \(selectedMockItem.name) with value \(selectedMockItem.value)")
        }
        .padding()
    }
}

struct MockItem: CustomPickerItem {
    let id = UUID()
    let name: String
    let value: Int

    var displayName: String {
        return name
    }
}
