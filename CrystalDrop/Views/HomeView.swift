import SwiftUI
import CoreLocation

// MARK: - ViewModel

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var weatherData: WeatherData?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let weatherService = WeatherService()
    private let notificationService = NotificationService()

    func fetchWeather(location: CLLocation, name: String) async {
        guard !Task.isCancelled else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        #if DEBUG
        if UserDefaults.standard.bool(forKey: "debugForceRainy") {
            weatherData = mockRainyData(name: name)
            return
        }
        #endif

        do {
            let data = try await weatherService.fetchWeather(for: location, locationName: name)
            weatherData = data
            notificationService.scheduleAlerts(for: data)
            if data.isCurrentlyRainy, let stopHour = data.rainStopHour {
                notificationService.scheduleRainStopNotification(at: stopHour.time)
            }
        } catch {
            errorMessage = "天気情報を取得できませんでした。\nもう一度お試しください。"
        }
    }

    #if DEBUG
    private func mockRainyData(name: String) -> WeatherData {
        let now = Date()
        let forecasts = (0..<48).map { i in
            HourlyForecast(
                time: now.addingTimeInterval(Double(i - 24) * 3600),
                precipitationProbability: 90,
                precipitation: 8.0,
                temperature: 18.0 + Double(i % 24) * 0.3
            )
        }
        return WeatherData(locationName: name, hourlyForecasts: forecasts, fetchedAt: now)
    }
    #endif
}

// MARK: - HomeView

struct HomeView: View {
    @ObservedObject var locationService: LocationService
    @StateObject private var viewModel = HomeViewModel()
    @State private var activeSheet: ActiveSheet?
    @State private var loadTask: Task<Void, Never>?
    @State private var currentPage = 0

    private enum ActiveSheet: Identifiable {
        case settings, search
        var id: Self { self }
    }

    var body: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()

            if viewModel.weatherData?.isCurrentlyRainy == true {
                RainfallView()
            }

            WaveLayerView(condition: viewModel.weatherData?.todayCondition ?? .sunny)

            VStack(spacing: 0) {
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(message: error)
                } else if let data = viewModel.weatherData {
                    weatherContent(data: data)
                } else {
                    emptyView
                }
                Spacer()
            }
            .padding(.top, 40)

            settingsButton

            if viewModel.weatherData != nil {
                pageIndicator
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .settings:
                SettingsView()
            case .search:
                LocationSearchView(locationService: locationService) {
                    scheduleLoad()
                }
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    withAnimation {
                        if value.translation.width < 0 {
                            currentPage = min(currentPage + 1, 1)
                        } else {
                            currentPage = max(currentPage - 1, 0)
                        }
                    }
                }
        )
        .task {
            scheduleLoad()
        }
        .onChange(of: locationService.locationName) { _, _ in
            scheduleLoad()
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        let colors = (viewModel.weatherData?.todayCondition ?? .sunny) == .sunny
            ? AppColors.sunnyGradients
            : AppColors.rainyGradients
        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }

    // MARK: - Location Label

    private var locationLabel: some View {
        VStack(spacing: 8) {
            Text(locationService.locationName.isEmpty ? "取得中..." : locationService.locationName)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)

            Button {
                activeSheet = .search
            } label: {
                Text("場所を変更")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 14)
                    .background(.white.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Weather Content

    @ViewBuilder
    private func weatherContent(data: WeatherData) -> some View {
        VStack(spacing: 40) {
            locationLabel

            TabView(selection: $currentPage) {
                PrecipitationPageView(data: data).tag(0)
                TemperaturePageView(diff: data.temperatureDiff).tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 220)
        }
        .padding(.top, 20)
    }

    // MARK: - Page Indicator

    private var pageIndicator: some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                ForEach(0..<2, id: \.self) { i in
                    Circle()
                        .fill(i == currentPage ? Color.white : Color.white.opacity(0.35))
                        .frame(width: 7, height: 7)
                }
            }
            .padding(.bottom, 96)
        }
    }

    // MARK: - Bottom Buttons

    private var settingsButton: some View {
        VStack {
            Spacer()
            HStack {
                Button {
                    scheduleLoad()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(16)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }

                Spacer()

                Button {
                    activeSheet = .settings
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(16)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }

    // MARK: - State Views

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(.white)
                .scaleEffect(1.5)
            Text("天気を取得中...")
                .foregroundStyle(.white)
        }
        .frame(maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.white)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
            Button("再試行") {
                scheduleLoad()
            }
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.3))
        }
        .frame(maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image("CrystalDropLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .shadow(radius: 10)
            Text("現在地から天気を取得します")
                .foregroundStyle(.white)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Actions

    private func scheduleLoad() {
        loadTask?.cancel()
        loadTask = Task { await loadWeather() }
    }

    private func loadWeather() async {
        guard let location = locationService.currentLocation,
              !locationService.locationName.isEmpty else { return }
        await viewModel.fetchWeather(location: location, name: locationService.locationName)
    }
}

// MARK: - Page Views

private struct PrecipitationPageView: View {
    let data: WeatherData

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(data.next24HoursMaxProbability)")
                    .font(.system(size: 120, weight: .black))
                Text("%")
                    .font(.system(size: 40, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .center)

            Text("今後24時間の最大降水確率")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white.opacity(0.9))

            if data.isCurrentlyRainy {
                if let hours = data.hoursUntilRainStops {
                    Text("だいたい\(hours)時間後に雨が止みます")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.top, 8)
                } else {
                    Text("しばらく雨が続く予報です")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.top, 8)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

private struct TemperaturePageView: View {
    let diff: Double?

    private var sign: String { (diff ?? 0) >= 0 ? "+" : "" }
    private var diffText: String {
        diff.map { "\(sign)\(Int($0.rounded()))" } ?? "--"
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(diffText)
                    .font(.system(size: 120, weight: .black))
                Text("℃")
                    .font(.system(size: 40, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .center)

            Text("前日同時刻との気温差")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    HomeView(locationService: LocationService())
}
