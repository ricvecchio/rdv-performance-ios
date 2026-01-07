import Foundation
import RealityKit
import ARKit
import Combine

@MainActor
final class ARExerciseViewModel: ObservableObject {
    let weekId: String
    let dayId: String

    @Published var modelName: String? = nil
    @Published var isSessionRunning: Bool = false
    @Published var correctionPoints: [ARCorrectionPoint] = []
    @Published var errorMessage: String? = nil

    private var storage: ARLocalStorage

    init(weekId: String, dayId: String, storage: ARLocalStorage = .shared) {
        self.weekId = weekId
        self.dayId = dayId
        self.storage = storage
    }

    func loadLocalCorrectionPoints() async {
        do {
            let pts = try storage.loadCorrectionPoints(weekId: weekId, dayId: dayId)
            correctionPoints = pts
        } catch {
            errorMessage = "Falha ao carregar pontos de correção"
        }
    }

    func saveCorrectionPoints() async {
        do {
            try storage.saveCorrectionPoints(correctionPoints, weekId: weekId, dayId: dayId)
        } catch {
            errorMessage = "Falha ao salvar pontos de correção"
        }
    }

    func addCorrectionPoint(at worldPosition: SIMD3<Float>, title: String? = nil, note: String? = nil, createdBy: String? = nil) {
        let p = ARCorrectionPoint(title: title, note: note, position: ARVector3Codable(from: worldPosition), createdBy: createdBy)
        correctionPoints.append(p)
    }

    func removeCorrectionPoint(id: String) {
        correctionPoints.removeAll { $0.id == id }
    }

    func updateCorrectionPoint(_ p: ARCorrectionPoint) {
        if let idx = correctionPoints.firstIndex(where: { $0.id == p.id }) {
            correctionPoints[idx] = p
        }
    }

    func loadModelIfExists(named name: String) async {
        // Tentativa simples: verificar se arquivo existe no bundle
        if Bundle.main.url(forResource: name, withExtension: "usdz") != nil {
            modelName = name
        } else {
            modelName = nil
        }
    }

    func placeholderModelEntity() -> ModelEntity {
        let mesh = MeshResource.generateSphere(radius: 0.15)
        let mat = SimpleMaterial(color: .green, isMetallic: false)
        let e = ModelEntity(mesh: mesh, materials: [mat])
        return e
    }
}
