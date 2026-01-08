// Tela AR para visualizar exercícios com pontos de correção interativos
import SwiftUI
import RealityKit
import ARKit
import Combine

struct ARExerciseView: View {
    @Binding var path: [AppRoute]
    @StateObject private var vm: ARExerciseViewModel
    @State private var arViewRef: ARView? = nil
    @State private var placingPoint: Bool = false
    @State private var showAddPointSheet: Bool = false
    @State private var newPointTitle: String = ""
    @State private var newPointNote: String = ""

    @State private var modelLoadTask: Task<Void, Never>? = nil
    @State private var observerTask: Task<Void, Never>? = nil
    @State private var isModelLoading: Bool = false

    // Inicializa a view com identificadores de semana e dia do treino
    init(path: Binding<[AppRoute]>, weekId: String, dayId: String) {
        self._path = path
        self._vm = StateObject(wrappedValue: ARExerciseViewModel(weekId: weekId, dayId: dayId))
    }

    // Interface principal da tela AR com controles e overlay de loading
    var body: some View {
        ZStack {
            ARContainerView(onArViewCreated: { ar in
                self.arViewRef = ar
                ARContainerView.startSession(on: ar)

                modelLoadTask?.cancel()
                modelLoadTask = Task {
                    await vm.loadLocalCorrectionPoints()
                    await vm.loadModelIfExists(named: "exercise_\(vm.weekId)_\(vm.dayId)")
                    await MainActor.run {
                        if let ar = arViewRef {
                            addModelToSceneIfNeeded(ar: ar)
                            renderCorrectionPoints(on: ar)
                        }
                    }
                }

                observerTask?.cancel()
                observerTask = Task {
                    for await _ in vm.$correctionPoints.values {
                        await MainActor.run {
                            if let ar = arViewRef { renderCorrectionPoints(on: ar) }
                        }
                    }
                }
            }, onTap: { pt in
                guard placingPoint, let ar = arViewRef else { return }
                if let result = ar.raycast(from: pt, allowing: .estimatedPlane, alignment: .any).first {
                    let world = result.worldTransform
                    let pos = SIMD3<Float>(world.columns.3.x, world.columns.3.y, world.columns.3.z)
                    newPointTitle = ""
                    newPointNote = ""
                    placingPoint = false
                    let tmp = ARCorrectionPoint(position: ARVector3Codable(from: pos))
                    vm.correctionPoints.append(tmp)
                    Task { @MainActor in
                        addCorrectionEntity(for: tmp, on: ar)
                    }
                    Task { await MainActor.run { showAddPointSheet = true } }
                }
            })
            .edgesIgnoringSafeArea(.all)

            VStack {
                HStack {
                    Button(action: { pop() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.35))
                            .cornerRadius(8)
                    }
                    Spacer()
                    Button(action: { placingPoint.toggle() }) {
                        Text(placingPoint ? "Cancelar" : "Adicionar ponto")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.35))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 40)

                Spacer()

                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        Button(action: { Task { await vm.saveCorrectionPoints() } }) {
                            Text("Salvar pontos")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.green.opacity(0.18))
                                .cornerRadius(10)
                        }

