//
//  StorageViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 28/10/2026.
//

import Foundation
import Core

struct StorageLegendItem: Identifiable {
    let id: String
    let title: String
    let sizeLabel: String
    let accent: ColorStyle
    let fraction: Double
}

struct StorageFilterChipItem: Identifiable {
    let id: String
    let category: StorageCategory?
    let title: String
    let isSelected: Bool
}

struct StorageRowItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let sizeLabel: String
    let target: StorageDeleteTarget
}

struct StorageGroupItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let sizeLabel: String
    let accent: ColorStyle
    let hasHeader: Bool
    let rows: [StorageRowItem]
    let collapsedRowCount: Int
    let isExpanded: Bool
    let deleteAllTarget: StorageDeleteTarget?

    var hasMoreRows: Bool { rows.count > collapsedRowCount }

    var visibleRows: [StorageRowItem] {
        isExpanded ? rows : Array(rows.prefix(collapsedRowCount))
    }
}

struct StorageSectionItem: Identifiable {
    let id: String
    let title: String
    let groups: [StorageGroupItem]
}

struct StorageDeletionRequest: Identifiable {
    let id: String
    let title: String
    let message: String
    let confirmTitle: String
    let cancelTitle: String
    let target: StorageDeleteTarget
}

@MainActor
final class StorageViewModel: MainViewModel {

    @Published private(set) var isScanning: Bool = true
    @Published private(set) var totalSizeLabel: String = ""
    @Published private(set) var legend: [StorageLegendItem] = []
    @Published private(set) var chips: [StorageFilterChipItem] = []
    @Published private(set) var sections: [StorageSectionItem] = []
    @Published private(set) var isLibraryEmpty: Bool = false
    @Published var deletionRequest: StorageDeletionRequest?

    private let downloadManager = DownloadManager.shared
    private let hadithDownloads = HadithDownloadManager.shared
    private let athkarDownloads = AthkarAudioDownloadManager.shared
    private let tafsirDownloads = TafsirDownloadManager.shared
    private let hadithCatalog = HadithDatabaseService.shared
    private let athkarManifest = AthkarManifestService.shared
    private let quranPackStore = QuranImagePackStore.shared
    private weak var coordinator: StorageCoordinating?

    private var scan: StorageScan = .empty
    private var selectedCategory: StorageCategory?
    private var expandedGroupIds: Set<String> = []
    private var hadithBooks: [HadithBook] = []

    var isTabBarVisible: Bool { false }

    init(coordinator: StorageCoordinating) {
        self.coordinator = coordinator
    }

    func onAppear() {
        reload()
    }
}

// MARK: - Titles

extension StorageViewModel {

    var screenTitle: String { AppLocalizedKeys.storageManagement.value }
    var totalCaption: String { AppLocalizedKeys.storageTotalUsed.value }
    var scanningTitle: String { AppLocalizedKeys.storageScanning.value }
    var emptyTitle: String { AppLocalizedKeys.storageEmptyTitle.value }
    var emptyMessage: String { AppLocalizedKeys.storageEmptyMessage.value }
    var showMoreTitle: String { AppLocalizedKeys.storageShowMore.value }
    var showLessTitle: String { AppLocalizedKeys.storageShowLess.value }
    var deleteAllTitle: String { AppLocalizedKeys.storageDeleteAll.value }
    var captionTracking: CGFloat {
        LocalizationManager.shared.currentLanguage == .Arabic ? 0 : 1.5
    }

    var deleteLabel: String { AppLocalizedKeys.deleteButton.value }
}

// MARK: - Actions

extension StorageViewModel {

    func onBackTapped() {
        coordinator?.coordinateBack()
    }

    func selectCategory(_ category: StorageCategory?) {
        selectedCategory = category
        rebuild()
    }

    func toggleGroup(_ identifier: String) {
        if expandedGroupIds.contains(identifier) {
            expandedGroupIds.remove(identifier)
        } else {
            expandedGroupIds.insert(identifier)
        }
        rebuild()
    }

    func requestDelete(_ row: StorageRowItem) {
        deletionRequest = StorageDeletionRequest(
            id: row.id,
            title: AppLocalizedKeys.storageDeleteTitle.value,
            message: String(format: AppLocalizedKeys.storageDeleteMessageFormat.value, row.title),
            confirmTitle: AppLocalizedKeys.deleteButton.value,
            cancelTitle: AppLocalizedKeys.cancel.value,
            target: row.target
        )
    }

    func requestDeleteAll(_ group: StorageGroupItem) {
        guard let target = group.deleteAllTarget else { return }
        deletionRequest = StorageDeletionRequest(
            id: "all-\(group.id)",
            title: AppLocalizedKeys.storageDeleteAllTitle.value,
            message: String(format: AppLocalizedKeys.storageDeleteAllMessageFormat.value, group.title),
            confirmTitle: AppLocalizedKeys.deleteButton.value,
            cancelTitle: AppLocalizedKeys.cancel.value,
            target: target
        )
    }

