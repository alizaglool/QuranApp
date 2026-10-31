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
    public let body: String
    public let soundFileName: String?
    public let dateComponents: DateComponents

    public init(identifier: String,
                title: String,
                body: String,
                soundFileName: String?,
                dateComponents: DateComponents) {
        self.identifier = identifier
        self.title = title
        self.body = body
        self.soundFileName = soundFileName
        self.dateComponents = dateComponents
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
        content.sound = draft.soundFileName
            .map { UNNotificationSound(named: UNNotificationSoundName($0)) } ?? .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: draft.dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: draft.identifier, content: content, trigger: trigger)
        try? await center.add(request)
    }
}
