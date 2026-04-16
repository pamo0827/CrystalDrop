import Foundation
import CoreLocation
import Combine

@MainActor
final class LocationService: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var locationName: String = ""
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var error: LocationError?

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    private enum Keys {
        static let name = "savedLocationName"
        static let latitude = "savedLatitude"
        static let longitude = "savedLongitude"
    }

    var hasSavedLocation: Bool {
        UserDefaults.standard.object(forKey: Keys.latitude) != nil
    }

    enum LocationError: LocalizedError {
        case denied
        case unavailable
        case geocodingFailed

        var errorDescription: String? {
            switch self {
            case .denied:
                return "位置情報の使用が許可されていません。\n設定アプリから許可してください。"
            case .unavailable:
                return "現在地を取得できませんでした。"
            case .geocodingFailed:
                return "地名を取得できませんでした。"
            }
        }
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        authorizationStatus = manager.authorizationStatus
        loadSavedLocation()
    }

    private func loadSavedLocation() {
        guard let name = UserDefaults.standard.string(forKey: Keys.name),
              UserDefaults.standard.object(forKey: Keys.latitude) != nil else { return }
        let lat = UserDefaults.standard.double(forKey: Keys.latitude)
        let lon = UserDefaults.standard.double(forKey: Keys.longitude)
        locationName = name
        currentLocation = CLLocation(latitude: lat, longitude: lon)
    }

    private func persistLocation(name: String, latitude: Double, longitude: Double) {
        UserDefaults.standard.set(name, forKey: Keys.name)
        UserDefaults.standard.set(latitude, forKey: Keys.latitude)
        UserDefaults.standard.set(longitude, forKey: Keys.longitude)
    }

    func requestLocation() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            error = .denied
        @unknown default:
            break
        }
    }

    func setManualLocation(name: String, latitude: Double, longitude: Double) {
        guard (-90...90).contains(latitude), (-180...180).contains(longitude) else { return }
        locationName = name
        currentLocation = CLLocation(latitude: latitude, longitude: longitude)
        persistLocation(name: name, latitude: latitude, longitude: longitude)
    }

    private func reverseGeocode(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, geoError in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if geoError != nil {
                    self.error = .geocodingFailed
                    return
                }
                if let placemark = placemarks?.first {
                    let admin = placemark.administrativeArea ?? ""
                    let sub = placemark.locality ?? placemark.subAdministrativeArea ?? ""
                    let name = admin + sub
                    self.locationName = name
                    self.persistLocation(
                        name: name,
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude
                    )
                }
            }
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = location
            self.reverseGeocode(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.error = .unavailable
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse
                || manager.authorizationStatus == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }
}