    func confirmDeletion(_ target: StorageDeleteTarget) {
        deletionRequest = nil
        performDeletion(target)
        reload()
    }

    func cancelDeletion() {
        deletionRequest = nil
    }
}

// MARK: - Reload

private extension StorageViewModel {

    func reload() {
        isScanning = scan.isEmpty
        Task { [weak self] in
            let fresh = await StorageScanner.scan()
            guard let self else { return }
            self.scan = fresh
            self.isScanning = false
            self.rebuild()
        }
    }

    func performDeletion(_ target: StorageDeleteTarget) {
        switch target {
        case .reciterSurah(let slug, let surahNumber):
            guard let reciter = ReciterLibrary.reciter(for: slug) else { return }
            downloadManager.deleteSurah(for: reciter, surahNumber: surahNumber)
        case .reciter(let slug):
            downloadManager.deleteReciter(slug)
        case .hadithBook(let identifier):
            hadithDownloads.delete(bookId: identifier)
        case .athkarPack(let key):
            athkarDownloads.delete(key: key)
        case .tafsirBook(let identifier):
            tafsirDownloads.delete(bookId: identifier)
        case .quranPack(let key):
            quranPackStore.delete(key: key)
        }
    }

    func rebuild() {
        let total = scan.totalBytes
        isLibraryEmpty = total == 0
        totalSizeLabel = Self.sizeLabel(total)
        legend = makeLegend(total: total)
        chips = makeChips()
        sections = makeSections()
    }
}

// MARK: - Header

private extension StorageViewModel {

    func makeLegend(total: Int64) -> [StorageLegendItem] {
        StorageCategory.allCases.compactMap { category in
            let bytes = scan.bytes(for: category)
            guard bytes > 0 else { return nil }
            return StorageLegendItem(
                id: category.rawValue,
                title: Self.title(for: category),
                sizeLabel: Self.sizeLabel(bytes),
                accent: Self.accent(for: category),
                fraction: total > 0 ? Double(bytes) / Double(total) : 0
            )
        }
    }

    func makeChips() -> [StorageFilterChipItem] {
        let active = StorageCategory.allCases.filter { scan.bytes(for: $0) > 0 }
        guard active.count > 1 else { return [] }

        var items: [StorageFilterChipItem] = [
            StorageFilterChipItem(id: "all",
                                  category: nil,
                                  title: AppLocalizedKeys.storageFilterAll.value,
                                  isSelected: selectedCategory == nil)
        ]
        items.append(contentsOf: active.map { category in
            StorageFilterChipItem(id: category.rawValue,
                                  category: category,
                                  title: Self.title(for: category),
                                  isSelected: selectedCategory == category)
        })
        return items
    }
}

// MARK: - Sections

private extension StorageViewModel {

    func makeSections() -> [StorageSectionItem] {
        StorageCategory.allCases.compactMap { category in
            guard selectedCategory == nil || selectedCategory == category else { return nil }
            let groups = makeGroups(for: category)
            guard !groups.isEmpty else { return nil }
            return StorageSectionItem(id: category.rawValue,
                                      title: Self.title(for: category),
                                      groups: groups)
        }
    }

    func makeGroups(for category: StorageCategory) -> [StorageGroupItem] {
        switch category {
        case .recitations: return reciterGroups
        case .hadith: return flatGroup(category: .hadith, rows: hadithRows)
        case .athkar: return flatGroup(category: .athkar, rows: athkarRows)
        case .tafsir: return flatGroup(category: .tafsir, rows: tafsirRows)
        case .quranPages: return flatGroup(category: .quranPages, rows: quranRows)
        }
    }

    func flatGroup(category: StorageCategory, rows: [StorageRowItem]) -> [StorageGroupItem] {
        guard !rows.isEmpty else { return [] }
        return [
            StorageGroupItem(
                id: category.rawValue,
                title: Self.title(for: category),
                subtitle: "",
                sizeLabel: Self.sizeLabel(scan.bytes(for: category)),
                accent: Self.accent(for: category),
                hasHeader: false,
                rows: rows,
                collapsedRowCount: rows.count,
                isExpanded: true,
                deleteAllTarget: nil
            )
        ]
    }

