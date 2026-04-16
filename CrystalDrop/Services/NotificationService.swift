import Foundation
import UserNotifications

final class NotificationService {

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        return granted ?? false
    }

    /// 降水確率80%以上などのアラートをスケジュール
    func scheduleAlerts(for data: WeatherData) {
        let center = UNUserNotificationCenter.current()
        // 既存のアラート（日次以外）を削除
        center.getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier).filter { $0.hasPrefix("rain_alert_prob") }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }

        let now = Date()
        let relevantForecasts = data.hourlyForecasts.filter { $0.time > now && $0.precipitationProbability >= 80 }
        
        for forecast in relevantForecasts.prefix(5) { // 直近5つまでに制限
            let content = UNMutableNotificationContent()
            content.title = "⚠️ 強い雨の予報"
            content.body = "\(forecast.hourString)時ごろ、降水確率が\(forecast.precipitationProbability)%に達する見込みです。"
            content.sound = .default

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: forecast.time)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: "rain_alert_prob_\(forecast.time.timeIntervalSince1970)", content: content, trigger: trigger)

            center.add(request)
        }
    }

    /// 雨が止む直前の通知をスケジュール
    func scheduleRainStopNotification(at stopTime: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["rain_alert_stop"])

        let content = UNMutableNotificationContent()
        content.title = "☁️ まもなく雨が止みます"
        content.body = "予報では間もなく雨が止む予定です。"
        content.sound = .default

        // 止む時間の5分前に通知（または即時）
        let triggerTime = max(Date(), stopTime.addingTimeInterval(-300))
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerTime)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "rain_alert_stop", content: content, trigger: trigger)

        center.add(request)
    }

    func scheduleDaily(at hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["rain_alert_daily"])

        let content = UNMutableNotificationContent()
        content.title = "☔ 今日の雨予報"
        content.body = "今日は雨の予報があります。傘をお忘れなく ☔"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "rain_alert_daily", content: content, trigger: trigger)

        center.add(request)
    }

    func cancelDaily() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["rain_alert_daily"])
    }
}
