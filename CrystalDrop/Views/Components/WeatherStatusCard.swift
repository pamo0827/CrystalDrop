import SwiftUI

struct WeatherStatusCard: View {
    let condition: WeatherCondition
    let timeMessage: String

    var body: some View {
        VStack(spacing: 16) {
            Text(condition.emoji)
                .font(.system(size: 80))
                .accessibilityLabel(accessibilityLabel)

            Text(condition.message)
                .font(.system(size: 22, weight: .semibold))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)

            if !timeMessage.isEmpty && condition != .sunny {
                Text(timeMessage)
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(condition.backgroundColor.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(.white.opacity(0.5), lineWidth: 1)
                )
        )
    }

    private var accessibilityLabel: String {
        switch condition {
        case .sunny:     return "晴れ"
        case .cloudy:    return "曇り時々雨"
        case .rainy:     return "雨"
        case .heavyRain: return "大雨"
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        WeatherStatusCard(condition: .sunny, timeMessage: "")
        WeatherStatusCard(condition: .heavyRain, timeMessage: "今日の午後3時ごろ")
    }
    .padding()
}
