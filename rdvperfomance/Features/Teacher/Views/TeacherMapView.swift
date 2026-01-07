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

    private var displayCoordinateText: String {
        if let coord = academyCoordinate {
            return String(format: "Academia: %.5f, %.5f", coord.latitude, coord.longitude)
        } else if let last = vm.lastLocation {
            return String(format: "Última: %.5f, %.5f", last.coordinate.latitude, last.coordinate.longitude)
        } else {
            return "Localização: —"
        }
    }

    @State private var annotationItems: [MapPin] = []
    @State private var showEditLocationSheet: Bool = false

    var body: some View {
        ZStack {
            // Map em background ocupando toda a tela
            Map(coordinateRegion: $vm.region, showsUserLocation: true, annotationItems: annotationItems) { item in
                MapMarker(coordinate: item.coordinate, tint: .red)
            }
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
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding(.bottom, 140)
                }

                // Controles inferiores (Centrar, Toggle, Editar, Remover)
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
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
