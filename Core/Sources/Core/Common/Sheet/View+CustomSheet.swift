//
//  View+CustomSheet.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI

public extension View {
    
    /// Used for displaying sheets
    /// and relies on fraction for iOS 16 devices and higher
    /// or on detents for iOS 15 devices.
    func customSheet<Content: View>(isPresented: Binding<Bool>, dismissable: Bool = true, fraction: CGFloat = 0.75, detents: [BottomSheet.Detent], @ViewBuilder content: @escaping () -> Content) -> some View  {
        if #available(iOS 16.0, *) {
            return getiOS16View(isPresented: isPresented, dismissable: dismissable, fraction: fraction, content: content)
        }
        else {
            return getBottomSheetView(isPresented: isPresented, dismissable: dismissable, detents: detents, content: content)
        }
    }
    
    /// Used for displaying sheets
    /// and relies on height for iOS 16 devices and higher
    /// or on detents for iOS 15 devices.
    func customSheet<Content: View>(isPresented: Binding<Bool>, dismissable: Bool = true, height: CGFloat, detents: [BottomSheet.Detent], @ViewBuilder content: @escaping () -> Content) -> some View  {
        if #available(iOS 16.0, *) {
            return getiOS16View(isPresented: isPresented, dismissable: dismissable, height: height, content: content)
        }
        else {
            return getBottomSheetView(isPresented: isPresented, dismissable: dismissable, detents: detents, content: content)
        }
    }
    
    @available(iOS 16.0, *)
    private func getiOS16View<Content: View>(isPresented: Binding<Bool>, dismissable: Bool, fraction: CGFloat, @ViewBuilder content: @escaping () -> Content) -> some View {
        self
            .sheet(isPresented: isPresented) {
                content()
                    .presentationDetents([.fraction(fraction)])
                    .interactiveDismissDisabled(!dismissable)
            }
    }
    
    @available(iOS 16.0, *)
    private func getiOS16View<Content: View>(isPresented: Binding<Bool>, dismissable: Bool, height: CGFloat, @ViewBuilder content: @escaping () -> Content) -> some View {
        self
            .sheet(isPresented: isPresented) {
                content()
                    .presentationDetents([.height(height)])
                    .interactiveDismissDisabled(!dismissable)
            }
    }
    
    private func getBottomSheetView<Content: View>(isPresented: Binding<Bool>, dismissable: Bool, detents: [BottomSheet.Detent], @ViewBuilder content: @escaping () -> Content) -> some View {
        self
            .bottomSheet(isPresented: isPresented, detents: detents, shouldScrollExpandSheet: true, showGrabber: false, showNavigationBar: true, dismissable: dismissable, content: content)
    }
}
