//
//  DhikrAudioService.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 26/09/2026
//

import Foundation
import AVFoundation

@MainActor
final class DhikrAudioService {

    private(set) var isPlaying: Bool = false
    var onStateChange: ((Bool) -> Void)?

    private var player: AVAudioPlayer?
    private var playerDelegate: DhikrAudioPlayerDelegate?
    private var playsCompleted: Int = 0
    private var targetPlays: Int = 1

    private let searchExtensions = ["m4a", "mp3", "aac", "caf"]
    private let subdirectory = "Audio"

    // MARK: - Playback

    func play(resource: String, repeats: Int) {
        stop()
        guard let url = resourceURL(for: resource) else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            let player = try AVAudioPlayer(contentsOf: url)
            let delegate = DhikrAudioPlayerDelegate { [weak self] finishedSuccessfully in
                self?.handlePlaybackFinished(successfully: finishedSuccessfully)
            }
            player.delegate = delegate

            self.player = player
            self.playerDelegate = delegate
            targetPlays = max(1, repeats)
            playsCompleted = 0

            player.play()
            setPlaying(true)
        } catch {
            setPlaying(false)
        }
    }

    func stop() {
        player?.stop()
        player = nil
        playerDelegate = nil
        playsCompleted = 0
        targetPlays = 1
        setPlaying(false)
    }

    // MARK: - Resource lookup

    private func resourceURL(for resource: String) -> URL? {
        let name = (resource as NSString).deletingPathExtension
        let declared = (resource as NSString).pathExtension
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

    // MARK: - Private

    private func handlePlaybackFinished(successfully: Bool) {
        playsCompleted += 1
        guard successfully, playsCompleted < targetPlays, let player else {
            stop()
            return
        }
        player.currentTime = 0
        player.play()
    }

    private func setPlaying(_ value: Bool) {
        isPlaying = value
        onStateChange?(value)
    }
}

private final class DhikrAudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {

    private let onFinish: (Bool) -> Void

    init(onFinish: @escaping (Bool) -> Void) {
        self.onFinish = onFinish
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.onFinish(flag) }
    }
}
