import SwiftUI
import MapKit

struct MapDemoView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var vm = MapViewModel()
    @State private var showSavedToggle: Bool = true
    private let profileStore = LocalProfileStore.shared

    private var academyCoordinate: CLLocationCoordinate2D? {
        profileStore.getLastSeenCoordinate(userId: session.currentUid)
    }

    @State private var annotationItems: [MapPin] = []

    var body: some View {
        VStack(spacing: 0) {
            if vm.authorizationStatus == .denied || vm.authorizationStatus == .restricted {
                VStack(spacing: 12) {
                    Text("Permissão de localização negada. Habilite em Ajustes para ver sua posição no mapa.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button(action: openSettings) {
                        Text("Abrir Ajustes")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                }
                .padding(.vertical, 20)
            }

            ZStack(alignment: .bottom) {
                Map(coordinateRegion: $vm.region, showsUserLocation: true, annotationItems: annotationItems) { item in
                    MapMarker(coordinate: item.coordinate, tint: .red)
                }
                .onAppear {
                    vm.requestPermissionIfNeeded()
                    showSavedToggle = profileStore.getMapDemoEnabled(userId: session.currentUid)
                    setupAnnotations()
                }
                .onChange(of: vm.lastLocation) { _ in
                    if let loc = vm.lastLocation, showSavedToggle {
                        profileStore.setLastSeenCoordinate(loc.coordinate, userId: session.currentUid)
                    }
                    setupAnnotations()
                }
                .onChange(of: vm.authorizationStatus) { status in
                    if status == .authorizedWhenInUse || status == .authorizedAlways {
                        vm.startUpdating()
                    } else {
                        vm.stopUpdating()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        setupAnnotations()
                    }
                }
                .edgesIgnoringSafeArea(.all)

                HStack(spacing: 12) {
                    Button(action: { vm.centerOnUser() }) {
                        Label("Centrar", systemImage: "location.fill")
                    }
                    .buttonStyle(.bordered)

                    Toggle(isOn: $showSavedToggle) {
                        Text("Salvar última localização")
                    }
                    .onChange(of: showSavedToggle) { newValue in
                        profileStore.setMapDemoEnabled(newValue, userId: session.currentUid)
                        if !newValue {
                            profileStore.setLastSeenCoordinate(nil, userId: session.currentUid)
                        }
                        setupAnnotations()
                    }
                    .toggleStyle(.switch)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .padding()
            }
        }
        .navigationTitle("Mapa (demo)")
        .onAppear { setupAnnotations() }
    }

    private func setupAnnotations() {
        DispatchQueue.main.async {
            annotationItems.removeAll()
            if let coord = academyCoordinate {
                annotationItems.append(MapPin(id: "academy", coordinate: coord))
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    vm.region.center = coord
                }
            } else if let last = vm.lastLocation {
                annotationItems.append(MapPin(id: "last", coordinate: last.coordinate))
            }
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

private struct MapPin: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
}

struct MapDemoView_Previews: PreviewProvider {
    static var previews: some View {
        MapDemoView()
            .environmentObject(AppSession())
    }
}
