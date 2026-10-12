import SwiftUI
import MapKit

struct TeacherMapView: View {
    @Environment(\.locale) private var locale
    @EnvironmentObject private var session: AppSession
    @StateObject private var vm = MapViewModel()
    @State private var showSavedToggle: Bool = true
    private let profileStore = LocalProfileStore.shared

    // ✅ iOS 17+: Map usa "position" ao invés de "coordinateRegion"
    @State private var cameraPosition: MapCameraPosition = .automatic

    private var academyCoordinate: CLLocationCoordinate2D? {
        profileStore.getLastSeenCoordinate(userId: session.currentUid)
    }

    private var displayCoordinateText: String {
        let format: String
        if let coord = academyCoordinate {
            format = AppLocalization.string("ui.gym_5f_5f", locale: locale)
            return String(
                format: format,
                locale: locale,
                arguments: [coord.latitude, coord.longitude]
            )
        } else if let last = vm.lastLocation {
            format = AppLocalization.string("ui.last_5f_5f", locale: locale)
            return String(
                format: format,
                locale: locale,
                arguments: [last.coordinate.latitude, last.coordinate.longitude]
            )
        } else {
            return AppLocalization.string("ui.location", locale: locale)
        }
    }

    @State private var annotationItems: [MapPin] = []
    @State private var showEditLocationSheet: Bool = false

    // ✅ Snapshot Equatable para poder usar onChange sem exigir MKCoordinateRegion: Equatable
    private var regionSnapshot: RegionSnapshot {
        RegionSnapshot(
            lat: vm.region.center.latitude,
            lon: vm.region.center.longitude,
            latDelta: vm.region.span.latitudeDelta,
            lonDelta: vm.region.span.longitudeDelta
        )
    }

    var body: some View {
        ZStack {
            // Map em background ocupando toda a tela
            mapView
                .edgesIgnoringSafeArea(.all)

            // Overlay: conteúdo superior (badge)
            VStack {
                HStack {
                    Spacer()
                    Text(displayCoordinateText)
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color.black.opacity(0.45))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.trailing, 16)
                }
                .padding(.top, 8)

                Spacer()

                // Se permissão negada, mostra card explicativo acima dos controles
                if vm.authorizationStatus == .denied || vm.authorizationStatus == .restricted {
                    VStack(spacing: 12) {
                        Text("ui.location_permission_denied_enable_it_in_settings_to_see_your_gym_s_position")
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button(action: openSettings) {
                            Text("ui.open_settings")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding(.bottom, 140)
                }

                // Controles inferiores (Centrar, Toggle, Editar, Remover)
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Button(action: {
                            vm.centerOnUser()
                            // ✅ garante que o map acompanhe o vm.region após centralizar
                            cameraPosition = .region(vm.region)
                        }) {
                            Label(LocalizedStringKey("ui.center"), systemImage: "location.fill")
                        }
                        .buttonStyle(.bordered)

                        Toggle(isOn: $showSavedToggle) {
                            Text("ui.save_last_location")
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

                    HStack(spacing: 12) {
                        Button(action: { showEditLocationSheet = true }) {
                            Label(LocalizedStringKey("ui.edit_location_2"), systemImage: "pencil")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button(action: {
                            profileStore.setLastSeenCoordinate(nil, userId: session.currentUid)
                            setupAnnotations()
                        }) {
                            Text("ui.remove_location")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .padding()
            }
        }
        .navigationTitle("ui.gym_map")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            setupAnnotations()
            cameraPosition = .region(vm.region)
        }
        .sheet(isPresented: $showEditLocationSheet) {
            EditLocationView(
                initialCoordinate: academyCoordinate ?? vm.lastLocation?.coordinate,
                locale: locale,
                onSave: { coord in
                    profileStore.setLastSeenCoordinate(coord, userId: session.currentUid)
                    setupAnnotations()
                }
            )
            .presentationDetents([.medium])
        }
    }

    // ✅ Quebra o Map em uma subview e remove pattern matching que estava gerando erro com 'let'
    private var mapView: some View {
        Map(position: $cameraPosition, interactionModes: .all) {
            UserAnnotation()

            ForEach(annotationItems) { item in
                Marker("", coordinate: item.coordinate)
                    .tint(.red)
            }
        }
        .onChange(of: regionSnapshot) { _, _ in
            // ✅ Mantém o mapa sincronizado quando o app altera vm.region (ex: setupAnnotations / centrar)
            cameraPosition = .region(vm.region)
        }
    }

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

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

// Small sheet view to edit latitude/longitude manually
private struct EditLocationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var latText: String
    @State private var lonText: String
    let locale: Locale
    var onSave: (CLLocationCoordinate2D) -> Void

    init(
        initialCoordinate: CLLocationCoordinate2D?,
        locale: Locale,
        onSave: @escaping (CLLocationCoordinate2D) -> Void
    ) {
        self.locale = locale
        self.onSave = onSave
        if let c = initialCoordinate {
            _latText = State(initialValue: String(format: "%.6f", locale: locale, c.latitude))
            _lonText = State(initialValue: String(format: "%.6f", locale: locale, c.longitude))
        } else {
            _latText = State(initialValue: "")
            _lonText = State(initialValue: "")
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("ui.gym_coordinates")) {
                    TextField("ui.latitude", text: $latText)
                        .keyboardType(.numbersAndPunctuation)
                    TextField("ui.longitude", text: $lonText)
                        .keyboardType(.numbersAndPunctuation)
                }

                Section {
                    Button("common.save") {
                        guard let lat = Double(latText.replacingOccurrences(of: ",", with: ".")),
                              let lon = Double(lonText.replacingOccurrences(of: ",", with: ".")) else {
                            return
                        }
                        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                        onSave(coord)
                        dismiss()
                    }
                    .disabled(latText.isEmpty || lonText.isEmpty)
                }
            }
            .navigationTitle("ui.edit_location")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.close") { dismiss() }
                }
            }
        }
    }
}

// Modelo de pin para o mapa
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

struct TeacherMapView_Previews: PreviewProvider {
    static var previews: some View {
        TeacherMapView()
            .environmentObject(AppSession())
    }
}
