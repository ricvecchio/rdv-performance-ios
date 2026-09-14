import SwiftUI
import FirebaseFirestore
import UIKit

struct TeacherWorkoutTemplateDetailSheet: View {

    let template: WorkoutTemplateFS
    @Environment(\.dismiss) private var dismiss

    private let contentMaxWidth: CGFloat = 380

    @State private var isEditing: Bool = false
    @State private var draftBlocks: [BlockFS] = []

    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil

    private let warmupTitle = "Aquecimento"
    private let techniqueTitle = "Técnica"
    private let loadsTitle = "Cargas / Movimentos"

    var body: some View {
        NavigationStack {
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

                                header

                                if isEditing {
                                    editableBlocksCard
                                } else {
                                    readOnlyBlocks
                                }

                                if let err = errorMessage {
                                    TeacherWorkoutTemplatesMessageCard(text: err, isError: true)
                                }

                                if let ok = successMessage {
                                    TeacherWorkoutTemplatesMessageCard(text: ok, isError: false)
                                }

                                Color.clear.frame(height: 18)
                            }
                            .frame(maxWidth: contentMaxWidth)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)

                            Spacer(minLength: 0)
                        }
                    }
                }
                .ignoresSafeArea(.container, edges: [.bottom])
            }
            .navigationTitle("Treino")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .topBarLeading) {
                    Button("Fechar") { dismiss() }
                        .disabled(isSaving)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if isEditing {
                        HStack(spacing: 12) {
                            Button("Cancelar") {
                                errorMessage = nil
                                successMessage = nil
                                isEditing = false
                                resetDraftFromTemplate()
                            }
                            .disabled(isSaving)

                            Button {
                                Task { await saveBlocks() }
                            } label: {
                                if isSaving {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Salvar")
                                }
                            }
                            .disabled(isSaving)
                        }
                    } else {
                        Button("Editar") {
                            errorMessage = nil
                            successMessage = nil
                            isEditing = true
                            ensureEditableBlocksExist()
                        }
                    }
                }
            }
            .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .background(NavigationBarNoHairline())
            .onAppear {
                resetDraftFromTemplate()
                ensureEditableBlocksExist()
            }
            // ✅ Ajuste solicitado anteriormente: contorno do modal mais aparente (principalmente no cabeçalho)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.20), lineWidth: 1.25)
                    .allowsHitTesting(false)
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(template.title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))

            let desc = template.description.trimmingCharacters(in: .whitespacesAndNewlines)
            if !desc.isEmpty {
                Text(desc)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.70))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var readOnlyBlocks: some View {
        Group {
            if let blocks = template.blocks, !blocks.isEmpty {
                VStack(spacing: 12) {
                    ForEach(blocks.indices, id: \.self) { i in
                        let b = blocks[i]
                        VStack(alignment: .leading, spacing: 8) {
                            Text(b.name.isEmpty ? "Bloco" : b.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))

                            Text(b.details)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.70))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.Colors.cardBackground)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sem blocos cadastrados")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))

                    Text("Este WOD ainda não possui Aquecimento/Técnica/WOD/Blocos.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.55))
                }
                .padding(.vertical, 16)
            }
        }
    }

    private var editableBlocksCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            blockEditor(title: warmupTitle, text: bindingForBlockDetails(title: warmupTitle))

            Divider().background(Theme.Colors.divider)

            blockEditor(title: techniqueTitle, text: bindingForBlockDetails(title: techniqueTitle))

            Divider().background(Theme.Colors.divider)

            blockEditor(title: loadsTitle, text: bindingForBlockDetails(title: loadsTitle))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func blockEditor(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))

            TextEditor(text: text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.92))
                .frame(minHeight: 110)
                .scrollContentBackground(.hidden)
                .background(Color.white.opacity(0.06))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func resetDraftFromTemplate() {
        draftBlocks = template.blocks ?? []
    }

    private func normalize(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
    }

    private func isSameBlockName(_ a: String, _ b: String) -> Bool {
        normalize(a) == normalize(b)
    }

    private func ensureEditableBlocksExist() {
        ensureBlockExists(named: warmupTitle)
        ensureBlockExists(named: techniqueTitle)
        ensureBlockExists(named: loadsTitle)
    }

    private func ensureBlockExists(named name: String) {
        if draftBlocks.contains(where: { isSameBlockName($0.name, name) }) {
            return
        }

        let new = BlockFS(
            id: UUID().uuidString,
            name: name,
            details: ""
        )
        draftBlocks.append(new)
    }

    private func indexForBlock(named name: String) -> Int? {
        draftBlocks.firstIndex(where: { isSameBlockName($0.name, name) })
    }

    private func bindingForBlockDetails(title: String) -> Binding<String> {
        Binding<String>(
            get: {
                guard let idx = indexForBlock(named: title) else { return "" }
                return draftBlocks[idx].details
            },
            set: { newValue in
                guard let idx = indexForBlock(named: title) else { return }
                draftBlocks[idx].details = newValue
            }
        )
    }

    private func saveBlocks() async {
        errorMessage = nil
        successMessage = nil

        guard let templateId = template.id?.trimmingCharacters(in: .whitespacesAndNewlines),
              !templateId.isEmpty else {
            errorMessage = "Não foi possível salvar: templateId inválido."
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            try await FirestoreRepository.shared.updateWorkoutTemplateBlocks(
                templateId: templateId,
                blocks: draftBlocks
            )

            successMessage = "Alterações salvas com sucesso!"
            isEditing = false

            NotificationCenter.default.post(name: .workoutTemplateUpdated, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
