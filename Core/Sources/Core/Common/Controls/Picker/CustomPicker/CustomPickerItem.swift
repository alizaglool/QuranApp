//
//  CustomPickerItem.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import Foundation

public protocol CustomPickerItem: Identifiable, Hashable {
    
    var displayName: String { get }
}

struct CustomPickerItemModel: CustomPickerItem {
    
    var displayName: String
    let id: UUID = UUID()
    
    static func == (lhs: CustomPickerItemModel, rhs: CustomPickerItemModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}
