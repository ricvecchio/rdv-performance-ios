import SwiftUI
import MapKit

// Tela de demonstração do mapa com localização do usuário e persistência de coordenadas
struct MapDemoView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var vm = MapViewModel()
    @State private var showSavedToggle: Bool = true
    private let profileStore = LocalProfileStore.shared

    // ✅ iOS 17+ Map usa position ao invés de coordinateRegion
    @State private var cameraPosition: MapCameraPosition = .automatic

    // Retorna a coordenada salva da academia do usuário atual
    private var academyCoordinate: CLLocationCoordinate2D? {
        profileStore.getLastSeenCoordinate(userId: session.currentUid)
    }

    @State private var annotationItems: [MapPin] = []

    // ✅ Snapshot Equatable para observar mudanças em MKCoordinateRegion sem exigir Equatable
    private var regionSnapshot: RegionSnapshot {
        RegionSnapshot(
            lat: vm.region.center.latitude,
            lon: vm.region.center.longitude,
            latDelta: vm.region.span.latitudeDelta,
            lonDelta: vm.region.span.longitudeDelta
        )
    }

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
                mapView
                    .edgesIgnoringSafeArea(.all)

                HStack(spacing: 12) {
                    Button(action: {
                        vm.centerOnUser()
                        // ✅ Mantém o mapa sincronizado quando o app altera vm.region (centrar)
                        cameraPosition = .region(vm.region)
                    }) {
                        Label("Centrar", systemImage: "location.fill")
                    }
                    .buttonStyle(.bordered)

                    Toggle(isOn: $showSavedToggle) {
                        Text("Salvar última localização")
                    }
                    .onChange(of: showSavedToggle) { _, newValue in
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
        .onAppear {
            vm.requestPermissionIfNeeded()
            showSavedToggle = profileStore.getMapDemoEnabled(userId: session.currentUid)
            setupAnnotations()

            // ✅ Inicializa o mapa na região atual do VM
            cameraPosition = .region(vm.region)
        }
    }

    // ✅ Quebra o Map em uma subview para o compilador não “engasgar”
    private var mapView: some View {
        Map(position: $cameraPosition, interactionModes: .all) {
            // ✅ Substitui showsUserLocation: true (não existe nesse initializer) pelo conteúdo moderno
            UserAnnotation()

            ForEach(annotationItems) { item in
                Marker("", coordinate: item.coordinate)
                    .tint(.red)
            }
        }
        .onChange(of: vm.lastLocation) { _, _ in
            if let loc = vm.lastLocation, showSavedToggle {
                profileStore.setLastSeenCoordinate(loc.coordinate, userId: session.currentUid)
            }
            setupAnnotations()
        }
        .onChange(of: vm.authorizationStatus) { _, status in
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                vm.startUpdating()
            } else {
                vm.stopUpdating()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                setupAnnotations()
            }
        }
        .onChange(of: regionSnapshot) { _, _ in
            // ✅ Mantém o mapa sincronizado quando o app altera vm.region (ex: setupAnnotations)
            cameraPosition = .region(vm.region)
        }
    }

    // Configura os marcadores no mapa baseado na coordenada salva ou localização atual
    private func setupAnnotations() {
        DispatchQueue.main.async {
            annotationItems.removeAll()

            if let coord = academyCoordinate {
                annotationItems.append(MapPin(id: "academy", coordinate: coord))
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    vm.region.center = coord
                    cameraPosition = .region(vm.region)
                }
            } else if let last = vm.lastLocation {
                annotationItems.append(MapPin(id: "last", coordinate: last.coordinate))
            }
        }
    }

    // Abre as configurações do sistema para o usuário habilitar localização
    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

// Representa um marcador no mapa com identificador único e coordenadas
private struct MapPin: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
}

// ✅ Snapshot Equatable do region (pra usar onChange sem MKCoordinateRegion: Equatable)
private struct RegionSnapshot: Equatable {
    let lat: Double
    let lon: Double
    let latDelta: Double
    let lonDelta: Double
}

struct MapDemoView_Previews: PreviewProvider {
    static var previews: some View {
        MapDemoView()
            .environmentObject(AppSession())
    }
}

