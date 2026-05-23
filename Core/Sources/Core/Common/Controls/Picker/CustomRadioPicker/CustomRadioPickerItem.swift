//
//  CustomRadioPickerItem.swift
//
//
//  Created by Ali M. Zaghloul on 8/16/24.
//

import Foundation

public protocol CustomRadioPickerItem: Identifiable, Hashable {
    
    var displayName: String { get }
}

struct CustomRadioPickerItemModel: CustomRadioPickerItem {
    
    var displayName: String
    let id: UUID = UUID()
    
    static func == (lhs: CustomRadioPickerItemModel, rhs: CustomRadioPickerItemModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}
