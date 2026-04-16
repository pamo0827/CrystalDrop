import SwiftUI

enum WeatherCondition {
    case sunny        // 0〜20%
    case cloudy       // 20〜50%
    case rainy        // 50〜80%
    case heavyRain    // 80〜100%

    init(maxProbability: Int) {
        switch maxProbability {
        case 0..<20:  self = .sunny
        case 20..<50: self = .cloudy
        case 50..<80: self = .rainy
        default:      self = .heavyRain
        }
    }

    var emoji: String {
        switch self {
        case .sunny:     return "☀️"
        case .cloudy:    return "🌤"
        case .rainy:     return "🌧"
        case .heavyRain: return "☔"
        }
    }

    var message: String {
        switch self {
        case .sunny:
            return "今日は雨の心配はありません"
        case .cloudy:
            return "雨が降るかもしれません。\n折りたたみ傘があると安心です"
        case .rainy:
            return "雨が降りそうです。\n傘をお持ちください"
        case .heavyRain:
            return "雨が降ります。\n必ず傘をお持ちください"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .sunny:     return Color(red: 1.0, green: 0.95, blue: 0.7)
        case .cloudy:    return Color(red: 0.85, green: 0.9, blue: 1.0)
        case .rainy:     return Color(red: 0.7, green: 0.8, blue: 1.0)
        case .heavyRain: return Color(red: 0.6, green: 0.7, blue: 0.95)
        }
    }
}
