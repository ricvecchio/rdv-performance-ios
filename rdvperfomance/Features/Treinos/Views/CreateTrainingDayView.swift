import SwiftUI

/// Tela para criar ou editar um dia de treino dentro de uma semana
struct CreateTrainingDayView: View {

    @Binding var path: [AppRoute]
    let weekId: String
    let category: TreinoTipo

    @EnvironmentObject private var session: AppSession

    // Form
    @State private var dayIndex: Int = 0
    @State private var dayName: String = "Dia 1"
    @State private var date: Date = Date()

    @State private var title: String = ""
    @State private var description: String = ""

    @State private var blocks: [BlockDraft] = [
        BlockDraft(name: "Aquecimento", details: ""),
        BlockDraft(name: "Técnica", details: ""),
        BlockDraft(name: "WOD", details: "")
    ]

    @State private var showPasswordDummy: Bool = false

    // UI state
    @State private var isSaving: Bool = false
    @State private var isLoadingDays: Bool = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil

    // Controles de edição e dias existentes
    @State private var existingDaysByIndex: [Int: TrainingDayFS] = [:]
    @State private var currentEditingDayId: String? = nil
    @State private var baseWeekStartDate: Date? = nil

    // Evita sobrescrever data quando usuário escolhe manualmente
    @State private var didUserManuallyPickDate: Bool = false

    private let contentMaxWidth: CGFloat = 380

    /// Corpo principal da view com header, formulários e ações
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
                    .frame(maxWidth: .infinity)

                ScrollView(showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 0)

                        VStack(alignment: .leading, spacing: 14) {

                            header

                            dayMetaCard
                            trainingCard
                            blocksCard

                            saveButtonCard

                            if let err = errorMessage {
                                messageCard(text: err, isError: true)
                            }

                            if let ok = successMessage {
                                messageCard(text: ok, isError: false)
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
                .frame(maxWidth: .infinity)
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
                Text("Criar dia")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task {
            await bootstrapDays()
        }
        .onChange(of: dayIndex) { _, newValue in
            loadDayIntoFormIfExists(index: newValue)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Categoria: \(category.displayName)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.green.opacity(0.85))

            if isLoadingDays {
                Text("Carregando dias cadastrados...")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.55))
            } else {
                Text("Adicione ou edite um dia de treino desta semana.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.55))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Card com formulário de metadados do dia: data, ordem e nome
    private var dayMetaCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            VStack(alignment: .leading, spacing: 6) {
                Text("Data")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.55))

                DatePicker("", selection: $date, displayedComponents: [.date])
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(.green.opacity(0.85))
                    .colorScheme(.dark)
                    .onChange(of: date) { _, _ in
                        didUserManuallyPickDate = true
                    }
            }

            Divider().background(Theme.Colors.divider)

