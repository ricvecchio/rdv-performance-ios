import SwiftUI
import MapKit

struct TeacherMapView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var vm = MapViewModel()
    @State private var showSavedToggle: Bool = true
    private let profileStore = LocalProfileStore.shared

    private var academyCoordinate: CLLocationCoordinate2D? {
        profileStore.getLastSeenCoordinate(userId: session.currentUid)
    }

    @State private var annotationItems: [MapPin] = []
    @State private var showEditLocationSheet: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            if vm.authorizationStatus == .denied || vm.authorizationStatus == .restricted {
                VStack(spacing: 12) {
                    Text("Permissão de localização negada. Habilite em Ajustes para ver a posição da sua academia.")
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

                VStack(spacing: 8) {
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

                    HStack(spacing: 12) {
                        Button(action: { showEditLocationSheet = true }) {
                            Label("Editar localização", systemImage: "pencil")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button(action: { profileStore.setLastSeenCoordinate(nil, userId: session.currentUid); setupAnnotations() }) {
                            Text("Remover localização")
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
        .navigationTitle("Mapa da Academia")
        .onAppear { setupAnnotations() }
        .sheet(isPresented: $showEditLocationSheet) {
            EditLocationView(
                initialCoordinate: academyCoordinate ?? vm.lastLocation?.coordinate,
                onSave: { coord in
                    profileStore.setLastSeenCoordinate(coord, userId: session.currentUid)
                    setupAnnotations()
                }
            )
            .presentationDetents([.medium])
        }
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

// Small sheet view to edit latitude/longitude manually
private struct EditLocationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var latText: String
    @State private var lonText: String
    var onSave: (CLLocationCoordinate2D) -> Void

    init(initialCoordinate: CLLocationCoordinate2D?, onSave: @escaping (CLLocationCoordinate2D) -> Void) {
        self.onSave = onSave
        if let c = initialCoordinate {
            _latText = State(initialValue: String(format: "%.6f", c.latitude))
            _lonText = State(initialValue: String(format: "%.6f", c.longitude))
        } else {
            _latText = State(initialValue: "")
            _lonText = State(initialValue: "")
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Coordenadas da Academia")) {
                    TextField("Latitude", text: $latText)
                        .keyboardType(.numbersAndPunctuation)
                    TextField("Longitude", text: $lonText)
                        .keyboardType(.numbersAndPunctuation)
                }

                Section {
                    Button("Salvar") {
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
            .navigationTitle("Editar Localização")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
    }
}

private struct MapPin: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
}

struct TeacherMapView_Previews: PreviewProvider {
    static var previews: some View {
        TeacherMapView()
            .environmentObject(AppSession())
    }
}
