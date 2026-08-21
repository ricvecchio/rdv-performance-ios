import Foundation
import MapKit
import CoreLocation
import Combine

// ViewModel que gerencia a localização do usuário e região do mapa
final class MapViewModel: NSObject, ObservableObject {
    // Região do mapa exibida na interface
    @Published var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -23.5505, longitude: -46.6333),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastLocation: CLLocation? = nil

    private let manager = CLLocationManager()

    // Configura o gerenciador de localização
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
    }

    // Solicita permissão de localização se ainda não foi concedida
    func requestPermissionIfNeeded() {
        let status = manager.authorizationStatus

        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else {
            self.authorizationStatus = status

            if let loc = manager.location {
                updateRegion(to: loc.coordinate)
                self.lastLocation = loc
            } else {
                manager.startUpdatingLocation()
            }
        }
    }

    // Atualiza a região do mapa para centralizar na coordenada fornecida
    private func updateRegion(to coordinate: CLLocationCoordinate2D) {
        DispatchQueue.main.async {
            self.region.center = coordinate
        }
    }

    // Centraliza o mapa na localização atual do usuário
    func centerOnUser() {
        if let loc = manager.location {
            updateRegion(to: loc.coordinate)
        } else if let last = lastLocation {
            updateRegion(to: last.coordinate)
        }
    }

    // Inicia as atualizações contínuas de localização
    func startUpdating() {
        manager.startUpdatingLocation()
    }

    // Para as atualizações de localização
    func stopUpdating() {
        manager.stopUpdatingLocation()
    }
}

// Implementa os métodos de delegate para gerenciar eventos de localização
extension MapViewModel: CLLocationManagerDelegate {
    // Chamado quando o status de autorização de localização muda
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.startUpdatingLocation()
                manager.requestLocation()
            } else {
                manager.stopUpdatingLocation()
            }
        }
    }

    // Chamado quando novas localizações estão disponíveis
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else { return }
        self.lastLocation = loc
        updateRegion(to: loc.coordinate)
    }

    // Chamado quando ocorre um erro ao obter a localização
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }
}
