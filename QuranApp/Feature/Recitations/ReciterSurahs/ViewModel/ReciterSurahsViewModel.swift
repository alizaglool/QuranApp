//
//  ReciterSurahsViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 12/10/2026
//

import Foundation
import Core

final class ReciterSurahsViewModel: MainViewModel {

    @Published var surahs: [SurahInfo] = []

    let reciter: ReciterInfo
    let sectionTitle: String = AppLocalizedKeys.surahs.value

    private weak var coordinator: RecitationsCoordinating?
    private let audio = AudioEngine.library

    init(coordinator: RecitationsCoordinating, reciter: ReciterInfo) {
        self.coordinator = coordinator
        self.reciter = reciter
    }

    // MARK: - Lifecycle

    func onAppear() {
        guard surahs.isEmpty else { return }
        surahs = QuranDatabase.shared.getAllSurahs()
    }

    // MARK: - Actions

    func onSurahTapped(_ surah: SurahInfo) {
        let isSameReciter = audio.currentReciter.id == reciter.id

        if isSameReciter, audio.currentSurahNumber == surah.id, audio.hasActiveVerse {
            audio.isPlaying ? audio.pause() : audio.resume()
            return
        }

        if !isSameReciter { audio.switchReciter(reciter) }
        audio.playWholeSurah(surahNumber: surah.id)
    }

    func onBackTapped() {
        coordinator?.coordinateBack()
    }

    // MARK: - Labels

    var reciterName: String {
        reciter.arabicName
    }

    var reciterSubtitle: String {
        reciter.englishName
    }

    func versesText(for surah: SurahInfo) -> String {
        String(format: AppLocalizedKeys.versesCount.value, "\(surah.versesCount)")
    }

    func originText(for surah: SurahInfo) -> String {
        surah.isMeccan ? AppLocalizedKeys.meccan.value : AppLocalizedKeys.medinan.value
    }

    func isActive(_ surah: SurahInfo) -> Bool {
        audio.currentReciter.id == reciter.id
            && audio.currentSurahNumber == surah.id
            && audio.hasActiveVerse
    }
}
