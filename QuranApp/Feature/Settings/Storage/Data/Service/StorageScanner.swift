//
//  StorageScanner.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 28/10/2026.
//

import Foundation

enum StorageScanner {

    private static let cachedTotalKey = "storage.cachedTotalBytes"

    static var cachedTotalBytes: Int64 {
        Int64(UserDefaults.standard.double(forKey: cachedTotalKey))
    }

    static func scan() async -> StorageScan {
        let scan = await Task.detached(priority: .utility) { performScan() }.value
        UserDefaults.standard.set(Double(scan.totalBytes), forKey: cachedTotalKey)
        return scan
    }
}

// MARK: - Scan

private extension StorageScanner {

    static var documents: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static var applicationSupport: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? documents
    }

    static func performScan() -> StorageScan {
        StorageScan(
            reciters: scanReciters(),
            hadithBooks: scanHadithBooks(),
            athkarPacks: scanAthkarPacks(),
            tafsirBooks: scanTafsirBooks(),
            quranPacks: scanQuranPacks()
        )
    }

    static func scanReciters() -> [ReciterUsage] {
        let root = documents.appendingPathComponent("Audio", isDirectory: true)
        guard let slugs = try? FileManager.default.contentsOfDirectory(atPath: root.path) else { return [] }

        var usages: [ReciterUsage] = []
        for slug in slugs where !slug.hasPrefix(".") {
            let directory = root.appendingPathComponent(slug, isDirectory: true)
            guard let names = try? FileManager.default.contentsOfDirectory(atPath: directory.path) else { continue }

            var bytesBySurah: [Int: Int64] = [:]
            for name in names where name.hasSuffix(".mp3") {
                let stem = name.dropLast(4)
                guard stem.count == 6, let surah = Int(stem.prefix(3)) else { continue }
                bytesBySurah[surah, default: 0] += fileSize(directory.appendingPathComponent(name))
            }
            guard !bytesBySurah.isEmpty else { continue }

            let surahs = bytesBySurah.keys.sorted().map { SurahUsage(number: $0, bytes: bytesBySurah[$0] ?? 0) }
            usages.append(ReciterUsage(slug: slug,
                                       bytes: surahs.reduce(Int64(0)) { $0 + $1.bytes },
                                       surahs: surahs))
        }
        return usages.sorted { $0.bytes > $1.bytes }
    }

    static func scanHadithBooks() -> [StorageItemUsage] {
        let root = documents.appendingPathComponent("hadith_books", isDirectory: true)
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: root.path) else { return [] }

        let prefix = "hadith_book_"
        return names
            .filter { $0.hasPrefix(prefix) && $0.hasSuffix(".db") }
            .compactMap { name in
                let stem = name.dropFirst(prefix.count).dropLast(3)
                guard !stem.isEmpty else { return nil }
                return StorageItemUsage(identifier: String(stem),
                                        bytes: fileSize(root.appendingPathComponent(name)))
            }
            .filter { $0.bytes > 0 }
            .sorted { $0.bytes > $1.bytes }
    }

    static func scanAthkarPacks() -> [StorageItemUsage] {
        let root = documents.appendingPathComponent("athkar_audio", isDirectory: true)
        guard let keys = try? FileManager.default.contentsOfDirectory(atPath: root.path) else { return [] }

        return keys
            .filter { !$0.hasPrefix(".") }
            .map { StorageItemUsage(identifier: $0,
                                    bytes: directorySize(root.appendingPathComponent($0, isDirectory: true))) }
            .filter { $0.bytes > 0 }
            .sorted { $0.bytes > $1.bytes }
    }

    static func scanQuranPacks() -> [StorageItemUsage] {
        let root = applicationSupport.appendingPathComponent(QuranImagePackStore.contentDirectoryName,
                                                             isDirectory: true)
        guard let keys = try? FileManager.default.contentsOfDirectory(atPath: root.path) else { return [] }

        return keys
            .filter { !$0.hasPrefix(".") }
            .map { StorageItemUsage(identifier: $0,
                                    bytes: directorySize(root.appendingPathComponent($0, isDirectory: true))) }
            .filter { $0.bytes > 0 }
            .sorted { $0.identifier < $1.identifier }
    }

    static func scanTafsirBooks() -> [StorageItemUsage] {
        let root = documents.appendingPathComponent("tafsir_books", isDirectory: true)
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: root.path) else { return [] }

        return names
            .filter { $0.hasSuffix(".json") }
            .map { StorageItemUsage(identifier: String($0.dropLast(5)),
                                    bytes: fileSize(root.appendingPathComponent($0))) }
            .filter { $0.bytes > 0 }
            .sorted { $0.bytes > $1.bytes }
    }
}

// MARK: - Sizes

private extension StorageScanner {

    static func fileSize(_ url: URL) -> Int64 {
        let keys: Set<URLResourceKey> = [.totalFileAllocatedSizeKey, .fileSizeKey]
        guard let values = try? url.resourceValues(forKeys: keys) else { return 0 }
        if let allocated = values.totalFileAllocatedSize { return Int64(allocated) }
        return Int64(values.fileSize ?? 0)
    }

    static func directorySize(_ url: URL) -> Int64 {
        let keys: [URLResourceKey] = [.isRegularFileKey, .totalFileAllocatedSizeKey, .fileSizeKey]
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: keys) else { return 0 }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard (try? fileURL.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile == true else { continue }
            total += fileSize(fileURL)
        }
        return total
    }
}
