import Foundation
import UserNotifications
import UIKit

enum NotificationAuthorizationState: Equatable { case notDetermined, authorized, provisional, denied }

@MainActor final class NotificationService {
    func status() async -> NotificationAuthorizationState {
        switch await UNUserNotificationCenter.current().notificationSettings().authorizationStatus {
        case .authorized: .authorized
        case .provisional, .ephemeral: .provisional
        case .denied: .denied
        default: .notDetermined
        }
    }
    func requestAndSchedule() async {
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
        let currentStatus = await status()
        if currentStatus == .authorized || currentStatus == .provisional { await schedule() }
    }
    func schedule() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["earth-guide-0900", "earth-guide-2000"])
        for (identifier, hour, title) in [("earth-guide-0900", 9, "今日任务"), ("earth-guide-2000", 20, "地球Online")] {
            let content = UNMutableNotificationContent(); content.title = title; content.body = "打开小向导查看今天的任务"; content.sound = .default
            var components = DateComponents(); components.hour = hour; components.minute = 0
            try? await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true)))
        }
    }
    func openSettings() { guard let url = URL(string: UIApplication.openSettingsURLString) else { return }; UIApplication.shared.open(url) }
}

protocol AudioPlayback { func playMusicIfAvailable(); func playSoundEffectIfAvailable() }
struct NoAssetAudioPlayback: AudioPlayback { func playMusicIfAvailable() {}; func playSoundEffectIfAvailable() {} }
