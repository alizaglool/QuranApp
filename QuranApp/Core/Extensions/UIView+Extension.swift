//
//  File.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 11/06/2025.
//

import SwiftUI

extension View {
    func limitInputLength(_ limit: Int) -> some View {
        self.modifier(TextFieldInputLimiter(limit: limit))
    }
}

// MARK: - Text Field Input Limiter
struct TextFieldInputLimiter: ViewModifier {
    let limit: Int
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification)) { obj in
                if let textField = obj.object as? UITextField {
                    if let text = textField.text, text.count > limit {
                        textField.text = String(text.prefix(limit))
                    }
                }
            }
    }
}
