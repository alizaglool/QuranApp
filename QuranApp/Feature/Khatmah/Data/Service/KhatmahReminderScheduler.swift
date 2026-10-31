//
//  KhatmahReminderScheduler.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import Foundation
import Combine
import UIKit
import Core

@MainActor
final class KhatmahReminderScheduler: ObservableObject {

    static let shared = KhatmahReminderScheduler(
        center: SystemLocalNotificationCenter(),
        store: KhatmahPlanStore.shared,
        clock: SystemLocalNotificationClock()
    )

    @Published private(set) var authorizationStatus: LocalNotificationAuthorizationStatus = .notDetermined
    @Published private(set) var scheduledRequestCount: Int = 0

    private let scheduler: LocalNotificationScheduler
    private let builder: KhatmahReminderScheduleBuilder
    private let store: KhatmahPlanStore
    private var cancellables = Set<AnyCancellable>()
    private var rescheduleTask: Task<Void, Never>?

    init(center: LocalNotificationCenter, store: KhatmahPlanStore, clock: LocalNotificationClock) {
        self.scheduler = LocalNotificationScheduler(
            center: center,
            ownedIdentifierPrefix: KhatmahNotificationIdentifier.ownedIdentifierPrefix
        )
        self.builder = KhatmahReminderScheduleBuilder(clock: clock)
        self.store = store
    }
}

// MARK: - Authorization

extension KhatmahReminderScheduler {

    func refreshAuthorizationStatus() async {
        authorizationStatus = await scheduler.currentAuthorizationStatus()
    }

    func requestAuthorization() async {
        let current = await scheduler.currentAuthorizationStatus()
        authorizationStatus = current == .notDetermined
            ? await scheduler.requestAuthorization()
            : current
        await reschedule()
    }
}

// MARK: - Scheduling

extension KhatmahReminderScheduler {

    func startObservingPlanChanges() {
        store.$activePlan
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in self?.rescheduleFromStore() }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in self?.rescheduleFromStore() }
            .store(in: &cancellables)
    }

    func rescheduleFromStore() {
        rescheduleTask?.cancel()
        rescheduleTask = Task { [weak self] in await self?.reschedule() }
    }

    func reschedule() async {
        let status = await scheduler.currentAuthorizationStatus()
        authorizationStatus = status

        guard status.allowsScheduling, let schedule = store.activeSchedule else {
            await scheduler.removeOwnedRequests()
            scheduledRequestCount = 0
            return
        }

        let entries = builder.entries(for: schedule)
        await scheduler.replaceOwnedRequests(with: entries.map(draft))
        scheduledRequestCount = entries.count
    }

    func pendingReminderIdentifiers() async -> [String] {
        await scheduler.pendingOwnedIdentifiers()
    }
}

// MARK: - Private

private extension KhatmahReminderScheduler {

    func draft(for entry: KhatmahReminderScheduleEntry) -> LocalNotificationRequestDraft {
        let body = String(format: AppLocalizedKeys.khatmahReminderBodyFormat.value,
                          localizedNumber(entry.firstPage),
                          localizedNumber(entry.lastPage))

        return LocalNotificationRequestDraft(identifier: entry.identifier,
                                             title: AppLocalizedKeys.khatmahReminderTitle.value,
                                             body: body,
                                             soundFileName: nil,
                                             dateComponents: entry.dateComponents)
    }

    func localizedNumber(_ value: Int) -> String {
        LocalizationManager.shared.currentLanguage == .Arabic ? value.arabicNumerals : "\(value)"
    }
}
