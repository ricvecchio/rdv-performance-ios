import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UIKit
import os.log

extension Notification.Name {
    static let workoutTemplateUpdated = Notification.Name("workoutTemplateUpdated")
    static let workoutTemplateSelectedForAttachment = Notification.Name("workoutTemplateSelectedForAttachment")
}

struct TeacherWorkoutTemplatesView: View {

    @Binding var path: [AppRoute]
    let category: TreinoTipo
    let sectionKey: String
    let sectionTitle: String
    let mode: TeacherWorkoutTemplatesMode

    @Environment(\.locale) private var locale

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
        guard mode == .manage else { return false }

        // ✅ Crossfit sempre mostra
        if isCrossfitCategory { return true }

        // ✅ Academia e Em Casa também devem mostrar (independente da seção)
        if isAcademiaOrEmCasaCategory { return true }

        return false
    }

    private var addButtonTitle: String {
        isCrossfitCategory
            ? AppLocalization.string("ui.add_wod", locale: locale)
            : AppLocalization.string("ui.add_workout", locale: locale)
    }

    @State private var activeSheet: ActiveSheet? = nil

    enum ActiveSheet: Identifiable {
        case detail(WorkoutTemplateFS)

        var id: String {
            switch self {
            case .detail(let t):
                return "detail-\(t.id ?? UUID().uuidString)"
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
                                Text(
                                    String(
                                        format: AppLocalization.string("ui.category_section", locale: locale),
                                        locale: locale,
                                        arguments: [category.localizedDisplayName(locale: locale), sectionTitle]
                                    )
                                )
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.92))
                            }

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
                                category: category,
                                showsTemplateActions: mode == .manage,
                                onTapTemplate: { t in
                                    if mode == .attach {
                                        selectTemplateForAttachment(t)
                                    } else {
                                        activeSheet = .detail(t)
                                    }
                                },
                                onSendTemplate: { t in
                                    path.append(.teacherSendWorkout(preselectedTemplate: t))
                                },
                                onDeleteTemplate: { t in
                                    Task { await deleteTemplate(template: t) }
                                }
                            )

                            if let err = errorMessage {
                                TeacherWorkoutTemplatesMessageCard(text: err, isError: true, usesApprovedCardStyle: true)
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
            errorMessage = AppLocalization.string("ui.unable_to_identify_the_signed_in_trainer", locale: locale)
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
            let format = AppLocalization.string("ui.failed_to_add_default_workouts_value", locale: locale)
            errorMessage = String(
                format: format,
                locale: locale,
                arguments: [error.localizedDescription]
            )
        }

        #if DEBUG
        os_log("seedDefaultsIfNeeded durationMs=%.0f", log: Self.debugLog, type: .debug, Date().timeIntervalSince(seedStart) * 1000)
        #endif
    }

    private func deleteTemplate(template: WorkoutTemplateFS) async {
        errorMessage = nil

        guard let templateId = template.id?.trimmingCharacters(in: .whitespacesAndNewlines),
              !templateId.isEmpty else {
            errorMessage = AppLocalization.string("ui.unable_to_remove_invalid_workout_id", locale: locale)
            return
        }

        let teacherId = (Auth.auth().currentUser?.uid ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !teacherId.isEmpty else {
            errorMessage = AppLocalization.string("ui.unable_to_identify_the_signed_in_trainer", locale: locale)
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await FirestoreRepository.shared.deleteWorkoutTemplate(templateId: templateId)

            templates.removeAll { $0.id == templateId }
            NotificationCenter.default.post(name: .workoutTemplateUpdated, object: nil)

        } catch {
            let format = AppLocalization.string("ui.failed_to_remove_the_workout_value", locale: locale)
            errorMessage = String(
                format: format,
                locale: locale,
                arguments: [error.localizedDescription]
            )
        }
    }

    private func selectTemplateForAttachment(_ template: WorkoutTemplateFS) {
        NotificationCenter.default.post(name: .workoutTemplateSelectedForAttachment, object: template)
        guard path.count >= 2 else { return }
        path.removeLast(2)
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
