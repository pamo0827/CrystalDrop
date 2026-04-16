import Foundation

struct WeatherData {
    let locationName: String
    let hourlyForecasts: [HourlyForecast]
    let fetchedAt: Date

    var todayForecasts: [HourlyForecast] {
        let calendar = Calendar.current
        return hourlyForecasts.filter { calendar.isDateInToday($0.time) }
    }

    var tomorrowForecasts: [HourlyForecast] {
        let calendar = Calendar.current
        return hourlyForecasts.filter { calendar.isDateInTomorrow($0.time) }
    }

    /// 現在時刻の予報
    var currentForecast: HourlyForecast? {
        let now = Date()
        return hourlyForecasts.first { forecast in
            let diff = forecast.time.timeIntervalSince(now)
            return diff >= -1800 && diff < 1800 // ±30分
        }
    }

    /// 現在雨が降っているか (降水確率50%以上)
    var isCurrentlyRainy: Bool {
        currentForecast?.isRainy ?? false
    }

    /// 現在の雨が止む時間 (現在の雨が続いて、初めて非雨天になる時間)
    var rainStopHour: HourlyForecast? {
        guard isCurrentlyRainy else { return nil }

        let now = Date()
        let futureForecasts = hourlyForecasts.filter { $0.time > now }

        // 最初の「雨でない」時間帯を探す
        return futureForecasts.first { !$0.isRainy }
    }

    /// 現在から雨が止むまでの時間数（降水確率50%未満になるまで）
    var hoursUntilRainStops: Int? {
        guard let stopForecast = rainStopHour else { return nil }
        let hours = Int(stopForecast.time.timeIntervalSince(Date()) / 3600)
        return max(1, hours)
    }

    /// 前日同時刻との気温差（プラスなら昨日より暖かい）
    var temperatureDiff: Double? {
        let now = Date()
        let yesterdayNow = now.addingTimeInterval(-24 * 3600)

        guard let currentTemp = hourlyForecasts.first(where: {
            abs($0.time.timeIntervalSince(now)) < 1800
        })?.temperature,
        let yesterdayTemp = hourlyForecasts.first(where: {
            abs($0.time.timeIntervalSince(yesterdayNow)) < 1800
        })?.temperature else { return nil }

        return currentTemp - yesterdayTemp
    }

    /// 今日6:00〜22:00の最大降水確率
    var todayMaxProbability: Int {
        let calendar = Calendar.current
        let active = todayForecasts.filter { forecast in
            let hour = calendar.component(.hour, from: forecast.time)
            return hour >= 6 && hour <= 22
        }
        return active.map(\.precipitationProbability).max() ?? 0
    }

    /// 今後24時間の最大降水確率
    var next24HoursMaxProbability: Int {
        let now = Date()
        let in24Hours = now.addingTimeInterval(24 * 3600)
        let active = hourlyForecasts.filter { forecast in
            forecast.time >= now && forecast.time <= in24Hours
        }
        return active.map(\.precipitationProbability).max() ?? 0
    }

    var todayCondition: WeatherCondition {
        WeatherCondition(maxProbability: todayMaxProbability)
    }

    /// 今日の雨が始まる最初の時間帯（降水確率50%以上）
    var firstRainyHour: HourlyForecast? {
        let calendar = Calendar.current
        return todayForecasts.first { forecast in
            let hour = calendar.component(.hour, from: forecast.time)
            return hour >= 6 && hour <= 22 && forecast.precipitationProbability >= 50
        }
    }

    /// 今日のメイン予報メッセージ
    var todayMessage: String {
        let condition = todayCondition
        if condition == .sunny {
            return condition.message
        }
        if let rainyHour = firstRainyHour {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.dateFormat = "今日のH時ごろ"
            return formatter.string(from: rainyHour.time)
        }
        return condition.message
    }

    var tomorrowMaxProbability: Int {
        tomorrowForecasts.map(\.precipitationProbability).max() ?? 0
    }

    var tomorrowCondition: WeatherCondition {
        WeatherCondition(maxProbability: tomorrowMaxProbability)
    }
}

struct HourlyForecast: Identifiable {
    let id = UUID()
    let time: Date
    let precipitationProbability: Int
    let precipitation: Double
    let temperature: Double

    var isRainy: Bool {
        precipitationProbability >= 50
    }

    var hourString: String {
        Self.hourFormatter.string(from: time)
    }

    private static let hourFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "H"
        return f
    }()
}

// MARK: - Open-Meteo API Response

struct OpenMeteoResponse: Decodable {
    let hourly: HourlyData
}

struct HourlyData: Decodable {
    let time: [String]
    let precipitationProbability: [Int]
    let precipitation: [Double]
    let temperature: [Double]

    enum CodingKeys: String, CodingKey {
        case time
        case precipitationProbability = "precipitation_probability"
        case precipitation
        case temperature = "temperature_2m"
    }
}
