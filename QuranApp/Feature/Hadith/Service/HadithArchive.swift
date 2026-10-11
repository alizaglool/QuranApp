//
//  HadithArchive.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 06/10/2026.
//

import Foundation
import Compression
import CryptoKit
import Core

// MARK: - Errors

enum HadithArchiveError: LocalizedError {
    case unreadable
    case notGzip
    case unsupportedCompression
    case truncated
    case corrupt
    case sizeMismatch(expected: Int, actual: Int)
    case checksumMismatch
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .unreadable, .writeFailed:
            return "hadithDownloadStorageError".localized
        case .notGzip, .unsupportedCompression, .truncated, .corrupt,
             .sizeMismatch, .checksumMismatch:
            return "hadithDownloadCorruptError".localized
        }
    }
}

// MARK: - Archive

/// Un-gzips a downloaded book and proves it arrived intact.
///
/// Both halves stream. A book is up to 45 MiB compressed and 460 MiB open, so
/// nothing here ever holds a whole file — the peak cost is two 256 KiB
/// buffers, whatever the book's size.
///
/// There is no new dependency: Apple's `Compression` decodes the DEFLATE body
/// and `CryptoKit` hashes it, which is also why the gzip wrapper is read by
/// hand below.
enum HadithArchive {

    /// 256 KiB, which is where a larger buffer stops buying throughput.
    private static let bufferSize = 256 * 1024

    // MARK: Hashing

    /// The SHA-256 of a file on disk, lower-case hex.
    static func sha256(ofFileAt url: URL) throws -> String {
        guard let handle = try? FileHandle(forReadingFrom: url) else { throw HadithArchiveError.unreadable }
        defer { try? handle.close() }

        var hasher = SHA256()
        while let chunk = try? handle.read(upToCount: bufferSize), !chunk.isEmpty {
            chunk.withUnsafeBytes { hasher.update(bufferPointer: $0) }
        }
        return hexString(hasher.finalize())
    }

    /// Throws unless the two digests match, ignoring case.
    ///
    /// An empty expectation passes: a manifest is allowed to omit a digest,
    /// and refusing a book over a field the server never sent would be the
    /// wrong failure.
    static func verify(digest actual: String, matches expected: String) throws {
        guard !expected.isEmpty else { return }
        guard actual.caseInsensitiveCompare(expected) == .orderedSame else {
            throw HadithArchiveError.checksumMismatch
        }
    }

    // MARK: Un-gzipping

