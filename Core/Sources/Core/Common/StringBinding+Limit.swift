//
//  StringBinding+Limit.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI

public extension Binding<String> {
    
    func limit(_ length: Int) -> Self {
        if self.wrappedValue.count > length {
            DispatchQueue.main.async {
                self.wrappedValue = String(self.wrappedValue.prefix(length))
            }
        }
        
        return  self
    }
}
