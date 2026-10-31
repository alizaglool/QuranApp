//
//  AthkarAudioRepetitionPolicyTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 30/10/2026.
//

import XCTest
@testable import QuranApp

@MainActor
final class AthkarAudioRepetitionPolicyTests: XCTestCase {

    // MARK: - Auto repeat

    func testCountsWithinTheLimitAutoRepeatExactlyThatManyTimes() {
        for count in 2...AthkarItemAudioPlayer.autoRepeatCountLimit {
            XCTAssertEqual(AthkarItemAudioPlayer.audioPlayCount(forRepeatCount: count), count)
            XCTAssertEqual(AthkarItemAudioPlayer.heldRepetitionCount(forRepeatCount: count), count)
        }
    }

    func testRealPackCountsMapToTheExpectedNumberOfPlays() {
        XCTAssertEqual(AthkarItemAudioPlayer.audioPlayCount(forRepeatCount: 3), 3)
        XCTAssertEqual(AthkarItemAudioPlayer.audioPlayCount(forRepeatCount: 4), 4)
        XCTAssertEqual(AthkarItemAudioPlayer.audioPlayCount(forRepeatCount: 7), 7)
        XCTAssertEqual(AthkarItemAudioPlayer.audioPlayCount(forRepeatCount: 10), 10)
        XCTAssertEqual(AthkarItemAudioPlayer.audioPlayCount(forRepeatCount: 100), 1)
    }

    // MARK: - Single play

    func testMissingAndSingleCountsPlayOnce() {
        XCTAssertEqual(AthkarItemAudioPlayer.audioPlayCount(forRepeatCount: 0), 1)
        XCTAssertEqual(AthkarItemAudioPlayer.audioPlayCount(forRepeatCount: 1), 1)
        XCTAssertEqual(AthkarItemAudioPlayer.heldRepetitionCount(forRepeatCount: 0), 1)
        XCTAssertEqual(AthkarItemAudioPlayer.heldRepetitionCount(forRepeatCount: 1), 1)
    }

    // MARK: - Held counter

    func testCountsAboveTheLimitPlayOnceAndHoldTheCounter() {
        let aboveLimit = AthkarItemAudioPlayer.autoRepeatCountLimit + 1

        XCTAssertEqual(AthkarItemAudioPlayer.audioPlayCount(forRepeatCount: aboveLimit), 1)
        XCTAssertEqual(AthkarItemAudioPlayer.heldRepetitionCount(forRepeatCount: aboveLimit), aboveLimit)
        XCTAssertEqual(AthkarItemAudioPlayer.audioPlayCount(forRepeatCount: 100), 1)
        XCTAssertEqual(AthkarItemAudioPlayer.heldRepetitionCount(forRepeatCount: 100), 100)
    }

    func testNegativeCountIsTreatedAsASinglePlay() {
        XCTAssertEqual(AthkarItemAudioPlayer.audioPlayCount(forRepeatCount: -5), 1)
        XCTAssertEqual(AthkarItemAudioPlayer.heldRepetitionCount(forRepeatCount: -5), 1)
    }
}
