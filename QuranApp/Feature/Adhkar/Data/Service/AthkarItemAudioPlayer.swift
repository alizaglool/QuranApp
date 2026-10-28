//
//  AthkarItemAudioPlayer.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 27/10/2026.
//

import Foundation
import AVFoundation

@MainActor
final class AthkarItemAudioPlayer: ObservableObject {

    @Published private(set) var playingItemID: Int?
    @Published private(set) var hasFailed: Bool = false

    private let downloads = AthkarAudioDownloadManager.shared
    private let searchExtensions = ["m4a", "mp3", "aac", "caf"]
    private let subdirectory = "Audio"

    private var player: AVAudioPlayer?
    private var playerDelegate: AthkarItemAudioPlayerDelegate?

    // MARK: - Output

    func isPlaying(itemID: Int) -> Bool {
        playingItemID == itemID
    }

    func canPlay(item: AthkarItem, inPack packKey: String) -> Bool {
        url(for: item, inPack: packKey) != nil
    }

    // MARK: - Playback

    func toggle(item: AthkarItem, inPack packKey: String) {
        if playingItemID == item.id {
            stop()
        } else {
            play(item: item, inPack: packKey)
        }
    }

    func play(item: AthkarItem, inPack packKey: String) {
        stop()
        hasFailed = false

        guard let url = url(for: item, inPack: packKey) else {
            hasFailed = true
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            let player = try AVAudioPlayer(contentsOf: url)
            let delegate = AthkarItemAudioPlayerDelegate { [weak self] in
                self?.stop()
            }
            player.delegate = delegate

            self.player = player
            self.playerDelegate = delegate

            player.play()
            playingItemID = item.id
        } catch {
            hasFailed = true
            stop()
        }
    }

    func stop() {
        player?.stop()
        player = nil
        playerDelegate = nil
        playingItemID = nil
    }

    func clearFailure() {
        hasFailed = false
    }

    // MARK: - Resource lookup

    private func url(for item: AthkarItem, inPack packKey: String) -> URL? {
        guard item.hasAudio else { return nil }

        if let downloaded = downloads.localURL(for: item, inPack: packKey) {
            return downloaded
        }

        let name = (item.audio as NSString).deletingPathExtension
        let declared = (item.audio as NSString).pathExtension
        let candidates = declared.isEmpty
            ? searchExtensions
            : [declared] + searchExtensions.filter { $0 != declared }

        for ext in candidates {
            if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: subdirectory) {
                return url
            }
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                return url
            }
        }

        return nil
    }
}

// MARK: - Delegate

private final class AthkarItemAudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {

    private let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.onFinish() }
    }
}