            VStack(alignment: .leading, spacing: 6) {
                Text("Ordem do dia")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.55))

                Picker("Ordem do dia", selection: $dayIndex) {
                    ForEach(0..<7, id: \.self) { i in
                        let exists = existingDaysByIndex[i] != nil
                        Text(exists ? "Dia \(i + 1) ✓" : "Dia \(i + 1)").tag(i)
                    }
                }
                .pickerStyle(.segmented)
            }

            Divider().background(Theme.Colors.divider)

            UnderlineTextField(
                title: "Nome do dia (ex: Segunda-feira)",
                text: $dayName,
                isSecure: false,
                showPassword: $showPasswordDummy,
                lineColor: Theme.Colors.divider,
                textColor: .white.opacity(0.92),
                placeholderColor: .white.opacity(0.55)
            )
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

    /// Card com formulário de título e descrição do treino
    private var trainingCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            UnderlineTextField(
                title: "Título do treino",
                text: $title,
                isSecure: false,
                showPassword: $showPasswordDummy,
                lineColor: Theme.Colors.divider,
                textColor: .white.opacity(0.92),
                placeholderColor: .white.opacity(0.55)
            )

            Divider().background(Theme.Colors.divider)

            VStack(alignment: .leading, spacing: 6) {
                Text("Descrição")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.55))

                TextEditor(text: $description)
                    .foregroundColor(.white.opacity(0.92))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 90)
                    .padding(10)
                    .background(Color.black.opacity(0.22))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
            }
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

    /// Card com editor de blocos de exercícios do dia
    private var blocksCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Spacer()
                Button {
                    blocks.append(BlockDraft(name: "Novo bloco", details: ""))
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green.opacity(0.85))
                        .font(.system(size: 18))
                }
                .buttonStyle(.plain)
            }

            ForEach($blocks) { $b in
                VStack(alignment: .leading, spacing: 10) {

                    HStack {
                        Text(b.name.isEmpty ? "Sem nome" : b.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.70))

                        Spacer()

                        Button {
                            if let idx = blocks.firstIndex(where: { $0.id == b.id }) {
                                blocks.remove(at: idx)
                            }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.yellow.opacity(0.85))
                        }
                        .buttonStyle(.plain)
                    }

                    UnderlineTextField(
                        title: "",
                        text: $b.name,
                        isSecure: false,
                        showPassword: $showPasswordDummy,
                        lineColor: Theme.Colors.divider,
                        textColor: .white.opacity(0.92),
                        placeholderColor: .white.opacity(0.55)
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Detalhes")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.55))

                        TextEditor(text: $b.details)
                            .foregroundColor(.white.opacity(0.92))
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 70)
                            .padding(10)
                            .background(Color.black.opacity(0.22))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                    }

                    Divider().background(Theme.Colors.divider)
                }
                .padding(.vertical, 6)
            }

            if blocks.isEmpty {
                Text("Nenhum bloco adicionado.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.55))
            }
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

    /// Botão para salvar ou atualizar o dia de treino
    private var saveButtonCard: some View {
        Button {
            Task { await saveDay() }
        } label: {
            HStack {
                Spacer()
                if isSaving {
                    ProgressView().tint(.white)
                } else {
                    Text(currentEditingDayId == nil ? "Salvar Dia" : "Salvar Alterações")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                }
                Spacer()
            }
            .padding(.vertical, 14)
            .background(Color.green.opacity(0.16))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
    }

    private func messageCard(text: String, isError: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundColor(isError ? .yellow.opacity(0.85) : .green.opacity(0.85))

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

    /// Carrega dias existentes da semana e posiciona no primeiro dia disponível
    private func bootstrapDays() async {
        isLoadingDays = true
        defer { isLoadingDays = false }

        do {
            let days = try await FirestoreRepository.shared.getDaysForWeek(weekId: weekId)

            var dict: [Int: TrainingDayFS] = [:]
            for d in days { dict[d.dayIndex] = d }
            existingDaysByIndex = dict

            let dates = days.compactMap { $0.date }
            baseWeekStartDate = dates.min()

            let firstMissing = (0...6).first(where: { dict[$0] == nil }) ?? 0
            dayIndex = firstMissing

            didUserManuallyPickDate = false
            loadDayIntoFormIfExists(index: dayIndex)

        } catch {
            errorMessage = (error as NSError).localizedDescription
        }
    }

    /// Carrega dados de um dia existente no formulário ou limpa para novo dia
    private func loadDayIntoFormIfExists(index: Int) {
        errorMessage = nil
        successMessage = nil

        if let existing = existingDaysByIndex[index] {
            currentEditingDayId = existing.id
            dayName = existing.dayName
            date = existing.date ?? date
            title = existing.title
            description = existing.description
            blocks = existing.blocks.map { BlockDraft(id: $0.id, name: $0.name, details: $0.details) }

            didUserManuallyPickDate = true
            return
        }

        currentEditingDayId = nil
        title = ""
        description = ""
        blocks = [
            BlockDraft(name: "Aquecimento", details: ""),
            BlockDraft(name: "Técnica", details: ""),
            BlockDraft(name: "WOD", details: "")
        ]

        dayName = ""
        syncDayName()

        if !didUserManuallyPickDate {
            let base = baseWeekStartDate ?? Date()
            if let computed = Calendar.current.date(byAdding: .day, value: index, to: base) {
                date = computed
            }
        }
    }

    /// Valida e salva ou atualiza o dia de treino no Firestore
    private func saveDay() async {
        errorMessage = nil
        successMessage = nil

        guard session.userType == .TRAINER else {
            errorMessage = "Apenas professor pode adicionar dias."
            return
        }

        let cleanWeekId = weekId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanWeekId.isEmpty else {
            errorMessage = "weekId inválido."
            return
        }

        let cleanDayName = dayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanDayName.isEmpty else {
            errorMessage = "Informe o nome do dia."
            return
        }

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            errorMessage = "Informe o título do treino."
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let payloadBlocks: [BlockFS] = blocks
                .filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .map { BlockFS(id: $0.id, name: $0.name, details: $0.details) }

            _ = try await FirestoreRepository.shared.upsertDay(
                weekId: cleanWeekId,
                dayId: currentEditingDayId,
                dayIndex: dayIndex,
                dayName: cleanDayName,
                date: date,
                title: cleanTitle,
                description: description,
                blocks: payloadBlocks
            )

            successMessage = currentEditingDayId == nil ? "Dia salvo com sucesso!" : "Alterações salvas com sucesso!"

            didUserManuallyPickDate = false
            await bootstrapDays()

        } catch {
            errorMessage = (error as NSError).localizedDescription
        }
    }

    /// Sincroniza o nome do dia com o índice quando nome estiver vazio
    private func syncDayName() {
        if dayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || dayName.hasPrefix("Dia ") {
            dayName = "Dia \(dayIndex + 1)"
        }
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

/// Modelo temporário de bloco de exercício usado durante edição
private struct BlockDraft: Identifiable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var details: String

    init(id: String = UUID().uuidString, name: String, details: String) {
        self.id = id
        self.name = name
        self.details = details
    }
}
