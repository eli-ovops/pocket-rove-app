import Foundation
import UserNotifications
import UIKit

enum NotificationAuthorizationState: Equatable { case notDetermined, authorized, provisional, denied }

struct NotificationRequest: Equatable { let identifier: String; let hour: Int; let minute: Int; let title: String; let body: String }

protocol NotificationCenterClient: AnyObject {
    func authorizationStatus() async -> NotificationAuthorizationState
    func requestAuthorization() async -> NotificationAuthorizationState
    func replace(_ requests: [NotificationRequest]) async throws
    func cancel(_ identifiers: [String]) async
}

enum NotificationSchedulePolicy {
    static let identifiers = ["earth-guide-0900", "earth-guide-2000"]
    static func requests(languageCode: String) -> [NotificationRequest] {
        let isEnglish = languageCode == "en"
        return [
            NotificationRequest(identifier: identifiers[0], hour: 9, minute: 0, title: isEnglish ? "Today's tasks" : "今日任务", body: isEnglish ? "Open Today to view your guide." : "打开小向导查看今天的任务"),
            NotificationRequest(identifier: identifiers[1], hour: 20, minute: 0, title: isEnglish ? "EarthOnline" : "地球Online", body: isEnglish ? "Open Today to view your guide." : "打开小向导查看今天的任务")
        ]
    }
}

@MainActor final class UNNotificationCenterClient: NotificationCenterClient {
    private let center = UNUserNotificationCenter.current()
    func authorizationStatus() async -> NotificationAuthorizationState {
        switch await center.notificationSettings().authorizationStatus { case .authorized: .authorized; case .provisional, .ephemeral: .provisional; case .denied: .denied; default: .notDetermined }
    }
    func requestAuthorization() async -> NotificationAuthorizationState {
        _ = try? await center.requestAuthorization(options: [.alert, .badge, .sound]); return await authorizationStatus()
    }
    func replace(_ requests: [NotificationRequest]) async throws {
        center.removePendingNotificationRequests(withIdentifiers: NotificationSchedulePolicy.identifiers)
        for request in requests {
            let content = UNMutableNotificationContent(); content.title = request.title; content.body = request.body
            var components = DateComponents(); components.hour = request.hour; components.minute = request.minute
            try await center.add(UNNotificationRequest(identifier: request.identifier, content: content, trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true)))
        }
    }
    func cancel(_ identifiers: [String]) async { center.removePendingNotificationRequests(withIdentifiers: identifiers) }
}

@MainActor final class NotificationService {
    private let client: NotificationCenterClient
    init(client: NotificationCenterClient = UNNotificationCenterClient()) { self.client = client }
    func status() async -> NotificationAuthorizationState { await client.authorizationStatus() }
    func requestAndSchedule(languageCode: String = "zh-Hans") async {
        let current = await client.requestAuthorization()
        guard current == .authorized || current == .provisional else { return }
        try? await client.replace(NotificationSchedulePolicy.requests(languageCode: languageCode))
    }
    func rescheduleIfAuthorized(languageCode: String) async {
        let current = await client.authorizationStatus()
        guard current == .authorized || current == .provisional else { return }
        try? await client.replace(NotificationSchedulePolicy.requests(languageCode: languageCode))
    }
    func cancel() async { await client.cancel(NotificationSchedulePolicy.identifiers) }
    func destinationForNotificationTap() -> AppTab { .today }
    func openSettings() { guard let url = URL(string: UIApplication.openSettingsURLString) else { return }; UIApplication.shared.open(url) }
}
