//
//  AppDelegate.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 21/04/2025.
//

import UIKit
import Core
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, AppDelegateProtocol {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FontsManager.registerFonts()
        ReciterLibrary.warmUp()
        RadioCatalogService.shared.warmUp()
        ContentCatalogRefresher.shared.start()
        startPrayerNotifications()
        startKhatmahReminders()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Background URLSession

    /// Stored completion handler from the system — called after DownloadManager
    /// finishes processing all pending background download events.
    var backgroundSessionCompletionHandler: (() -> Void)?

    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        backgroundSessionCompletionHandler = completionHandler
        // Accessing shared recreates the session if needed so its delegate
        // is live and can receive the pending callbacks from the OS.
        switch BackgroundSessionOwner(sessionIdentifier: identifier) {
        case .quranImagePacks:
            _ = QuranImagePackStore.shared
        case .athkarAudio:
            _ = AthkarAudioDownloadManager.shared
        case .recitationAudio:
            _ = DownloadManager.shared
        }
    }

}

// MARK: - Prayer Notifications

private extension AppDelegate {

    func startPrayerNotifications() {
        let manager = PrayerNotificationManager.shared
        UNUserNotificationCenter.current().delegate = manager
        manager.startObservingPrayerTimes()
        manager.rescheduleFromPrayerTimesStore()
    }
}

// MARK: - Khatmah Reminders

private extension AppDelegate {

    func startKhatmahReminders() {
        let scheduler = KhatmahReminderScheduler.shared
        scheduler.startObservingPlanChanges()
        scheduler.rescheduleFromStore()
    }
}

// MARK: - Background Session Owner

enum BackgroundSessionOwner: Equatable {
    case quranImagePacks
    case athkarAudio
    case recitationAudio

    init(sessionIdentifier: String) {
        switch sessionIdentifier {
        case QuranImagePackStore.backgroundSessionIdentifier:
            self = .quranImagePacks
        case AthkarAudioDownloadManager.backgroundSessionIdentifier:
            self = .athkarAudio
        default:
            self = .recitationAudio
        }
    }
}
