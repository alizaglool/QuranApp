//
//  SheikhChannel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 25/09/2026.
//

import Foundation

// MARK: - SheikhChannel

/// One curated entry from the remote sheikh list.
///
/// `name` is the editorial Arabic name. It is deliberately kept separate from
/// YouTube's `snippet.title`, which follows whatever the channel owner renames
/// their channel to.
struct SheikhChannel: Codable, Sendable, Equatable {
    let id: String
    let name: String
}
