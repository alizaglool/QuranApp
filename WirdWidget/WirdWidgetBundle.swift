//
//  WirdWidgetBundle.swift
//  WirdWidget
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import SwiftUI
import WidgetKit

@main
struct WirdWidgetBundle: WidgetBundle {

    var body: some Widget {
        NextPrayerWidget()
        PrayerScheduleWidget()
        HijriDateWidget()
    }
}
