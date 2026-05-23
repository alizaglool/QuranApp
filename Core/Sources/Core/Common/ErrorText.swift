//
//  ErrorText.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI

struct ErrorText: View {
    
    var text: String
    
    var body: some View {
        Text(text)
            .customStyle(.bodySmall, .error)
    }
}

#Preview {
    ErrorText(text: "This is wrong")
}
