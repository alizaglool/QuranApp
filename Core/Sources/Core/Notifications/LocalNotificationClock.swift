//
//  LocalNotificationClock.swift
//  Core
//
//  Created by Ali Zaghloul on 30/10/2026.
//

import Foundation

public protocol LocalNotificationClock {
    var currentDate: Date { get }
}

public struct SystemLocalNotificationClock: LocalNotificationClock {

    public init() {}

    public var currentDate: Date { Date() }
}
