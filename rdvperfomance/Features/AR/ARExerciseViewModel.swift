// ViewModel para gerenciar estado e lógica da tela AR de exercícios
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

    // Inicializa o ViewModel com identificadores de semana e dia
    init(weekId: String, dayId: String, storage: ARLocalStorage = .shared) {
        self.weekId = weekId
        self.dayId = dayId
        self.storage = storage
    }

    // Carrega pontos de correção salvos localmente
    func loadLocalCorrectionPoints() async {
        do {
            let pts = try storage.loadCorrectionPoints(weekId: weekId, dayId: dayId)
            correctionPoints = pts
        } catch {
            errorMessage = "Falha ao carregar pontos de correção"
        }
    }

    // Salva pontos de correção no armazenamento local
    func saveCorrectionPoints() async {
        do {
            try storage.saveCorrectionPoints(correctionPoints, weekId: weekId, dayId: dayId)
        } catch {
            errorMessage = "Falha ao salvar pontos de correção"
        }
    }

    // Adiciona um novo ponto de correção à lista
    func addCorrectionPoint(at worldPosition: SIMD3<Float>, title: String? = nil, note: String? = nil, createdBy: String? = nil) {
        let p = ARCorrectionPoint(title: title, note: note, position: ARVector3Codable(from: worldPosition), createdBy: createdBy)
        correctionPoints.append(p)
    }

    // Remove um ponto de correção pelo ID
    func removeCorrectionPoint(id: String) {
        correctionPoints.removeAll { $0.id == id }
    }

    // Atualiza um ponto de correção existente
    func updateCorrectionPoint(_ p: ARCorrectionPoint) {
        if let idx = correctionPoints.firstIndex(where: { $0.id == p.id }) {
            correctionPoints[idx] = p
        }
    }

    // Verifica se existe modelo 3D no bundle e armazena o nome
    func loadModelIfExists(named name: String) async {
        if Bundle.main.url(forResource: name, withExtension: "usdz") != nil {
            modelName = name
        } else {
            modelName = nil
        }
    }

    // Retorna uma esfera verde como modelo placeholder
    func placeholderModelEntity() -> ModelEntity {
        let mesh = MeshResource.generateSphere(radius: 0.15)
        let mat = SimpleMaterial(color: .green, isMetallic: false)
        let e = ModelEntity(mesh: mesh, materials: [mat])
        return e
    }
}
