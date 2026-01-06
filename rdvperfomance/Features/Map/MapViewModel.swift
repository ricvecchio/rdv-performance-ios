import Foundation
import MapKit
import CoreLocation
import Combine

final class MapViewModel: NSObject, ObservableObject {
    @Published var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -23.5505, longitude: -46.6333),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestPermissionIfNeeded() {
        if CLLocationManager.authorizationStatus() == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else {
            self.authorizationStatus = CLLocationManager.authorizationStatus()
            if let loc = manager.location {
                updateRegion(to: loc.coordinate)
            }
        }
    }

    private func updateRegion(to coordinate: CLLocationCoordinate2D) {
        DispatchQueue.main.async {
            self.region.center = coordinate
        }
    }
}

extension MapViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else { return }
        updateRegion(to: loc.coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // apenas logar; o app continua com região padrão
        print("Location manager failed: \(error)")
    }
}
