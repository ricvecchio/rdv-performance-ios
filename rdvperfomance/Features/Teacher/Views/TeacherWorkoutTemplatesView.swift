import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UIKit

extension Notification.Name {
    static let workoutTemplateUpdated = Notification.Name("workoutTemplateUpdated")
}

struct TeacherWorkoutTemplatesView: View {

    @Binding var path: [AppRoute]
    let category: TreinoTipo
    let sectionKey: String
    let sectionTitle: String

    @State private var templates: [WorkoutTemplateFS] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var isSeedingDefaults: Bool = false

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
        .toolbar {

            ToolbarItem(placement: .navigationBarLeading) {
                Button { pop() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text(sectionTitle)
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
                    .lineLimit(1)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await loadTemplates() }
        .onAppear { Task { await loadTemplates() } }
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
        if isLoading { return }
        errorMessage = nil

        let teacherId = (Auth.auth().currentUser?.uid ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !teacherId.isEmpty else {
            errorMessage = "Não foi possível identificar o professor logado."
            templates = []
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            templates = try await FirestoreRepository.shared.getWorkoutTemplates(
                teacherId: teacherId,
                categoryRaw: category.rawValue,
                sectionKey: sectionKey
            )

            // ✅ Seed controlado para seções com defaults (exceto "Meus Treinos")
            if (category == .crossfit || category == .academia || category == .emCasa) && sectionKey != "meusTreinos" && !isSeedingDefaults {
                isSeedingDefaults = true
                defer { isSeedingDefaults = false }

                do {
                    let didInsert = try await WorkoutTemplateDefaultsSeeder.shared.seedMissingDefaultsIfNeeded(
                        teacherId: teacherId,
                        category: category,
                        sectionKey: sectionKey,
                        sectionTitle: sectionTitle,
                        existingTemplates: templates
                    )

                    if didInsert {
                        templates = try await FirestoreRepository.shared.getWorkoutTemplates(
                            teacherId: teacherId,
                            categoryRaw: category.rawValue,
                            sectionKey: sectionKey
                        )
                    }

                } catch {
                    errorMessage = "Falha ao inserir treinos padrão: \(error.localizedDescription)"
                }
            }

        } catch {
            errorMessage = error.localizedDescription
            templates = []
        }
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

