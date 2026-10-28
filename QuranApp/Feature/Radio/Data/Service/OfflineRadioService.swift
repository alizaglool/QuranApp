//
//  OfflineRadioService.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 12/10/2026
//

import Foundation
import Combine

// MARK: - OfflineRadioService

@MainActor
final class OfflineRadioService: ObservableObject {

    static let shared = OfflineRadioService()

    @Published private(set) var stations: [OfflineRadioStation] = []
    @Published private(set) var currentStation: OfflineRadioStation?

    private let engine = AudioEngine.library
    private let storage = StorageManager.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        observeEngine()
    }

    var isPlaying: Bool { currentStation != nil && engine.isPlaying }
    var isLoading: Bool { currentStation != nil && engine.isLoadingVerse }

    // MARK: - Catalog

    func refreshStations() {
        stations = storage.getAllDownloadedReciters()
            .filter { !$0.downloadedSurahNumbers.isEmpty }
            .map {
                OfflineRadioStation(
                    reciterSlug: $0.slug,
                    nameAr: $0.arabicName,
                    nameEn: $0.name,
                    surahNumbers: $0.downloadedSurahNumbers.sorted()
                )
            }
            .sorted { $0.nameAr < $1.nameAr }

        if let current = currentStation, !stations.contains(where: { $0.id == current.id }) {
            stop()
        }
    }

    // MARK: - Controls

    func play(station: OfflineRadioStation) {
        guard let firstSurah = station.surahNumbers.first else { return }

        currentStation = station
        engine.playToMode = .continuous
        engine.switchReciter(reciter(for: station))
        engine.playFrom(surahNumber: firstSurah, verseNumber: 1)
    }

    func pause() {
        engine.pause()
    }

    func resume() {
        engine.resume()
    }

    func toggle() {
        guard let station = currentStation else { return }
        if engine.isPlaying {
            engine.pause()
        } else if engine.hasActiveVerse {
            engine.resume()
        } else {
            play(station: station)
        }
    }

    func stop() {
        currentStation = nil
        engine.stop()
    }

    // MARK: - Playlist Cycling

    private func observeEngine() {
        engine.$currentSurahNumber
            .removeDuplicates()
            .sink { [weak self] surah in
                Task { @MainActor in
                    self?.handleSurahChange(surah)
                }
            }
            .store(in: &cancellables)
    }

    private func handleSurahChange(_ surah: Int) {
        guard let station = currentStation else { return }
        guard !station.surahNumbers.contains(surah) else { return }

        guard let next = nextDownloadedSurah(after: surah, in: station) else {
            stop()
            return
        }
        engine.playFrom(surahNumber: next, verseNumber: 1)
    }

    private func nextDownloadedSurah(after surah: Int, in station: OfflineRadioStation) -> Int? {
        if let forward = station.surahNumbers.first(where: { $0 > surah }) { return forward }
        return station.surahNumbers.first
    }

    // MARK: - Reciter Resolution

    private func reciter(for station: OfflineRadioStation) -> ReciterInfo {
        if let known = ReciterLibrary.reciter(for: station.reciterSlug) { return known }
        return ReciterInfo(
            id: station.reciterSlug,
            arabicName: station.nameAr,
            englishName: station.nameEn,
            bitrateKbps: 128,
            sizeMB: 0,
            mp3quranId: nil,
            radioIds: [],
            imageURL: nil
        )
    }
}
