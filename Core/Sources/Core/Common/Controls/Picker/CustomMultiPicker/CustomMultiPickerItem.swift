//
//  CustomMultiPickerItem.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import Foundation

public protocol CustomMultiPickerItem: Identifiable {
    
    var displayName: String { get }
    var isSelected: Bool { get set }
    
    init(displayName: String)
}

struct CustomMultiPickerItemModel: CustomMultiPickerItem {
    
    let id: UUID = UUID()
    
    var displayName: String
    var isSelected: Bool
    
    init(displayName: String) {
        self.displayName = displayName
        isSelected = false
    }
}