    var reciterGroups: [StorageGroupItem] {
        scan.reciters.map { usage in
            let identifier = "reciter-\(usage.slug)"
            let reciter = ReciterLibrary.reciter(for: usage.slug)
            let rows: [StorageRowItem] = reciter == nil ? [] : usage.surahs.map { surah in
                StorageRowItem(
                    id: "\(identifier)-\(surah.number)",
                    title: Self.surahName(surah.number),
                    subtitle: "",
                    sizeLabel: Self.sizeLabel(surah.bytes),
                    target: .reciterSurah(slug: usage.slug, surahNumber: surah.number)
                )
            }
            return StorageGroupItem(
                id: identifier,
                title: reciter?.arabicName ?? usage.slug,
                subtitle: Self.reciterSubtitle(reciter: reciter, surahCount: usage.surahs.count),
                sizeLabel: Self.sizeLabel(usage.bytes),
                accent: Self.accent(for: .recitations),
                hasHeader: true,
                rows: rows,
                collapsedRowCount: 5,
                isExpanded: expandedGroupIds.contains(identifier),
                deleteAllTarget: .reciter(slug: usage.slug)
            )
        }
    }

    var hadithRows: [StorageRowItem] {
        let catalog = hadithBooks.isEmpty ? hadithCatalog.loadManifest() : hadithBooks
        hadithBooks = catalog

        return scan.hadithBooks.compactMap { usage in
            guard let identifier = Int(usage.identifier) else { return nil }
            let book = catalog.first { $0.id == identifier }
            return StorageRowItem(
                id: "hadith-\(identifier)",
                title: book?.title ?? usage.identifier,
                subtitle: book?.author ?? "",
                sizeLabel: Self.sizeLabel(usage.bytes),
                target: .hadithBook(identifier: identifier)
            )
        }
    }

    var athkarRows: [StorageRowItem] {
        let packs = athkarManifest.load().packs
        return scan.athkarPacks.map { usage in
            let pack = packs.first { $0.key == usage.identifier }
            return StorageRowItem(
                id: "athkar-\(usage.identifier)",
                title: pack?.name ?? usage.identifier,
                subtitle: "",
                sizeLabel: Self.sizeLabel(usage.bytes),
                target: .athkarPack(key: usage.identifier)
            )
        }
    }

    var quranRows: [StorageRowItem] {
        let packs = quranPackStore.packs
        return scan.quranPacks.map { usage in
            let pack = packs.first { $0.key == usage.identifier }
            return StorageRowItem(
                id: "quran-\(usage.identifier)",
                title: pack.map { AppLocalizedKeys.juzKey($0.juz).value } ?? usage.identifier,
                subtitle: pack.map(Self.pagesSubtitle) ?? "",
                sizeLabel: Self.sizeLabel(usage.bytes),
                target: .quranPack(key: usage.identifier)
            )
        }
    }

    var tafsirRows: [StorageRowItem] {
        scan.tafsirBooks.map { usage in
            let book = TafsirBook.find(id: usage.identifier)
            return StorageRowItem(
                id: "tafsir-\(usage.identifier)",
                title: book?.nameArabic ?? usage.identifier,
                subtitle: book?.author ?? "",
                sizeLabel: Self.sizeLabel(usage.bytes),
                target: .tafsirBook(identifier: usage.identifier)
            )
        }
    }
}

// MARK: - Formatting

private extension StorageViewModel {

    static func sizeLabel(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    static func surahName(_ number: Int) -> String {
        ReciterLibrary.surahArabicNames[number]
            ?? String(format: AppLocalizedKeys.surahFallback.value, number)
    }

    static func pagesSubtitle(_ pack: QuranImagePack) -> String {
        String(format: AppLocalizedKeys.quranDownloadsPagesFormat.value,
               localizedNumber(pack.firstPage),
               localizedNumber(pack.lastPage))
    }

    static func localizedNumber(_ value: Int) -> String {
        LocalizationManager.shared.currentLanguage == .Arabic ? value.arabicNumerals : "\(value)"
    }

    static func reciterSubtitle(reciter: ReciterInfo?, surahCount: Int) -> String {
        let surahs = String(format: AppLocalizedKeys.surahsDownloaded.value, surahCount)
        guard let reciter else { return surahs }
        return "\(surahs) · \u{2066}\(reciter.bitrateKbps) kbps\u{2069}"
    }

    static func title(for category: StorageCategory) -> String {
        switch category {
        case .recitations: return AppLocalizedKeys.storageCategoryRecitations.value
        case .hadith: return AppLocalizedKeys.storageCategoryHadith.value
        case .athkar: return AppLocalizedKeys.storageCategoryAthkar.value
        case .tafsir: return AppLocalizedKeys.storageCategoryTafsir.value
        case .quranPages: return AppLocalizedKeys.storageCategoryQuranPages.value
        }
    }

    static func accent(for category: StorageCategory) -> ColorStyle {
        switch category {
        case .recitations: return .quickAccentRecitations
        case .hadith: return .quickAccentHadith
        case .athkar: return .quickAccentAdhkar
        case .tafsir: return .quickAccentLessons
        case .quranPages: return .quickAccentQuran
        }
    }
}
