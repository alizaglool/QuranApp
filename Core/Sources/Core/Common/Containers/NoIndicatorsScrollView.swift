//
//  NoIndicatorsScrollView.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI

public struct NoIndicatorsScrollView<Content: View>: View {
    
    var axes: Axis.Set
    @ViewBuilder var content: () -> Content
    
    public init(_ axes: Axis.Set = .vertical,
                @ViewBuilder content: @escaping () -> Content) {
        self.axes = axes
        self.content = content
    }
    
    public var body: some View {
        if #available(iOS 16.0, *) {
            return iOS16Body
        } else {
            return iOS15Body
        }
    }
    
    @available(iOS 16.0, *)
    private var iOS16Body: some View {
        ScrollView(axes, content: content)
            .scrollIndicators(.hidden)
    }
    
    private var iOS15Body: some View {
        ScrollView(axes, showsIndicators: false, content: content)
    }
}
