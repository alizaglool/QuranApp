//
//  SurahRow.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 2026-03-23.
//

import SwiftUI
import Core

struct SurahRow: View {
    let surah: SurahEntity
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Surah Number
                surahNumber
                
                // English Name + Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(surah.nameEnglish)
                        .customStyle(.headline, .onSurface)
                    
                    HStack(spacing: 4) {
                        Text(surah.isMeccan ? AppLocalizedKeys.meccan.value : AppLocalizedKeys.medinan.value)
                            .customStyle(.caption2, .subtitle)
                        
                        Circle()
                            .fill(ColorStyle.subtitle.color)
                            .frame(width: 3, height: 3)
                        
                        Text("\(surah.versesCount) \(AppLocalizedKeys.verses.value)")
                            .customStyle(.caption2, .subtitle)
                    }
                }
                
                Spacer()
                
                // Arabic Name + Meaning
                VStack(alignment: .trailing, spacing: 4) {
                    Text(surah.nameArabic)
                        .customStyle(.heading3, .quranText)
                    
                    Text(surah.meaning.uppercased())
                        .customStyle(.caption2, .subtitle)
                }
            }
            .padding(.horizontal, .big)
            .padding(.vertical, 14)
            .background(Color.surfaceContainerLowest)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Surah Number Circle
    
    private var surahNumber: some View {
        ZStack {
            Circle()
                .stroke(ColorStyle.surahDivider.color, lineWidth: 1)
                .frame(width: 40, height: 40)
            
            Text("\(surah.id)")
                .customStyle(.caption1, .onSurface)
        }
    }
}
