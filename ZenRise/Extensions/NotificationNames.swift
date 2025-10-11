//
//  NotificationNames.swift
//  ZenRise
//
//  Created by Pavan Khiani on 2024-12-28.
//

import Foundation

extension Notification.Name {
    static let openSleepReadinessQuiz = Notification.Name("openSleepReadinessQuiz")
    static let wakeTimeUpdated = Notification.Name("wakeTimeUpdated")
    static let suppressAlarmRescheduling = Notification.Name("suppressAlarmRescheduling")
    static let enableAlarmRescheduling = Notification.Name("enableAlarmRescheduling")
    static let alarmDidFire = Notification.Name("alarmDidFire")
    static let alarmDidSnooze = Notification.Name("alarmDidSnooze")
}
