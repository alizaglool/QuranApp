//
//  SettingsAboutSheet.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 18/10/2026.
//

import SwiftUI
import Core

struct SettingsAboutSheet: View {

    let title: String
    let appName: String
    let appInitial: String
    let tagline: String
    let versionText: String
    let descriptionText: String

    var body: some View {
        VStack(spacing: .big) {
            SettingsSheetGrabber()

            Text(title)
                .customStyle(.kitab(size: 18, bold: true), .onSurface)

            appMark

            VStack(spacing: .xxSm) {
                Text(appName)
                    .customStyle(.kitab(size: 20, bold: true), .onSurface)

                Text(tagline)
                    .customStyle(.kitab(size: 14, bold: false), .onSurfaceVariant)

                Text(versionText)
                    .customStyle(.kitab(size: 13, bold: false), .outline)
            }

            Text(descriptionText)
                .customStyle(.kitab(size: 14, bold: false), .onSurfaceVariant)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, .md)

            Spacer(minLength: 0)
        }
        .padding(.top, .sm)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .customBackground(.background)
    }
}

// MARK: - Parts

private extension SettingsAboutSheet {

    var appMark: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(colors: [.avatarGradientStart, .avatarGradientEnd],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                )

            Text(appInitial)
                .customStyle(.kitab(size: 30, bold: true), .onPrimary)
        }
        .frame(width: 72, height: 72)
    }
}
