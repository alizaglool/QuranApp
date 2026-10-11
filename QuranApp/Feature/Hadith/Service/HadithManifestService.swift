//
//  HadithManifestService.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 06/10/2026.
//

import Foundation

// MARK: - Manifest

/// Where the book list in hand came from. The library shows the books either
/// way, so this exists to keep the app honest about how fresh the list is
/// rather than to hide anything from the reader.
enum HadithManifestSource {
    /// Shipped inside the app. Correct on first launch, frozen after that.
    case bundled
    /// The last release manifest that was successfully read.
    case cached
    /// Fetched from the release during this launch.
    case remote
}

struct HadithManifest {
    let schemaVersion: Int
    let corpusVersion: String
    let books: [HadithBook]
    let source: HadithManifestSource

    static let empty = HadithManifest(schemaVersion: 0, corpusVersion: "",
                                      books: [], source: .bundled)
}

enum HadithManifestError: Error {
    /// The release is built for a newer app. Carrying on would mean guessing
    /// at a layout this build has never seen, so the cached list is kept.
    case unsupportedSchema(Int)
    case malformed
}

// MARK: - Release manifest

/// The release's own JSON, kept apart from `HadithBook` on purpose: the
/// release knows sizes, hashes and URLs, the app knows titles, authors and
/// colours, and neither has any reason to learn the other's half.
private struct ReleaseManifest: Decodable {

    struct Book: Decodable {
        let bookId: Int
        let sort: Int?
        let url: String?
        let gzSize: Int?
        let gzSha256: String?
        let dbSize: Int?
        let dbSha256: String?
        let hadithCount: Int?
    }

    let schemaVersion: Int
    let corpusVersion: String
    let books: [Book]
}

// MARK: - Service

/// Keeps the list of downloadable books current.
///
/// The bundled manifest is always the starting point, because it is the only
/// place the titles, authors and colours live. A release manifest layers the
/// sizes, hashes and URLs on top of it, so a corpus can be re-cut without
/// shipping a new app build.
final class HadithManifestService {

    static let shared = HadithManifestService()

    /// The highest manifest layout this build understands.
    static let supportedSchemaVersion = 1

    static let releaseURL = URL(string: "https://github.com/bilalelsayed97/hadith-nine-books-data/releases/latest/download/manifest.json")!

    private let session: URLSession
    private let fileManager: FileManager
    private let bundle: Bundle
    private let cacheURL: URL

    private let lock = NSLock()
    private var cached: HadithManifest?

    init(session: URLSession = .shared,
         fileManager: FileManager = .default,
         bundle: Bundle = .main,
         cacheDirectory: URL? = nil) {
        self.session = session
        self.fileManager = fileManager
        self.bundle = bundle
        let directory = cacheDirectory
            ?? fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.cacheURL = directory.appendingPathComponent("hadith_manifest.json")
    }

    // MARK: Reading

    /// The best list available without touching the network.
    ///
    /// Safe to call during a view's first layout: it never blocks on anything
    /// slower than one small file read, and that read happens once.
    func load() -> HadithManifest {
        lock.lock(); defer { lock.unlock() }
        if let cached { return cached }

        let bundled = loadBundledBooks()
        let manifest: HadithManifest
        if let data = try? Data(contentsOf: cacheURL),
           let merged = try? merge(data: data, into: bundled, source: .cached) {
            manifest = merged
        } else {
            manifest = HadithManifest(schemaVersion: Self.supportedSchemaVersion,
                                      corpusVersion: bundledCorpusVersion(),
                                      books: bundled.sorted(by: Self.byLibraryOrder),
                                      source: .bundled)
        }
        cached = manifest
        return manifest
    }

    /// Fetches the release manifest and, if it is readable, adopts it.
    ///
    /// Never throws and never leaves the caller empty-handed: a failed fetch
    /// just means `load()`'s answer stands, which is the whole point of
    /// caching it in the first place.
    @discardableResult
    func refresh() async -> HadithManifest {
        guard let data = try? await fetch() else { return load() }

        let bundled = loadBundledBooks()
        guard let merged = try? merge(data: data, into: bundled, source: .remote) else {
            return load()
        }

        // Written only after it parsed, so a malformed release can never
        // replace a cache that still works.
        try? data.write(to: cacheURL, options: .atomic)
        adopt(merged)
        return merged
    }

    /// Takes the lock on the caller's behalf, which an async function cannot
    /// do for itself without risking a suspension while it is held.
    private func adopt(_ manifest: HadithManifest) {
        lock.lock(); defer { lock.unlock() }
        cached = manifest
    }

    /// Drops the in-memory copy. The next `load()` reads from disk again.
    func invalidate() {
        lock.lock(); defer { lock.unlock() }
        cached = nil
    }

    // MARK: Updates

    /// True when the release carries a different build of a book that is
    /// already installed.
    ///
    /// Compares the database hash rather than the corpus version, so a book
    /// that was untouched by a re-cut does not nag the reader to download
    /// forty megabytes of the same thing.
    func updateAvailable(for book: HadithBook) -> Bool {
        guard !book.dbSha256.isEmpty,
              let installed = HadithInstalledVersions.installedHash(for: book.id),
              !installed.isEmpty else { return false }
        return installed.caseInsensitiveCompare(book.dbSha256) != .orderedSame
    }