    /// Expands a gzip file, replacing anything at `destination`.
    ///
    /// - Returns: the SHA-256 of what was written, so the caller can check it
    ///   against the manifest without reading the file a second time.
    /// - Note: a failure part-way through removes the partial output before
    ///   throwing, so a retry never finds a half-written book in its way.
    @discardableResult
    static func gunzip(from source: URL, to destination: URL) throws -> String {
        guard let input = try? FileHandle(forReadingFrom: source),
              let fileSize = try? input.seekToEnd() else { throw HadithArchiveError.unreadable }
        defer { try? input.close() }
        try? input.seek(toOffset: 0)

        let fileManager = FileManager.default
        try? fileManager.removeItem(at: destination)
        guard fileManager.createFile(atPath: destination.path, contents: nil),
              let output = try? FileHandle(forWritingTo: destination) else {
            throw HadithArchiveError.writeFailed
        }

        var succeeded = false
        defer {
            try? output.close()
            if !succeeded { try? fileManager.removeItem(at: destination) }
        }

        let reader = ChunkReader(handle: input, chunkSize: bufferSize)
        try readGzipHeader(from: reader)

        // The trailer is the last eight bytes, so the compressed body is
        // everything between the header and it. Measuring it up front is what
        // lets the decoder be told which chunk is its last, which is the only
        // way it flushes what it still holds.
        let bodyLength = Int(fileSize) - reader.consumed - 8
        guard bodyLength > 0 else { throw HadithArchiveError.truncated }

        var hasher = SHA256()
        var written = 0
        try inflate(reader: reader, bodyLength: bodyLength) { buffer in
            guard let base = buffer.baseAddress else { return }
            // Written without copying: a big book is 460 MiB, and a copy per
            // block is 460 MiB of memcpy bought for nothing. The handle has
            // finished with the bytes by the time `write` returns.
            let view = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: base),
                            count: buffer.count,
                            deallocator: .none)
            try output.write(contentsOf: view)
            hasher.update(bufferPointer: buffer)
            written += buffer.count
        }

        guard let trailer = try reader.take(8) else { throw HadithArchiveError.truncated }
        try checkTrailer(trailer, bytesWritten: written)
        succeeded = true
        return hexString(hasher.finalize())
    }

    // MARK: Gzip wrapper

    /// Consumes the gzip header, leaving the reader on the first DEFLATE byte.
    private static func readGzipHeader(from reader: ChunkReader) throws {
        guard let head = try reader.take(10) else { throw HadithArchiveError.truncated }
        guard head[0] == 0x1F, head[1] == 0x8B else { throw HadithArchiveError.notGzip }
        guard head[2] == 8 else { throw HadithArchiveError.unsupportedCompression }

        let flags = head[3]
        if flags & 0x04 != 0 {                               // FEXTRA
            guard let length = try reader.take(2) else { throw HadithArchiveError.truncated }
            let extra = Int(length[0]) | Int(length[1]) << 8
            guard try reader.skip(extra) else { throw HadithArchiveError.truncated }
        }
        if flags & 0x08 != 0 { try reader.skipCString() }    // FNAME
        if flags & 0x10 != 0 { try reader.skipCString() }    // FCOMMENT
        if flags & 0x02 != 0 {                               // FHCRC
            guard try reader.skip(2) else { throw HadithArchiveError.truncated }
        }
    }

    /// Checks the gzip trailer's uncompressed length against what was written.
    ///
    /// The trailer's other half is a CRC-32, which is not checked here: the
    /// caller compares the output against the manifest's SHA-256, and that is
    /// the stronger statement about the very same bytes.
    private static func checkTrailer(_ trailer: Data, bytesWritten: Int) throws {
        guard trailer.count >= 8 else { throw HadithArchiveError.truncated }
        let bytes = [UInt8](trailer)
        let declared = UInt32(bytes[4]) | UInt32(bytes[5]) << 8
                     | UInt32(bytes[6]) << 16 | UInt32(bytes[7]) << 24
        // gzip stores the length modulo 2^32, so that is what it is compared to.
        let actual = UInt32(truncatingIfNeeded: bytesWritten)
        guard declared == actual else {
            throw HadithArchiveError.sizeMismatch(expected: Int(declared), actual: bytesWritten)
        }
    }

    // MARK: DEFLATE

    /// Streams `bodyLength` bytes of DEFLATE through `Compression`, handing
    /// each block of output to `emit`, and leaves the reader on the trailer.
    private static func inflate(reader: ChunkReader,
                                bodyLength: Int,
                                emit: (UnsafeRawBufferPointer) throws -> Void) throws {
        let stream = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1)
        defer { stream.deallocate() }

        // `COMPRESSION_ZLIB` is raw DEFLATE here, with no zlib wrapper of its
        // own, which is exactly what sits inside a gzip file.
        guard compression_stream_init(stream, COMPRESSION_STREAM_DECODE, COMPRESSION_ZLIB) == COMPRESSION_STATUS_OK else {
            throw HadithArchiveError.corrupt
        }
        defer { compression_stream_destroy(stream) }

        let destination = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { destination.deallocate() }

        var remaining = bodyLength
        var finished = false

        while remaining > 0 {
            guard let chunk = try reader.next(maxBytes: remaining) else {
                throw HadithArchiveError.truncated
            }
            remaining -= chunk.count
            // Only the last chunk is finalized. Without it the decoder keeps
            // its tail — up to one window — and never reports the end.
            let isLast = remaining == 0
            let flags = isLast ? Int32(COMPRESSION_STREAM_FINALIZE.rawValue) : 0

            finished = try chunk.withUnsafeBytes { raw -> Bool in
                guard let base = raw.bindMemory(to: UInt8.self).baseAddress else { return false }
                stream.pointee.src_ptr = base
                stream.pointee.src_size = raw.count
                var lastSrcSize = raw.count

                while true {
                    stream.pointee.dst_ptr = destination
                    stream.pointee.dst_size = bufferSize

                    let status = compression_stream_process(stream, flags)
                    let produced = bufferSize - stream.pointee.dst_size
                    if produced > 0 {
                        try emit(UnsafeRawBufferPointer(start: destination, count: produced))
                    }

                    switch status {
                    case COMPRESSION_STATUS_END:
                        return true
                    case COMPRESSION_STATUS_OK:
                        // On a middle chunk, an empty source means it is time
                        // to read more. On the last one the decoder is still
                        // draining, so the loop carries on.
                        if stream.pointee.src_size == 0, !isLast { return false }
                        // Neither consumed nor produced: the stream is stuck,
                        // and looping again would hang the download.
                        if produced == 0, stream.pointee.src_size == lastSrcSize {
                            throw HadithArchiveError.corrupt
                        }
                        lastSrcSize = stream.pointee.src_size
                    default:
                        throw HadithArchiveError.corrupt
                    }
                }
            }
            if finished { break }
        }

        guard finished else { throw HadithArchiveError.truncated }
    }

    // MARK: Helpers

    private static func hexString<D: Sequence>(_ digest: D) -> String where D.Element == UInt8 {
        digest.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Chunk reader

/// Reads a file in chunks while still allowing a few bytes to be taken off the
/// front, which is what parsing the gzip header needs.
///
/// Every `Data` it hands back is freshly based at zero, so callers can index
/// it from `0` without tripping over a slice's inherited offsets.
private final class ChunkReader {

    private let handle: FileHandle
    private let chunkSize: Int
    private var pending = Data()
    private var reachedEnd = false

    /// How many bytes have been handed out so far, which is how the caller
    /// works out where the gzip header ended.
    private(set) var consumed = 0

    init(handle: FileHandle, chunkSize: Int) {
        self.handle = handle
        self.chunkSize = chunkSize
    }

    /// The next block of bytes, never longer than `maxBytes`, or `nil` at the
    /// end of the file.
    func next(maxBytes: Int) throws -> Data? {
        guard maxBytes > 0 else { return nil }
        if pending.isEmpty, let more = try readMore() { pending = more }
        guard !pending.isEmpty else { return nil }

        let count = min(maxBytes, pending.count)
        let head = Data(pending.prefix(count))
        pending = Data(pending.dropFirst(count))
        consumed += count
        return head
    }

    /// Exactly `count` bytes off the front, or `nil` if the file ends first.
    func take(_ count: Int) throws -> Data? {
        guard try fill(to: count) else { return nil }
        let head = Data(pending.prefix(count))
        pending = Data(pending.dropFirst(count))
        consumed += count
        return head
    }

    /// Discards `count` bytes. `false` if the file ends first.
    @discardableResult
    func skip(_ count: Int) throws -> Bool {
        try take(count) != nil
    }

    /// Discards a zero-terminated string, as the gzip header stores names.
    func skipCString() throws {
        while true {
            guard let byte = try take(1)?.first else { throw HadithArchiveError.truncated }
            if byte == 0 { return }
        }
    }

    private func fill(to count: Int) throws -> Bool {
        while pending.count < count {
            guard let more = try readMore() else { return false }
            pending.append(more)
        }
        return true
    }

    private func readMore() throws -> Data? {
        guard !reachedEnd else { return nil }
        guard let chunk = try handle.read(upToCount: chunkSize), !chunk.isEmpty else {
            reachedEnd = true
            return nil
        }
        return chunk
    }
}
