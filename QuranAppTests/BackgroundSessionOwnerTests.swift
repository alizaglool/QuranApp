//
//  BackgroundSessionOwnerTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import XCTest
@testable import QuranApp

final class BackgroundSessionOwnerTests: XCTestCase {

    // MARK: - Routing

    func testQuranImagePackIdentifierRoutesToImagePacks() {
        let owner = BackgroundSessionOwner(
            sessionIdentifier: QuranImagePackStore.backgroundSessionIdentifier
        )
        XCTAssertEqual(owner, .quranImagePacks)
    }

    func testAthkarAudioIdentifierRoutesToAthkarAudio() {
        let owner = BackgroundSessionOwner(
            sessionIdentifier: AthkarAudioDownloadManager.backgroundSessionIdentifier
        )
        XCTAssertEqual(owner, .athkarAudio)
    }

    func testRecitationAudioIdentifierRoutesToRecitationAudio() {
        let owner = BackgroundSessionOwner(sessionIdentifier: "com.quranapp.audio.download")
        XCTAssertEqual(owner, .recitationAudio)
    }

    func testUnknownIdentifierFallsBackToRecitationAudio() {
        let owner = BackgroundSessionOwner(sessionIdentifier: "com.quranapp.unknown.session")
        XCTAssertEqual(owner, .recitationAudio)
    }

    // MARK: - Identifier uniqueness

    func testOwnedIdentifiersAreDistinct() {
        XCTAssertNotEqual(
            QuranImagePackStore.backgroundSessionIdentifier,
            AthkarAudioDownloadManager.backgroundSessionIdentifier
        )
    }

    func testOwnedIdentifiersAreNotEmpty() {
        XCTAssertFalse(QuranImagePackStore.backgroundSessionIdentifier.isEmpty)
        XCTAssertFalse(AthkarAudioDownloadManager.backgroundSessionIdentifier.isEmpty)
    }
}
