//
//  AdhanAudioFocus.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 02/11/2026.
//

import Foundation

@MainActor
protocol AdhanAudioFocus: AnyObject {
    func pauseCompetingPlayback()
}

@MainActor
final class AppAdhanAudioFocus: AdhanAudioFocus {

    func pauseCompetingPlayback() {
        if AudioEngine.shared.isPlaying {
            AudioEngine.shared.pause()
        }

        if AudioEngine.library.isPlaying {
            AudioEngine.library.pause()
        }

        if RadioPlayer.shared.isPlaying {
            RadioPlayer.shared.pause()
        }
    }
}
