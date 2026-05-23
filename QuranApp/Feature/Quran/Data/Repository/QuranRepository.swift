//
//  QuranRepository.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 2026-03-23.
//

import Foundation
import SwiftData

@MainActor
final class QuranRepository {
    
    private let service = QuranService.shared
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Is Data Already Downloaded?
    
    var isQuranDataAvailable: Bool {
        let descriptor = FetchDescriptor<SurahEntity>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        return count >= 114
    }
    
    // MARK: - Download & Save All Quran Data
    
    func downloadAndSaveQuranData() async throws {
        // Fetch both in parallel
        async let surahsTask = service.fetchSurahList()
        async let versesTask = service.fetchQuranText()
        async let infoTask = service.fetchSurahsInfo()
        
        let (surahs, verses, info) = try await (surahsTask, versesTask, infoTask)
        
        // Save Surahs
        for surah in surahs {
            let chapterInfo = info[String(surah.id)]
            
            let entity = SurahEntity(
                id: surah.id,
                nameArabic: surah.name,
                nameEnglish: chapterInfo?.name ?? "",
                meaning: chapterInfo?.englishname ?? "",
                versesCount: chapterInfo?.verses ?? 0,
                isMeccan: (surah.makkia ?? 1) == 1,
                startPage: surah.startPage ?? 0,
                endPage: surah.endPage ?? 0
            )
            modelContext.insert(entity)
        }
        
        // Save Ayahs
        for verse in verses {
            let entity = AyahEntity(
                surahId: verse.chapter,
                verseNumber: verse.verse,
                text: verse.text
            )
            modelContext.insert(entity)
        }
        
        try modelContext.save()
        print("✅ Quran data saved — \(surahs.count) surahs, \(verses.count) ayahs")
    }
    
    // MARK: - Fetch Surahs from SwiftData
    
    func getAllSurahs() throws -> [SurahEntity] {
        let descriptor = FetchDescriptor<SurahEntity>(
            sortBy: [SortDescriptor(\.id)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - Fetch Ayahs for a Surah
    
    func getAyahs(forSurah surahId: Int) throws -> [AyahEntity] {
        let descriptor = FetchDescriptor<AyahEntity>(
            predicate: #Predicate { $0.surahId == surahId },
            sortBy: [SortDescriptor(\.verseNumber)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - Last Read
    
    func getLastRead() throws -> LastReadEntity? {
        let descriptor = FetchDescriptor<LastReadEntity>()
        return try modelContext.fetch(descriptor).first
    }
    
    func saveLastRead(
        surahId: Int,
        surahNameArabic: String,
        surahNameEnglish: String,
        ayahNumber: Int,
        page: Int,
        juz: Int,
        versesCount: Int
    ) throws {
        // Delete old
        let existing = try modelContext.fetch(FetchDescriptor<LastReadEntity>())
        existing.forEach { modelContext.delete($0) }
        
        // Insert new
        let entity = LastReadEntity(
            surahId: surahId,
            surahNameArabic: surahNameArabic,
            surahNameEnglish: surahNameEnglish,
            ayahNumber: ayahNumber,
            page: page,
            juz: juz,
            versesCount: versesCount
        )
        modelContext.insert(entity)
        try modelContext.save()
    }
}
