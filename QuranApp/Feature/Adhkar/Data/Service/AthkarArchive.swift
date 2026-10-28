//
//  AthkarArchive.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 26/10/2026.
//

import Foundation
import Compression
import CryptoKit
import Core

// MARK: - Archive

enum AthkarArchive {

    // MARK: - Entry

    struct Entry {
        let path: String
        let method: UInt16
        let compressedSize: Int
        let uncompressedSize: Int
        let localHeaderOffset: Int

        var isDirectory: Bool { path.hasSuffix("/") }
    }

    // MARK: - Layout

    private enum Layout {
        static let endOfCentralDirectory: UInt32 = 0x0605_4b50
        static let centralDirectoryHeader: UInt32 = 0x0201_4b50
        static let localFileHeader: UInt32 = 0x0403_4b50
        static let endRecordLength = 22
        static let maxCommentLength = 0xFFFF
        static let centralRecordLength = 46
        static let localRecordLength = 30
        static let zip64Marker: UInt32 = 0xFFFF_FFFF
        static let stored: UInt16 = 0
        static let deflated: UInt16 = 8
    }

    private static let bufferSize = 256 * 1024

    // MARK: - Digest

    static func sha256(ofFileAt url: URL) throws -> String {
        guard let handle = FileHandle(forReadingAtPath: url.path) else {
            throw AthkarDataError.missingResource(url.lastPathComponent)
        }
        defer { try? handle.close() }

        var hasher = SHA256()
        while true {
            let chunk = try handle.read(upToCount: bufferSize) ?? Data()
            if chunk.isEmpty { break }
            hasher.update(data: chunk)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    static func verify(digest: String, matches expected: String) throws {
        let wanted = expected.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !wanted.isEmpty else { return }
        guard digest.lowercased() == wanted else {
            throw AthkarDataError.checksumMismatch(digest)
        }
    }

    // MARK: - Listing

    static func entries(in archive: Data, named name: String) throws -> [Entry] {
        let endOffset = try locateEndRecord(in: archive, named: name)

        let total = Int(archive.readUInt16(at: endOffset + 10))
        let directorySize = Int(archive.readUInt32(at: endOffset + 12))
        let directoryOffset = Int(archive.readUInt32(at: endOffset + 16))

        guard directoryOffset >= 0,
              directorySize >= 0,
              directoryOffset + directorySize <= archive.count else {
            throw AthkarDataError.corruptArchive(name)
        }

        var cursor = directoryOffset
        var result: [Entry] = []
        result.reserveCapacity(total)

        while cursor + Layout.centralRecordLength <= directoryOffset + directorySize {
            guard archive.readUInt32(at: cursor) == Layout.centralDirectoryHeader else { break }

            let method = archive.readUInt16(at: cursor + 10)
            let compressed = archive.readUInt32(at: cursor + 20)
            let uncompressed = archive.readUInt32(at: cursor + 24)
            let nameLength = Int(archive.readUInt16(at: cursor + 28))
            let extraLength = Int(archive.readUInt16(at: cursor + 30))
            let commentLength = Int(archive.readUInt16(at: cursor + 32))
            let headerOffset = archive.readUInt32(at: cursor + 42)

            guard compressed != Layout.zip64Marker,
                  uncompressed != Layout.zip64Marker,
                  headerOffset != Layout.zip64Marker else {
                throw AthkarDataError.corruptArchive(name)
            }

            let nameStart = cursor + Layout.centralRecordLength
            guard nameStart + nameLength <= archive.count else {
                throw AthkarDataError.corruptArchive(name)
            }

            let raw = archive.slice(from: nameStart, length: nameLength)
            let path = String.decoding(raw)

            if isSafe(path: path) {
                result.append(Entry(path: path,
                                    method: method,
                                    compressedSize: Int(compressed),
                                    uncompressedSize: Int(uncompressed),
                                    localHeaderOffset: Int(headerOffset)))
            }

            cursor = nameStart + nameLength + extraLength + commentLength
        }

        return result
    }

    // MARK: - Reading

    static func data(for entry: Entry, in archive: Data, named name: String) throws -> Data {
        let header = entry.localHeaderOffset
        guard header + Layout.localRecordLength <= archive.count,
              archive.readUInt32(at: header) == Layout.localFileHeader else {
            throw AthkarDataError.corruptArchive(name)
        }

        let nameLength = Int(archive.readUInt16(at: header + 26))
        let extraLength = Int(archive.readUInt16(at: header + 28))
        let start = header + Layout.localRecordLength + nameLength + extraLength
        let end = start + entry.compressedSize

        guard start <= end, end <= archive.count else {
            throw AthkarDataError.corruptArchive(name)
        }

        let payload = archive.slice(from: start, length: end - start)

        switch entry.method {
        case Layout.stored:
            return payload
        case Layout.deflated:
            let inflated = try inflate(payload, expecting: entry.uncompressedSize, named: name)
            guard entry.uncompressedSize == 0 || inflated.count == entry.uncompressedSize else {
                throw AthkarDataError.corruptArchive(name)
            }
            return inflated
        default:
            throw AthkarDataError.corruptArchive(name)
        }
    }

    // MARK: - Extraction

    @discardableResult
    static func extract(archiveAt url: URL,
                        to directory: URL,
                        where include: (Entry) -> Bool = { _ in true }) throws -> [URL] {
        let name = url.lastPathComponent
        let archive = try Data(contentsOf: url, options: .mappedIfSafe)
        let all = try entries(in: archive, named: name)

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        var written: [URL] = []

        for entry in all where !entry.isDirectory && include(entry) {
            let target = directory.appendingPathComponent(entry.path)
            let parent = target.deletingLastPathComponent()

            try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)

            let payload = try data(for: entry, in: archive, named: name)
            try payload.write(to: target, options: .atomic)
            written.append(target)
        }

        return written
    }

    static func payload(named file: String, archiveAt url: URL) throws -> Data {
        let name = url.lastPathComponent
        let archive = try Data(contentsOf: url, options: .mappedIfSafe)
        let all = try entries(in: archive, named: name)

        guard let entry = all.first(where: { $0.path == file || $0.path.hasSuffix("/\(file)") }) else {
            throw AthkarDataError.missingResource(file)
        }
        return try data(for: entry, in: archive, named: name)
    }

    // MARK: - Helpers

    private static func locateEndRecord(in archive: Data, named name: String) throws -> Int {
        guard archive.count >= Layout.endRecordLength else {
            throw AthkarDataError.corruptArchive(name)
        }

        let highest = archive.count - Layout.endRecordLength
        let lowest = max(0, highest - Layout.maxCommentLength)

        var offset = highest
        while offset >= lowest {
            if archive.readUInt32(at: offset) == Layout.endOfCentralDirectory { return offset }
            offset -= 1
        }
        throw AthkarDataError.corruptArchive(name)
    }

    private static func isSafe(path: String) -> Bool {
        guard !path.isEmpty, !path.hasPrefix("/"), !path.hasPrefix("\\") else { return false }
        guard !path.contains("..") else { return false }
        guard path.unicodeScalars.allSatisfy({ $0.value >= 0x20 }) else { return false }
        return true
    }

    private static func inflate(_ payload: Data, expecting size: Int, named name: String) throws -> Data {
        guard !payload.isEmpty else { return Data() }

        let stream = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1)
        defer { stream.deallocate() }

        guard compression_stream_init(stream, COMPRESSION_STREAM_DECODE, COMPRESSION_ZLIB) == COMPRESSION_STATUS_OK else {
            throw AthkarDataError.corruptArchive(name)
        }
        defer { compression_stream_destroy(stream) }

        let destination = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { destination.deallocate() }

        var output = Data(capacity: max(size, payload.count))

        try payload.withUnsafeBytes { raw in
            guard let base = raw.bindMemory(to: UInt8.self).baseAddress else {
                throw AthkarDataError.corruptArchive(name)
            }

            stream.pointee.src_ptr = base
            stream.pointee.src_size = raw.count
            var lastSrcSize = raw.count

            while true {
                stream.pointee.dst_ptr = destination
                stream.pointee.dst_size = bufferSize

                let status = compression_stream_process(stream, Int32(COMPRESSION_STREAM_FINALIZE.rawValue))
                let produced = bufferSize - stream.pointee.dst_size
                if produced > 0 {
                    output.append(destination, count: produced)
                }

                switch status {
                case COMPRESSION_STATUS_END:
                    return
                case COMPRESSION_STATUS_OK:
                    if produced == 0, stream.pointee.src_size == lastSrcSize {
                        throw AthkarDataError.corruptArchive(name)
                    }
                    lastSrcSize = stream.pointee.src_size
                default:
                    throw AthkarDataError.corruptArchive(name)
                }
            }
        }

        return output
    }
}

// MARK: - Byte access

private extension Data {

    func slice(from offset: Int, length: Int) -> Data {
        guard offset >= 0, length >= 0, offset + length <= count else { return Data() }
        let base = startIndex + offset
        return subdata(in: base..<(base + length))
    }

    func readUInt16(at offset: Int) -> UInt16 {
        guard offset >= 0, offset + 2 <= count else { return 0 }
        let base = startIndex + offset
        return UInt16(self[base]) | (UInt16(self[base + 1]) << 8)
    }

    func readUInt32(at offset: Int) -> UInt32 {
        guard offset >= 0, offset + 4 <= count else { return 0 }
        let base = startIndex + offset
        return UInt32(self[base])
            | (UInt32(self[base + 1]) << 8)
            | (UInt32(self[base + 2]) << 16)
            | (UInt32(self[base + 3]) << 24)
    }
}

// MARK: - Name decoding

private extension String {

    static func decoding(_ raw: Data) -> String {
        String(data: raw, encoding: .utf8) ?? String(decoding: raw, as: UTF8.self)
    }
}
