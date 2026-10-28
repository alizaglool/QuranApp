//
//  RadioStationRow.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 12/10/2026
//

import SwiftUI
import Core

// MARK: - RadioStationRow

struct RadioStationRow: View {

    let title: String
    let detail: String?
    let badge: String?
    let isCurrent: Bool
    let isPlaying: Bool
    let isLoading: Bool
    let isEnabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 14) {
                leadingIcon
                textStack
                Spacer(minLength: 8)
                trailingControl
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .customFill(.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isCurrent ? ColorStyle.primary.color : Color.clear,
                                lineWidth: 1.5
                            )
                    }
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(isPlaying ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Leading Icon

    private var leadingIcon: some View {
        ZStack {
            Circle()
                .fill(isCurrent ? ColorStyle.primary.color.opacity(0.14) : ColorStyle.container.color)
                .frame(width: 44, height: 44)
            Image(systemName: isPlaying ? "waveform" : "dot.radiowaves.left.and.right")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(isCurrent ? ColorStyle.primary.color : ColorStyle.subtitle.color)
                .symbolEffect(.variableColor.iterative, isActive: isPlaying)
        }
    }

    // MARK: - Text

    private var textStack: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(title)
                    .customStyle(.bodyMedium, .onSurface)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                if let badge {
                    liveBadge(badge)
                }
            }
            if let detail, !detail.isEmpty {
                Text(detail)
                    .customStyle(.caption1, .subtitle)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func liveBadge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(ColorStyle.onPrimary.color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().customFill(.error))
    }

    // MARK: - Trailing

    @ViewBuilder
    private var trailingControl: some View {
        if isLoading {
            ProgressView()
                .scaleEffect(0.8)
                .frame(width: 28, height: 28)
        } else {
            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(isCurrent ? ColorStyle.primary.color : ColorStyle.outline.color)
        }
    }

    private var accessibilityText: String {
        [title, badge, detail].compactMap { $0 }.joined(separator: ", ")
    }
}
