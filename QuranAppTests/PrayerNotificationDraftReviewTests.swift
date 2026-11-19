//
//  PrayerNotificationDraftReviewTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import XCTest
import Core
@testable import QuranApp

@MainActor
final class PrayerNotificationDraftReviewTests: XCTestCase {

    func testEveryScheduledDraftRendersForReview() async {
        var lines: [String] = []

        for language in [LocalizationManager.Language.Arabic, LocalizationManager.Language.English] {
            let original = LocalizationManager.shared.currentLanguage
            LocalizationManager.shared.currentLanguage = language

            let center = LocalNotificationCenterDouble(status: .authorized)
            let preferences = PrayerNotificationFixture.preferences(slots: Set(PrayerSlot.allCases),
                                                                    isReminderEnabled: true,
                                                                    leadMinutes: 15)
            let subject = PrayerNotificationManagerBuilder.manager(center: center,
                                                                    defaults: PrayerNotificationFixture.defaults(),
                                                                    preferences: preferences,
                                                                    now: PrayerNotificationFixture.date(dayKey: PrayerNotificationFixture.mondayDayKey,
                                                                                                        minutesSinceMidnight: 0))

            await subject.reschedule(day: PrayerNotificationFixture.day())
            await subject.reschedule(day: PrayerNotificationFixture.day(dayKey: PrayerNotificationFixture.nextFridayDayKey))

            lines.append("================ LANGUAGE \(language.rawValue) ================")

            for draft in center.addedDrafts.sorted(by: { $0.identifier < $1.identifier }) {
                lines.append(draft.identifier)
                lines.append("  TITLE    \(draft.title)")
                lines.append("  SUBTITLE \(draft.subtitle ?? "-")")
                lines.append("  BODY     \(draft.body.replacingOccurrences(of: "\n", with: " / "))")
                lines.append("")
            }

            LocalizationManager.shared.currentLanguage = original
        }

        lines.append("================ TWO CONSECUTIVE DAYS, FAJR ADHAN ================")

        for dayKey in ["2026-11-02", "2026-11-03", "2026-11-04", "2026-11-05", "2026-11-06"] {
            for slot in PrayerSlot.obligatorySlots {
                let content = PrayerNotificationContentCatalog.content(dayKey: dayKey, slot: slot, kind: .adhan)
                lines.append("\(dayKey) \(slot.rawValue).adhan -> \(content?.id ?? "nil")")
            }
        }

        let attachment = XCTAttachment(string: lines.joined(separator: "\n"))
        attachment.name = "notification-preview"
        attachment.lifetime = .keepAlways
        add(attachment)

        XCTAssertFalse(lines.isEmpty)
    }
}
