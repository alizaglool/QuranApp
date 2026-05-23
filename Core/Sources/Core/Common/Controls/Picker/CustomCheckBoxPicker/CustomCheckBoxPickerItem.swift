//
//  CustomCheckBoxPickerItem.swift
//
//
//  Created by Ali M. Zaghloul on 8/16/24.
//

import Foundation

public protocol CustomCheckBoxPickerItem: Identifiable {
    
    var displayName: String { get }
    var isOn: Bool { get set }
    
    init(displayName: String)
}

struct CustomCheckBoxPickerItemModel: CustomCheckBoxPickerItem {
    
    let id: UUID = UUID()
    
    var displayName: String
    var isOn: Bool
    
    init(displayName: String) {
        self.displayName = displayName
        isOn = false
    }
}
