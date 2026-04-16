import SwiftUI

@main
struct CrystalDropApp: App {
    @StateObject private var locationService = LocationService()
    @State private var locationConfigured = UserDefaults.standard.object(forKey: "savedLatitude") != nil

    var body: some Scene {
        WindowGroup {
            Group {
                if !locationConfigured {
                    LocationSearchView(locationService: locationService) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            locationConfigured = true
                        }
                    }
                } else {
                    HomeView(locationService: locationService)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: locationConfigured)
        }
    }
}
