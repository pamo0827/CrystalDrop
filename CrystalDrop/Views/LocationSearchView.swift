import SwiftUI
import CoreLocation
import MapKit

struct LocationSearchView: View {
    @ObservedObject var locationService: LocationService
    @Environment(\.dismiss) private var dismiss
    let onLocationSelected: () -> Void
    var isInitial: Bool = false

    @State private var searchText = ""
    @State private var searchResults: [MKLocalSearchCompletion] = []
    #if DEBUG
    @State private var debugTapCount = 0
    #endif

    @StateObject private var completerDelegate = CompleterDelegate()

    private var gradient: LinearGradient {
        LinearGradient(colors: AppColors.rainyGradients, startPoint: .top, endPoint: .bottom)
    }

    var body: some View {
        ZStack {
            gradient.ignoresSafeArea()
            
            waveLayers

            VStack(spacing: 0) {
                if !isInitial {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(16)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }

                Spacer().frame(height: isInitial ? 60 : 30)

                if !isInitial {
                    CrystalDropIcon(size: 110)
                    Spacer().frame(height: 24)
                }

                Text("どこの天気を知りたい？")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    #if DEBUG
                    .onTapGesture(count: 3) {
                        activateDebugRainy()
                    }
                    #endif

                Spacer().frame(height: 30)

                searchBarView
                    .padding(.horizontal, 24)
                
                if !searchResults.isEmpty {
                    ScrollView {
                        resultsList
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                    }
                } else {
                    Spacer().frame(height: 40)
                    currentLocationButton
                }

                Spacer()
            }
        }
        .onChange(of: searchText) { old, new in
            completerDelegate.completer.queryFragment = new
        }
        .onReceive(completerDelegate.$results) { results in
            self.searchResults = results
        }
    }

    private var waveLayers: some View {
        WaveLayerView(condition: .rainy)
    }

    private var searchBarView: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.6))

            TextField("例：新宿区、大阪市", text: $searchText)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .tint(.white)
                .submitLabel(.search)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(.white.opacity(0.15))
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 32))
        )
    }

    private var currentLocationButton: some View {
        Button {
            #if DEBUG
            UserDefaults.standard.removeObject(forKey: "debugForceRainy")
            #endif
            locationService.requestLocation()
            dismiss()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                Text("現在地を使用する")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .background(
                Capsule()
                    .fill(AppColors.accent.opacity(0.8))
            )
        }
    }

    private var resultsList: some View {
        VStack(spacing: 0) {
            ForEach(searchResults, id: \.self) { result in
                Button {
                    selectLocation(completion: result)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                        if !result.subtitle.isEmpty {
                            Text(result.subtitle)
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                }
                
                if result != searchResults.last {
                    Divider()
                        .background(.white.opacity(0.2))
                        .padding(.horizontal, 20)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white.opacity(0.1))
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24))
        )
    }

    // MARK: - Helpers

    #if DEBUG
    private func activateDebugRainy() {
        UserDefaults.standard.set(true, forKey: "debugForceRainy")
        // 東京駅の座標をダミーロケーションとして使用
        locationService.setManualLocation(name: "デバッグ（雨）", latitude: 35.6812, longitude: 139.7671)
        onLocationSelected()
        dismiss()
    }
    #endif

    private func selectLocation(completion: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let mapItem = response?.mapItems.first else { return }
            let name = mapItem.name ?? completion.title
            let coordinate = mapItem.placemark.coordinate

            #if DEBUG
            UserDefaults.standard.removeObject(forKey: "debugForceRainy")
            #endif

            locationService.setManualLocation(
                name: name,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            onLocationSelected()
            dismiss()
        }
    }

    class CompleterDelegate: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
        @Published var results: [MKLocalSearchCompletion] = []
        let completer = MKLocalSearchCompleter()

        override init() {
            super.init()
            completer.delegate = self
            completer.resultTypes = .address
        }

        func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
            results = completer.results
        }

        func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
            #if DEBUG
            print("Search error: \(error.localizedDescription)")
            #endif
        }
    }
}

#Preview {
    LocationSearchView(locationService: LocationService()) {}
}
