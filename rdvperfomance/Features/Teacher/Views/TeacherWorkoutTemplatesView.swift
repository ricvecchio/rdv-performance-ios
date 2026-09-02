import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UIKit
import os.log

extension Notification.Name {
    static let workoutTemplateUpdated = Notification.Name("workoutTemplateUpdated")
}

struct TeacherWorkoutTemplatesView: View {

    @Binding var path: [AppRoute]
    let category: TreinoTipo
    let sectionKey: String
    let sectionTitle: String

    @State private var templates: [WorkoutTemplateFS] = []
    @State private var isLoading: Bool = true
    @State private var hasLoadedInitialData: Bool = false
    @State private var errorMessage: String? = nil
    @State private var isSeedingDefaults: Bool = false
    @State private var isFetchingTemplates: Bool = false

    private static let debugLog = OSLog(subsystem: "com.rdvperformance.app", category: "TeacherWorkoutTemplatesView")
    #if DEBUG
    @State private var loadCallCount: Int = 0
    #endif

    private let contentMaxWidth: CGFloat = 380

    private var isCrossfitCategory: Bool {
        category == .crossfit
    }

    private var isAcademiaOrEmCasaCategory: Bool {
        category == .academia || category == .emCasa
    }

    private var shouldShowAddButton: Bool {
        // ✅ Crossfit sempre mostra
        if isCrossfitCategory { return true }

        // ✅ Academia e Em Casa também devem mostrar (independente da seção)
        if isAcademiaOrEmCasaCategory { return true }

        return false
    }

    private var addButtonTitle: String {
        isCrossfitCategory ? "Adicionar WOD" : "Adicionar Treino"
    }

    private var descriptionText: String {
        if isAcademiaOrEmCasaCategory {
            return "Cadastre e gerencie os treinos desta seção."
        }
        return "Cadastre e gerencie os WODs desta seção."
    }

    @State private var activeSheet: ActiveSheet? = nil

    enum ActiveSheet: Identifiable {
        case detail(WorkoutTemplateFS)
        case send(WorkoutTemplateFS)

        var id: String {
            switch self {
            case .detail(let t):
                return "detail-\(t.id ?? UUID().uuidString)"
            case .send(let t):
                return "send-\(t.id ?? UUID().uuidString)"
            }
        }
    }

