import SwiftUI

struct HourlyForecastRow: View {
    let forecasts: [HourlyForecast]

    private var displayForecasts: [HourlyForecast] {
        let now = Date()
        let in24Hours = now.addingTimeInterval(24 * 3600)
        return forecasts.filter { forecast in
            forecast.time >= now && forecast.time <= in24Hours
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(displayForecasts) { forecast in
                        HourlyCell(forecast: forecast)
                    }
                }
                .padding(.horizontal, 10)
            }
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white.opacity(0.15))
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24))
        )
    }
}

private struct HourlyCell: View {
    let forecast: HourlyForecast

    var body: some View {
        VStack(spacing: 8) {
            Text(forecast.isRainy ? "☔" : "☀️")
                .font(.system(size: 26))

            Text("\(forecast.precipitationProbability)%")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)

            Text(forecast.hourString + "時")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(minWidth: 50)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(forecast.hourString)時、降水確率\(forecast.precipitationProbability)パーセント")
    }
}

#Preview {
    let now = Date()
    let forecasts = (6...22).map { hour in
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: now)!
        return HourlyForecast(time: date, precipitationProbability: hour > 13 ? 70 : 10, precipitation: 0, temperature: 20.0)
    }
    HourlyForecastRow(forecasts: forecasts)
        .padding()
}
