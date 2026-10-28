//
//  AthkarDownloadControl.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 27/10/2026.
//

import SwiftUI
import Core

struct AthkarDownloadControl: View {
    let state: AthkarAudioState
    let action: () -> Void

    private let side: CGFloat = 36

    var body: some View {
        switch state {
        case .notDownloaded:
            button { idle(symbol: "arrow.down", size: 13) }

        case let .downloading(progress):
            button {
                ZStack {
                    Circle().stroke(ColorStyle.downloadStroke.color.opacity(0.40), lineWidth: 2.5)
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(Color.secondaryColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.15), value: progress)
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .customForeground(.downloadIcon)
                }
                .frame(width: side, height: side)
            }

        case .installing:
            ZStack {
                Circle().stroke(ColorStyle.downloadStroke.color.opacity(0.40), lineWidth: 2.5)
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.65)
            }
            .frame(width: side, height: side)

        case .downloaded:
            EmptyView()

        case .failed:
            button {
                ZStack {
                    RoundedRectangle(cornerRadius: .cornerSm).fill(Color.red.opacity(0.10))
                    RoundedRectangle(cornerRadius: .cornerSm).strokeBorder(Color.red.opacity(0.40), lineWidth: 1)
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red.opacity(0.80))
                }
                .frame(width: side, height: side)
            }
        }
    }

    // MARK: - Pieces

    private func button<Content: View>(@ViewBuilder label: () -> Content) -> some View {
        Button(action: action, label: label)
            .buttonStyle(.plain)
    }

    private func idle(symbol: String, size: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: .cornerSm).fill(ColorStyle.downloadSurface.color)
            RoundedRectangle(cornerRadius: .cornerSm).strokeBorder(ColorStyle.downloadStroke.color, lineWidth: 1)
            Image(systemName: symbol)
                .font(.system(size: size, weight: .medium))
                .customForeground(.downloadIcon)
        }
        .frame(width: side, height: side)
    }
}