                        Button(action: {
                            // marca execução rápida — para futuro integrar com Student progress
                        }) {
                            Text("Marcar execução")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.green.opacity(0.18))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.trailing, 12)
                }
            }

            // Overlay simples de loading quando o modelo está sendo carregado
            if isModelLoading {
                Color.black.opacity(0.4).ignoresSafeArea()
                VStack {
                    ProgressView("Carregando modelo...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                }
            }
        }
        .sheet(isPresented: $showAddPointSheet) {
            ZStack {
                Color.black.opacity(0.95).ignoresSafeArea()
                VStack(alignment: .leading, spacing: 12) {
                    Text("Novo Ponto de Correção")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    UnderlineTextField(title: "Título (curto)", text: $newPointTitle, isSecure: false, showPassword: .constant(false), lineColor: Theme.Colors.divider, textColor: .white, placeholderColor: .white.opacity(0.55))

                    UnderlineTextField(title: "Observação (opcional)", text: $newPointNote, isSecure: false, showPassword: .constant(false), lineColor: Theme.Colors.divider, textColor: .white, placeholderColor: .white.opacity(0.55))

                    HStack {
                        Button("Cancelar") { showAddPointSheet = false }
                        Spacer()
                        Button("Salvar") {
                            // Atualiza o último ponto temporário com título/nota
                            if let lastIdx = vm.correctionPoints.indices.last {
                                var p = vm.correctionPoints[lastIdx]
                                p.title = newPointTitle
                                p.note = newPointNote
                                vm.correctionPoints[lastIdx] = p
                                Task { await vm.saveCorrectionPoints() }
                            }
                            showAddPointSheet = false
                        }
                    }
                    Spacer()
                }
                .padding(18)
            }
            .presentationDetents([.medium])
        }
        .onDisappear {
            // Pause session e cancelar tarefas pendentes
            if let ar = arViewRef { ar.session.pause() }
            modelLoadTask?.cancel()
            observerTask?.cancel()
        }
        .onAppear {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            if status == .notDetermined { AVCaptureDevice.requestAccess(for: .video) { _ in } }
        }
        .navigationTitle("AR")
    }

    // Remove a última rota da pilha de navegação
    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    // Adiciona modelo 3D à cena AR ou placeholder caso falhe
    private func addModelToSceneIfNeeded(ar: ARView) {
        Task { @MainActor in
            let toRemove = ar.scene.anchors.filter { ($0.name ?? "") == "arModel" }
            for anchor in toRemove { ar.scene.removeAnchor(anchor) }
        }

        if let name = vm.modelName {
            Task {
                await MainActor.run { isModelLoading = true }
                defer { Task { await MainActor.run { isModelLoading = false } } }

                do {
                    try Task.checkCancellation()
                    let entity = try await ModelEntity.load(named: name)
                    try Task.checkCancellation()
                    await MainActor.run {
                        guard let ar = arViewRef else { return }
                        let anchor = AnchorEntity(plane: .any)
                        anchor.name = "arModel"
                        entity.transform.translation = [0, 0, -0.5]
                        anchor.addChild(entity)
                        ar.scene.addAnchor(anchor)
                    }
                } catch is CancellationError {
                } catch {
                    let placeholder = vm.placeholderModelEntity()
                    await MainActor.run {
                        guard let ar = arViewRef else { return }
                        let anchor = AnchorEntity(plane: .any)
                        anchor.name = "arModel"
                        placeholder.transform.translation = [0, 0, -0.5]
                        anchor.addChild(placeholder)
                        ar.scene.addAnchor(anchor)
                    }
                }
            }
        } else {
            let placeholder = vm.placeholderModelEntity()
            Task { @MainActor in
                let anchor = AnchorEntity(plane: .any)
                anchor.name = "arModel"
                placeholder.transform.translation = [0, 0, -0.5]
                anchor.addChild(placeholder)
                ar.scene.addAnchor(anchor)
            }
        }
    }

    // Renderiza todos os pontos de correção como esferas vermelhas na cena AR
    private func renderCorrectionPoints(on ar: ARView) {
        Task { @MainActor in
            let toRemove = ar.scene.anchors.filter { ($0.name ?? "").hasPrefix("arPoint-") }
            for anchor in toRemove { ar.scene.removeAnchor(anchor) }

            for p in vm.correctionPoints {
                let sphere = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.03), materials: [SimpleMaterial(color: .red, isMetallic: false)])
                sphere.name = "point-\(p.id)"
                let anchor = AnchorEntity(world: p.position.simd)
                anchor.name = "arPoint-\(p.id)"
                anchor.addChild(sphere)
                ar.scene.addAnchor(anchor)
            }
        }
    }

    // Adiciona uma esfera vermelha representando um ponto de correção na cena AR
    private func addCorrectionEntity(for point: ARCorrectionPoint, on ar: ARView) {
        Task { @MainActor in
            let sphere = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.03), materials: [SimpleMaterial(color: .red, isMetallic: false)])
            sphere.name = "point-\(point.id)"
            let anchor = AnchorEntity(world: point.position.simd)
            anchor.name = "arPoint-\(point.id)"
            anchor.addChild(sphere)
            ar.scene.addAnchor(anchor)
        }
    }
}
