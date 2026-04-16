import Foundation
import CoreLocation

final class WeatherService {
    private let baseURL = "https://api.open-meteo.com/v1/forecast"

    func fetchWeather(for location: CLLocation, locationName: String) async throws -> WeatherData {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude

        guard var components = URLComponents(string: baseURL) else {
            throw URLError(.badURL)
        }
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(format: "%.4f", lat)),
            URLQueryItem(name: "longitude", value: String(format: "%.4f", lon)),
            URLQueryItem(name: "hourly", value: "precipitation_probability,precipitation,temperature_2m"),
            URLQueryItem(name: "timezone", value: "Asia/Tokyo"),
            URLQueryItem(name: "forecast_days", value: "2"),
            URLQueryItem(name: "past_days", value: "1")
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }
        let (data, urlResponse) = try await URLSession.shared.data(from: url)
        guard (urlResponse as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        return parse(response: response, locationName: locationName)
    }

    private func parse(response: OpenMeteoResponse, locationName: String) -> WeatherData {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")

        let hourly = response.hourly
        var forecasts: [HourlyForecast] = []

        for i in 0..<hourly.time.count {
            guard let date = formatter.date(from: hourly.time[i]) else { continue }
            let prob = i < hourly.precipitationProbability.count ? hourly.precipitationProbability[i] : 0
            let precip = i < hourly.precipitation.count ? hourly.precipitation[i] : 0.0
            let temp = i < hourly.temperature.count ? hourly.temperature[i] : 0.0
            forecasts.append(HourlyForecast(time: date, precipitationProbability: prob, precipitation: precip, temperature: temp))
        }

        return WeatherData(locationName: locationName, hourlyForecasts: forecasts, fetchedAt: Date())
    }
}
