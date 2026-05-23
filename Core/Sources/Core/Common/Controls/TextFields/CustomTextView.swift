//
//  CustomTextView.swift
//
//
//  Created by Ali M. Zaghloul on 7/14/24.
//

import SwiftUI

public struct CustomTextView: View {
    
    @Binding var text: String
    private let characterLimit: Int
    private let placeholder: String
    
    public init(text: Binding<String>,
                characterLimit: Int = 250,
                placeholder: String = "Overview") {
        self._text = text
        self.characterLimit = characterLimit
        self.placeholder = placeholder
    }
    
    public var body: some View {
        VStack(alignment: .leading) {
            
            ZStack(alignment: .topLeading) {
                
                if text.isEmpty {
                    
                    Text(placeholder)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                }
                
                TextEditor(text: $text.limit(characterLimit))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
            }
            .frame(height: 120)
            
            HStack {
                
                Spacer()
                
                Text("\(text.count)/\(characterLimit)")
                    .customStyle(.bodySmall, .subtitle)
                    .padding(.trailing, 12)
                    .padding(.bottom, 8)
            }
        }
        .withCardBorder(cornerRadius: 6,
                        borderColor: .neutral)
    }
}

#Preview {
    CustomTextViewTest()
}

struct CustomTextViewTest: View {
    
    @State var text = "Title"
    
    var body: some View {
        VStack {
            CustomTextView(text: $text)
        }
        .padding(.horizontal)
    }
}
