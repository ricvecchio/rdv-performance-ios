import SwiftUI

// MARK: - Aluno: Detalhe do Dia (MVP)
struct StudentDayDetailView: View {

    @Binding var path: [AppRoute]

    // ✅ Necessário para editar/excluir no Firestore
    let weekId: String

    let day: TrainingDayFS
    let weekTitle: String

    @EnvironmentObject private var session: AppSession

    private let contentMaxWidth: CGFloat = 380

    // ✅ Editar/Excluir
    @State private var showEditSheet: Bool = false
    @State private var showDeleteConfirm: Bool = false
    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil

    // Campos edição
    @State private var editTitle: String = ""
    @State private var editDescription: String = ""
    @State private var editBlocks: [BlockFS] = []

    // ✅ Controle para evitar resetar campos enquanto edita
    @State private var didPrepareEditFields: Bool = false

    private var isTeacherViewing: Bool { session.userType == .TRAINER }

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
                    VStack(spacing: 16) {
                        header

                        if let err = errorMessage {
                            messageCard(text: err)
                        }

                        trainingCard
                        blocksCard
                    }
                    .frame(maxWidth: contentMaxWidth)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                    .frame(maxWidth: .infinity)
                }

                footer
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
                Text("Dia de treino")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItemGroup(placement: .navigationBarTrailing) {

                // ✅ Menu para professor editar/excluir
                if isTeacherViewing {
                    Menu {
                        Button {
                            // ✅ Reset da flag (vamos preparar quando a sheet aparecer)
                            didPrepareEditFields = false
                            showEditSheet = true
                        } label: {
                            Label("Editar", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Excluir", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)
                }

                MiniProfileHeader(imageName: "rdv_eu", size: 38)
                    .background(Color.clear)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .alert("Excluir dia?", isPresented: $showDeleteConfirm) {
            Button("Cancelar", role: .cancel) {}
            Button("Excluir", role: .destructive) {
                Task { await deleteDay() }
            }
        } message: {
            Text("O dia \"\(day.title)\" será excluído.")
        }
        .sheet(isPresented: $showEditSheet, onDismiss: {
            // ✅ Ao fechar a sheet, liberamos para preparar na próxima abertura
            didPrepareEditFields = false
        }) {
            editDaySheet
                .onAppear {
                    // ✅ GARANTIA: quando a sheet abrir, prepara os campos 1x
                    guard !didPrepareEditFields else { return }
                    prepareEditFields()
                    didPrepareEditFields = true
                }
        }
    }

    private var footer: some View {
        FooterBar(
            path: $path,
            kind: .agendaSobrePerfil(
                isAgendaSelected: true,
                isSobreSelected: false,
                isPerfilSelected: false
            )
        )
        .frame(height: Theme.Layout.footerHeight)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.footerBackground)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {

            Text("Semana: \(weekTitle)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.55))

            Text(day.subtitleText)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var trainingCard: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text("Treino")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.75))

            VStack(alignment: .leading, spacing: 6) {
                Text(day.title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))

                if let dateText = formattedDate(day.date) {
                    Text(dateText)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.45))
                }

                if !day.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(day.description)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.65))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    private var blocksCard: some View {
        VStack(alignment: .leading, spacing: 10) {

            if day.blocks.isEmpty {
                Text("Nenhum bloco cadastrado.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.55))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(day.blocks.enumerated()), id: \.offset) { idx, block in
                        VStack(alignment: .leading, spacing: 6) {

                            Text(block.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.92))

                            if !block.details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(block.details)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.65))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.vertical, 12)

                        if idx < day.blocks.count - 1 {
                            innerDivider(leading: 0)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    private func messageCard(text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow.opacity(0.85))
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.75))
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.35))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func innerDivider(leading: CGFloat) -> some View {
        Divider()
            .background(Theme.Colors.divider)
            .padding(.leading, leading)
    }

    private func formattedDate(_ date: Date?) -> String? {
        guard let date else { return nil }
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateStyle = .medium
        return f.string(from: date)
    }

    // MARK: - Edit helpers

    private func prepareEditFields() {
        editTitle = day.title
        editDescription = day.description
        editBlocks = day.blocks
        errorMessage = nil
    }

    private var editDaySheet: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {

                Text("Editar dia de treino")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))

                UnderlineTextField(
                    title: "Título",
                    text: $editTitle,
                    isSecure: false,
                    showPassword: .constant(false),
                    lineColor: Theme.Colors.divider,
                    textColor: .white.opacity(0.92),
                    placeholderColor: .white.opacity(0.55)
                )

                UnderlineTextField(
                    title: "Descrição",
                    text: $editDescription,
                    isSecure: false,
                    showPassword: .constant(false),
                    lineColor: Theme.Colors.divider,
                    textColor: .white.opacity(0.92),
                    placeholderColor: .white.opacity(0.55)
                )

                Divider().background(Theme.Colors.divider)

                // ✅ Blocos (Aquecimento/Técnica/WOD)
                blocksEditorSection

                Divider().background(Theme.Colors.divider)

                HStack(spacing: 10) {

                    Button { showEditSheet = false } label: {
                        Text("Cancelar")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.90))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.10))
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)

                    Button { Task { await saveDayEdits() } } label: {
                        HStack(spacing: 8) {
                            if isSaving { ProgressView().tint(.white) }
                            Text("Salvar")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.green.opacity(0.16))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green.opacity(0.35), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)

                    Spacer()
                }

                Spacer()
            }
            .padding(16)
            .frame(maxWidth: 420)
        }
        .presentationDetents([.medium])
    }

    private var blocksEditorSection: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text("Blocos")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.75))

            if editBlocks.isEmpty {
                Text("Nenhum bloco cadastrado para este dia.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.55))
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(editBlocks.indices, id: \.self) { i in
                            VStack(alignment: .leading, spacing: 8) {

                                Text(editBlocks[i].name)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.92))

                                TextEditor(text: Binding(
                                    get: { editBlocks[i].details },
                                    set: { editBlocks[i].details = $0 }
                                ))
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.85))
                                .scrollContentBackground(.hidden)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(10)
                                .frame(minHeight: 70)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.top, 2)
                }
                .frame(maxHeight: 220)
            }
        }
    }

    private func saveDayEdits() async {
        errorMessage = nil

        guard let dayId = day.id, !dayId.isEmpty else {
            errorMessage = "Dia inválido: id não encontrado."
            return
        }

        let t = editTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else {
            errorMessage = "Informe o título do dia."
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            try await FirestoreRepository.shared.upsertDay(
                weekId: weekId,
                dayId: dayId,
                dayIndex: day.dayIndex,
                dayName: day.dayName,
                date: day.date ?? Date(),
                title: t,
                description: editDescription,
                blocks: editBlocks
            )
            showEditSheet = false

            // ✅ Mantém fluxo estável: volta para a tela anterior para evitar estado desatualizado.
            pop()

        } catch {
            errorMessage = (error as NSError).localizedDescription
        }
    }

    private func deleteDay() async {
        errorMessage = nil

        guard let dayId = day.id, !dayId.isEmpty else {
            errorMessage = "Dia inválido: id não encontrado."
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            try await FirestoreRepository.shared.deleteTrainingDay(weekId: weekId, dayId: dayId)
            pop()
        } catch {
            errorMessage = (error as NSError).localizedDescription
        }
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

