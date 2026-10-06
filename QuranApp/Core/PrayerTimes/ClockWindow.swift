//
//  ClockWindow.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 27/09/2026
//

import Foundation

/// A span of the day expressed in minutes since local midnight.
///
/// A window whose end lands before its start runs through midnight —
/// Isha → Fajr, for example — and `contains(_:)` handles that without any
/// calendar arithmetic, so a single day's prayer anchors are enough.
struct ClockWindow: Equatable {

    private static let minutesPerDay = 1440

    let start: Int
    let end: Int

    init(start: Int, end: Int) {
        self.start = ClockWindow.normalised(start)
        self.end = ClockWindow.normalised(end)
    }

    var wrapsMidnight: Bool { end < start }

    /// An end equal to the start covers nothing. Worth naming, because without
    /// the guard in `contains(_:)` such a window would read as the whole day.
    var isEmpty: Bool { end == start }

    /// Minutes covered, counting through midnight for a window that wraps.
    var length: Int { ClockWindow.normalised(end - start) }

    /// Half-open: the start minute is inside the window, the end minute is not.
    func contains(_ minutes: Int) -> Bool {
        guard !isEmpty else { return false }
        let point = ClockWindow.normalised(minutes)
        if wrapsMidnight {
            return point >= start || point < end
        }
        return point >= start && point < end
    }

    /// Folds any offset back onto the clock, so `sunset - 10` stays valid even
    /// for the theoretical case of an anchor within ten minutes of midnight.
    private static func normalised(_ minutes: Int) -> Int {
        ((minutes % minutesPerDay) + minutesPerDay) % minutesPerDay
    }
}