    // MARK: Fetching

    private func fetch() async throws -> Data {
        var request = URLRequest(url: Self.releaseURL)
        request.timeoutInterval = 20
        // The manifest is small and changes rarely; a stale copy from a proxy
        // would silently undo the whole point of refreshing.
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw HadithManifestError.malformed
        }
        return data
    }

    // MARK: Merging

    private func merge(data: Data,
                       into bundled: [HadithBook],
                       source: HadithManifestSource) throws -> HadithManifest {
        guard let release = try? JSONDecoder().decode(ReleaseManifest.self, from: data) else {
            throw HadithManifestError.malformed
        }
        guard release.schemaVersion <= Self.supportedSchemaVersion else {
            throw HadithManifestError.unsupportedSchema(release.schemaVersion)
        }

        let byID = Dictionary(release.books.map { ($0.bookId, $0) }, uniquingKeysWith: { first, _ in first })
        // A book the release dropped keeps its bundled entry, so an install
        // already on the device still has a title and a size to show.
        let books = bundled.map { book in
            guard let remote = byID[book.id] else { return book }
            return book.applying(remote)
        }

        return HadithManifest(schemaVersion: release.schemaVersion,
                              corpusVersion: release.corpusVersion,
                              books: books.sorted(by: Self.byLibraryOrder),
                              source: source)
    }

    /// Scholarly order first, then id, so the list never reshuffles when two
    /// books share a sort value.
    private static func byLibraryOrder(_ lhs: HadithBook, _ rhs: HadithBook) -> Bool {
        lhs.sort == rhs.sort ? lhs.id < rhs.id : lhs.sort < rhs.sort
    }

    // MARK: Bundled copy

    private func loadBundledBooks() -> [HadithBook] {
        guard let url = bundle.url(forResource: "books_manifest", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return [] }
        struct Wrapper: Decodable { let books: [HadithBook] }
        return (try? JSONDecoder().decode(Wrapper.self, from: data))?.books ?? []
    }

    private func bundledCorpusVersion() -> String {
        guard let url = bundle.url(forResource: "books_manifest", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return "" }
        struct Wrapper: Decodable { let corpusVersion: String? }
        return (try? JSONDecoder().decode(Wrapper.self, from: data))?.corpusVersion ?? ""
    }
}

// MARK: - Applying a release entry

private extension HadithBook {

    /// Takes the release's numbers and leaves the app's presentation alone.
    ///
    /// Each field falls back to the bundled value, so a release that omits a
    /// key narrows what is known rather than erasing it.
    func applying(_ remote: ReleaseManifest.Book) -> HadithBook {
        var merged = HadithBook(
            id: id,
            titleAr: titleAr,
            titleEn: titleEn,
            authorAr: authorAr,
            authorEn: authorEn,
            hadithCount: remote.hadithCount ?? hadithCount,
            chapterCount: chapterCount,
            colorHex: colorHex,
            downloadURL: remote.url ?? downloadURL,
            fileSizeBytes: remote.gzSize ?? fileSizeBytes
        )
        merged.sort = remote.sort ?? sort
        merged.installedSizeBytes = remote.dbSize ?? installedSizeBytes
        merged.hasTranslation = hasTranslation
        merged.gzSha256 = remote.gzSha256 ?? gzSha256
        merged.dbSha256 = remote.dbSha256 ?? dbSha256
        return merged
    }
}

// MARK: - Installed versions

/// Remembers which build of each book is on disk.
///
/// The download manager writes an entry when a book lands and clears it when
/// the book is deleted; the manifest service reads it to work out whether a
/// re-cut corpus actually changed that book.
enum HadithInstalledVersions {

    private static let key = "hadith_installed_books"

    struct Record: Codable, Equatable {
        let dbSha256: String
        let corpusVersion: String
        let installedAt: Date
    }

    static func record(bookId: Int,
                       dbSha256: String,
                       corpusVersion: String,
                       defaults: UserDefaults = .standard) {
        var all = load(defaults: defaults)
        all[String(bookId)] = Record(dbSha256: dbSha256,
                                     corpusVersion: corpusVersion,
                                     installedAt: Date())
        save(all, defaults: defaults)
    }

    static func forget(bookId: Int, defaults: UserDefaults = .standard) {
        var all = load(defaults: defaults)
        guard all.removeValue(forKey: String(bookId)) != nil else { return }
        save(all, defaults: defaults)
    }

    static func installedHash(for bookId: Int, defaults: UserDefaults = .standard) -> String? {
        load(defaults: defaults)[String(bookId)]?.dbSha256
    }

    static func record(for bookId: Int, defaults: UserDefaults = .standard) -> Record? {
        load(defaults: defaults)[String(bookId)]
    }

    private static func load(defaults: UserDefaults) -> [String: Record] {
        guard let data = defaults.data(forKey: key),
              let all = try? JSONDecoder().decode([String: Record].self, from: data) else { return [:] }
        return all
    }

    private static func save(_ all: [String: Record], defaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(all) else { return }
        defaults.set(data, forKey: key)
    }
}