    var body: some View {
        ZStack {

            Image("rdv_fundo")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {

                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)

                ScrollView(showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 0)

                        VStack(alignment: .leading, spacing: 14) {

                            if isCrossfitCategory {
                                EmptyView()
                            } else if isAcademiaOrEmCasaCategory {
                                EmptyView()
                            } else {
                                Text("\(category.displayName) • \(sectionTitle)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.92))
                            }

                            Text(descriptionText)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.35))

                            if shouldShowAddButton {
                                TeacherWorkoutTemplatesAddButton(
                                    title: addButtonTitle,
                                    action: { handleAddButtonTap() }
                                )
                            }

                            TeacherWorkoutTemplatesContentCard(
                                isLoading: isLoading,
                                hasLoadedInitialData: hasLoadedInitialData,
                                templates: templates,
                                isCrossfitCategory: isCrossfitCategory,
                                onTapTemplate: { t in
                                    activeSheet = .detail(t)
                                },
                                onSendTemplate: { t in
                                    activeSheet = .send(t)
                                },
                                onDeleteTemplate: { t in
                                    Task { await deleteTemplate(template: t) }
                                }
                            )

                            if let err = errorMessage {
                                TeacherWorkoutTemplatesMessageCard(text: err, isError: true)
                            }

                            Color.clear.frame(height: Theme.Layout.footerHeight + 20)
                        }
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        Spacer(minLength: 0)
                    }
                }

                FooterBar(
                    path: $path,
                    kind: .teacherHomeAlunosSobrePerfil(
                        selectedCategory: category,
                        isHomeSelected: false,
                        isAlunosSelected: false,
                        isSobreSelected: false,
                        isPerfilSelected: false
                    )
                )
                .frame(height: Theme.Layout.footerHeight)
                .background(Theme.Colors.footerBackground)
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {

            ToolbarItem(placement: .topBarLeading) {
                Button { pop() } label: {
                    ZStack {
                        Color.clear
                            .frame(width: 44, height: 44)

                        Image(systemName: "chevron.left")
                            .foregroundColor(.green)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text(sectionTitle)
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
                    .lineLimit(1)
            }

            ToolbarItem(placement: .topBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await loadTemplates() }
        .onReceive(NotificationCenter.default.publisher(for: .workoutTemplateUpdated)) { _ in
            Task { await loadTemplates() }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .detail(let t):
                TeacherWorkoutTemplateDetailSheet(template: t)

            case .send(let t):
                TeacherSendWorkoutToStudentSheet(
                    template: t,
                    category: category
                )
            }
        }
    }

    private func handleAddButtonTap() {
        if isCrossfitCategory {
            path.append(.createCrossfitWOD(category: category, sectionKey: sectionKey, sectionTitle: sectionTitle))
        } else if category == .academia {
            path.append(.createTreinoAcademia(category: category, sectionKey: sectionKey, sectionTitle: sectionTitle))
        } else if category == .emCasa {
            path.append(.createTreinoCasa(category: category, sectionKey: sectionKey, sectionTitle: sectionTitle))
        } else {
            path.append(.createCrossfitWOD(category: category, sectionKey: sectionKey, sectionTitle: sectionTitle))
        }
    }

    private func loadTemplates() async {
        guard !isFetchingTemplates else { return }
        isFetchingTemplates = true
        defer { isFetchingTemplates = false }
        errorMessage = nil

        #if DEBUG
        loadCallCount += 1
        let callId = loadCallCount
        let debugStart = Date()
        os_log("loadTemplates() call #%d START category=%{public}@ section=%{public}@", log: Self.debugLog, type: .debug, callId, category.rawValue, sectionKey)
        #endif

        let teacherId = (Auth.auth().currentUser?.uid ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !teacherId.isEmpty else {
            errorMessage = "Não foi possível identificar o professor logado."
            templates = []
            isLoading = false
            hasLoadedInitialData = true
            return
        }

        isLoading = true

        do {
            let fetched = try await FirestoreRepository.shared.getWorkoutTemplates(
                teacherId: teacherId,
                categoryRaw: category.rawValue,
                sectionKey: sectionKey
            )
            templates = fetched

            #if DEBUG
            os_log("loadTemplates() call #%d fetched %d docs in %.0fms", log: Self.debugLog, type: .debug, callId, fetched.count, Date().timeIntervalSince(debugStart) * 1000)
            #endif

            if fetched.isEmpty {
                await seedDefaultsIfNeeded(teacherId: teacherId)
                hasLoadedInitialData = true
                isLoading = false
                return
            }

            // Exibe os templates encontrados enquanto o seed verifica defaults ausentes.
            isLoading = false
            hasLoadedInitialData = true
            await seedDefaultsIfNeeded(teacherId: teacherId)

        } catch {
            errorMessage = error.localizedDescription
            templates = []
            isLoading = false
            hasLoadedInitialData = true
        }

        #if DEBUG
        os_log("loadTemplates() call #%d END totalDurationMs=%.0f", log: Self.debugLog, type: .debug, callId, Date().timeIntervalSince(debugStart) * 1000)
        #endif
    }

    /// Semeia os treinos padrão (Hero/Tribute, Girls, Open etc.) quando ainda não existirem,
    /// sem bloquear a exibição da lista já carregada. Idempotente: só roda de fato uma vez
    /// por professor/seção (ver `WorkoutTemplateDefaultsSeeder`).
    private func seedDefaultsIfNeeded(teacherId: String) async {
        guard (category == .crossfit || category == .academia || category == .emCasa),
              sectionKey != "meusTreinos",
              !isSeedingDefaults else { return }

        isSeedingDefaults = true
        defer { isSeedingDefaults = false }

        #if DEBUG
        let seedStart = Date()
        #endif

        do {
            let didInsert = try await WorkoutTemplateDefaultsSeeder.shared.seedMissingDefaultsIfNeeded(
                teacherId: teacherId,
                category: category,
                sectionKey: sectionKey,
                sectionTitle: sectionTitle,
                existingTemplates: templates
            )

            if didInsert {
                // Atualização silenciosa (sem reexibir o spinner cheio) assim que os
                // defaults forem inseridos.
                templates = try await FirestoreRepository.shared.getWorkoutTemplates(
                    teacherId: teacherId,
                    categoryRaw: category.rawValue,
                    sectionKey: sectionKey
                )
            }

        } catch {
            errorMessage = "Falha ao inserir treinos padrão: \(error.localizedDescription)"
        }

        #if DEBUG
        os_log("seedDefaultsIfNeeded durationMs=%.0f", log: Self.debugLog, type: .debug, Date().timeIntervalSince(seedStart) * 1000)
        #endif
    }

    private func deleteTemplate(template: WorkoutTemplateFS) async {
        errorMessage = nil

        guard let templateId = template.id?.trimmingCharacters(in: .whitespacesAndNewlines),
              !templateId.isEmpty else {
            errorMessage = "Não foi possível remover: id do treino inválido."
            return
        }

        let teacherId = (Auth.auth().currentUser?.uid ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !teacherId.isEmpty else {
            errorMessage = "Não foi possível identificar o professor logado."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await FirestoreRepository.shared.deleteWorkoutTemplate(templateId: templateId)

            templates.removeAll { $0.id == templateId }
            NotificationCenter.default.post(name: .workoutTemplateUpdated, object: nil)

        } catch {
            errorMessage = "Falha ao remover o treino: \(error.localizedDescription)"
        }
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
