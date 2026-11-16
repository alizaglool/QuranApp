//
//  LocalNotificationCenter.swift
//  Core
//
//  Created by Ali Zaghloul on 30/10/2026.
//

import Foundation
import UserNotifications

public enum LocalNotificationAuthorizationStatus {
    case notDetermined
    case denied
    case authorized
    case provisional

    public var allowsScheduling: Bool {
        switch self {
        case .authorized, .provisional: return true
        case .notDetermined, .denied: return false
        }
    }

    public var isDenied: Bool { self == .denied }

    public init(_ status: UNAuthorizationStatus) {
        switch status {
        case .authorized, .ephemeral: self = .authorized
        case .provisional: self = .provisional
        case .denied: self = .denied
        case .notDetermined: self = .notDetermined
        @unknown default: self = .notDetermined
        }
    }
}

public struct LocalNotificationRequestDraft: Equatable {

    public let identifier: String
    public let title: String
    public let subtitle: String?
    public let body: String
    public let soundFileName: String?
    public let dateComponents: DateComponents
    public let secondsFromNow: TimeInterval?

    public init(identifier: String,
                title: String,
                subtitle: String? = nil,
                body: String,
                soundFileName: String?,
                dateComponents: DateComponents,
                secondsFromNow: TimeInterval? = nil) {
        self.identifier = identifier
        self.title = title
        self.subtitle = subtitle
        self.body = body
        self.soundFileName = soundFileName
        self.dateComponents = dateComponents
        self.secondsFromNow = secondsFromNow
    }
}

@MainActor
public protocol LocalNotificationCenter: AnyObject {
    func currentAuthorizationStatus() async -> LocalNotificationAuthorizationStatus
    func requestAuthorization() async -> LocalNotificationAuthorizationStatus
    func pendingRequestIdentifiers() async -> [String]
    func removeRequests(withIdentifiers identifiers: [String])
    func add(_ draft: LocalNotificationRequestDraft) async
}

@MainActor
public final class SystemLocalNotificationCenter: LocalNotificationCenter {

    private let center = UNUserNotificationCenter.current()

    public init() {}

    public func currentAuthorizationStatus() async -> LocalNotificationAuthorizationStatus {
        let settings = await center.notificationSettings()
        return LocalNotificationAuthorizationStatus(settings.authorizationStatus)
    }

    public func requestAuthorization() async -> LocalNotificationAuthorizationStatus {
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        return await currentAuthorizationStatus()
    }

    public func pendingRequestIdentifiers() async -> [String] {
        await center.pendingNotificationRequests().map(\.identifier)
    }

    public func removeRequests(withIdentifiers identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    public func add(_ draft: LocalNotificationRequestDraft) async {
        let content = UNMutableNotificationContent()
        content.title = draft.title
        content.body = draft.body

        if let subtitle = draft.subtitle, !subtitle.isEmpty {
            content.subtitle = subtitle
        }

        content.sound = draft.soundFileName
            .map { UNNotificationSound(named: UNNotificationSoundName($0)) } ?? .default

        let request = UNNotificationRequest(identifier: draft.identifier,
                                            content: content,
                                            trigger: trigger(for: draft))
        try? await center.add(request)
    }

    private func trigger(for draft: LocalNotificationRequestDraft) -> UNNotificationTrigger {
        guard let secondsFromNow = draft.secondsFromNow else {
            return UNCalendarNotificationTrigger(dateMatching: draft.dateComponents, repeats: false)
        }

        return UNTimeIntervalNotificationTrigger(timeInterval: max(1, secondsFromNow), repeats: false)
    }
}
