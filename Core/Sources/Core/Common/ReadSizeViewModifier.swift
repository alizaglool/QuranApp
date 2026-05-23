//
//  ReadSizeViewModifier.swift
//  Core
//
//  Created by Ali M. Zaghloul on 03/06/2025.
//


import SwiftUI

struct ReadSizeViewModifier: ViewModifier {
    
    var onChange: GenericAction<CGSize>
    
    @Binding var size: CGSize
    
    func body(content: Content) -> some View {
        
        content
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: SizePreferenceKey.self, value: proxy.size)
                }
            }
            .onPreferenceChange(SizePreferenceKey.self, perform: { onChange?($0) })
            .onPreferenceChange(SizePreferenceKey.self,
                                perform: { size in
                self.size = size
            })
    }
}

public extension View {
    
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        ModifiedContent(content: self, modifier: ReadSizeViewModifier(onChange: onChange, size: .constant(.zero)))
    }
    
    func readSize(to size: Binding<CGSize>) -> some View {
        ModifiedContent(content: self, modifier: ReadSizeViewModifier(onChange: nil, size: size))
    }
}

fileprivate struct SizePreferenceKey: PreferenceKey {
    
    static var defaultValue: CGSize = .zero
    
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) { }
}
