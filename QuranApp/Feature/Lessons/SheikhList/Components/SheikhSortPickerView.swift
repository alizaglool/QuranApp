//
//  SheikhSortPickerView.swift
//  QuranApp
//

import SwiftUI
import Core

struct SheikhSortPickerView: View {
    @Binding var selected: SheikhSortOption
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("ترتيب حسب")
                .customStyle(.subheadline, .onSurface)
                .padding(.top, 20)
                .padding(.bottom, 12)

            Divider()

            ForEach(SheikhSortOption.allCases, id: \.self) { option in
                Button {
                    selected = option
                    onDismiss()
                } label: {
                    HStack {
                        Text(option.rawValue)
                            .customStyle(.bodySmall, .onSurface)
                        Spacer()
                        if selected == option {
                            Image(systemName: "checkmark")
                                .customForeground(.primary)
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                }
                Divider()
            }
        }
        .customBackground(.background)
        .presentationDetents([.height(CGFloat(SheikhSortOption.allCases.count) * 52 + 80)])
        .presentationDragIndicator(.visible)
    }
}
