import SwiftUI
import RealityKit
import ARKit
import AVFoundation
import CoreMotion
import UIKit

// Minimal AR container + demo view — sem logs/debug/diagnóstico
struct ARContainerView: UIViewRepresentable {
    typealias UIViewType = UIView
    var onArViewCreated: ((ARView) -> Void)?

    class Coordinator: NSObject, ARSessionDelegate {
        weak var statusLabel: UILabel?
        weak var arView: ARView?

        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            DispatchQueue.main.async {
                guard let label = self.statusLabel else { return }
                label.isHidden = (frame.camera.trackingState == .normal)
                switch frame.camera.trackingState {
                case .normal: break
                case .notAvailable:
                    label.isHidden = false
                    label.text = "Câmera ou sensores indisponíveis"
                case .limited(let reason):
                    label.isHidden = false
                    switch reason {
                    case .initializing: label.text = "Tracking: inicializando"
                    case .excessiveMotion: label.text = "Tracking: movimento excessivo"
                    case .insufficientFeatures: label.text = "Tracking: poucas feições visuais"
                    case .relocalizing: label.text = "Tracking: relocalizando"
                    @unknown default: label.text = "Tracking: desconhecido"
                    }
                }
            }
        }

        func session(_ session: ARSession, didFailWithError error: Error) {
            DispatchQueue.main.async {
                self.statusLabel?.isHidden = false
                self.statusLabel?.text = "Falha na sessão AR"
            }
        }

        func sessionWasInterrupted(_ session: ARSession) {
            DispatchQueue.main.async {
                self.statusLabel?.isHidden = false
                self.statusLabel?.text = "Sessão AR interrompida"
            }
        }

        func sessionInterruptionEnded(_ session: ARSession) {
            DispatchQueue.main.async {
                self.statusLabel?.isHidden = false
                self.statusLabel?.text = "Sessão AR reiniciada"
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIView {
        let container = UIView(frame: .zero)
        container.backgroundColor = .black

        let arView = ARView(frame: .zero)
        arView.translatesAutoresizingMaskIntoConstraints = false
        arView.automaticallyConfigureSession = false

        container.addSubview(arView)
        NSLayoutConstraint.activate([
            arView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            arView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            arView.topAnchor.constraint(equalTo: container.topAnchor),
            arView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        let statusLabel = UILabel()
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text = "Aguardando câmera..."
        statusLabel.textColor = .white
        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center
        statusLabel.backgroundColor = UIColor(white: 0, alpha: 0.55)
        statusLabel.layer.cornerRadius = 8
        statusLabel.layer.masksToBounds = true
        container.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            statusLabel.widthAnchor.constraint(lessThanOrEqualTo: container.widthAnchor, multiplier: 0.9)
        ])

        let coordinator = context.coordinator
        coordinator.statusLabel = statusLabel
        coordinator.arView = arView
        arView.session.delegate = coordinator

        DispatchQueue.main.async { self.onArViewCreated?(arView) }

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    static func startSession(on arView: ARView, minimal: Bool = false) {
        guard ARWorldTrackingConfiguration.isSupported else { return }
        let motion = CMMotionManager()
        guard motion.isDeviceMotionAvailable else { return }

        let config = ARWorldTrackingConfiguration()
        if minimal {
            config.planeDetection = []
            config.environmentTexturing = .none
        } else {
            config.planeDetection = [.horizontal]
            config.environmentTexturing = .automatic
        }
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }
}

struct ARDemoView: View {
    @State private var arViewRef: ARView? = nil

    var body: some View {
        ZStack {
            ARContainerView(onArViewCreated: { ar in
                self.arViewRef = ar
                ARContainerView.startSession(on: ar)
            })
            .edgesIgnoringSafeArea(.all)
        }
        .navigationTitle("AR Demo")
        .onDisappear { if let ar = arViewRef { ar.session.pause() } }
        .onAppear {
            // Minimal camera permission handling: request if not determined
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            if status == .notDetermined {
                AVCaptureDevice.requestAccess(for: .video) { _ in }
            }
        }
    }
}
