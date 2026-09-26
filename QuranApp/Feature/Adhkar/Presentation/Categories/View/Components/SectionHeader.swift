//
//  SectionHeader.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 26/09/2026
//

import SwiftUI
import Core

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .customStyle(.heading3, .onSurface)
    }
}
