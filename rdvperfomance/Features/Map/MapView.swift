import SwiftUI
import MapKit

struct MapFeatureView: View {
    @StateObject private var vm = MapViewModel()

    var body: some View {
        VStack {
            if vm.authorizationStatus == .denied || vm.authorizationStatus == .restricted {
                Text("Permissão de localização negada. Habilite em Ajustes.")
                    .multilineTextAlignment(.center)
                    .padding()
            }

            Map(coordinateRegion: $vm.region, showsUserLocation: true)
                .onAppear { vm.requestPermissionIfNeeded() }
                .edgesIgnoringSafeArea(.all)
        }
        .navigationTitle("Mapa")
    }
}

struct MapFeatureView_Previews: PreviewProvider {
    static var previews: some View {
        MapFeatureView()
    }
}
