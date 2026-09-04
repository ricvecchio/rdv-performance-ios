import SwiftUI
import Charts

// Tela do Aluno: Recorde Pessoal > Gymnastic (lista fixa + registros)
struct StudentGymnasticPersonalRecordsView: View {

    @Binding var path: [AppRoute]

    private let contentMaxWidth: CGFloat = 380

    private struct GymItem: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let metric: String
        let storageKey: String
    }

    private struct CustomGymItem: Identifiable, Hashable, Codable {
        let id: String
        let name: String
        let metric: String
        let storageKey: String
    }


    private struct PRHistoryEntry: Identifiable, Codable, Hashable {
        let id: String
        let value: String
        let createdAt: Date
    }

    private struct HistoryChartPoint: Identifiable {
        let id: String
        let date: Date
        let value: Double
    }

    private enum PRMetricComparison: Equatable {
        case time
        case higher
    }

    // ✅ Dados fixos conforme solicitado
    private let items: [GymItem] = [
        .init(name: "Abmat", metric: "Max Reps", storageKey: "abmat"),
        .init(name: "Air Squat", metric: "Max Reps", storageKey: "air_squat"),
        .init(name: "Bar Muscle-Ups", metric: "Max Reps", storageKey: "bar_muscle_ups"),
        .init(name: "Box Jump", metric: "Max Height", storageKey: "box_jump"),
        .init(name: "Double Unders", metric: "Max Reps", storageKey: "double_unders"),
        .init(name: "Handstand Push-Ups", metric: "Max", storageKey: "handstand_push_ups"),
        .init(name: "Handstand Walk", metric: "Max Distance", storageKey: "handstand_walk"),
        .init(name: "L-Sit", metric: "Max Hold", storageKey: "l_sit"),
        .init(name: "Muscle-Ups", metric: "30 Reps for Time", storageKey: "muscle_ups_30_for_time"),
        .init(name: "Pull-Up (Weighted)", metric: "1 Rep Max", storageKey: "pull_up_weighted_1rm"),
        .init(name: "Pull-Ups (Chest To Bar)", metric: "Max Reps", storageKey: "pull_ups_ctb"),
        .init(name: "Pull-Ups (Strict Chest To Bar)", metric: "Max Reps", storageKey: "pull_ups_strict_ctb"),
        .init(name: "Pull-Ups (Strict)", metric: "Max Reps", storageKey: "pull_ups_strict"),
        .init(name: "Pull-Ups", metric: "Max Reps", storageKey: "pull_ups"),
        .init(name: "Push-Ups", metric: "Max Reps", storageKey: "push_ups"),
        .init(name: "Ring Dips", metric: "Max Reps", storageKey: "ring_dips"),
        .init(name: "Ring Muscle-Ups", metric: "Max Reps", storageKey: "ring_muscle_ups"),
        .init(name: "Ring Row", metric: "", storageKey: "ring_row"),
        .init(name: "Single Unders", metric: "Max Reps", storageKey: "single_unders"),
        .init(name: "Sit Up", metric: "Max Reps 1'", storageKey: "sit_up_max_reps_1min"),
        .init(name: "Strict Handstand Push-Ups", metric: "Max Reps", storageKey: "strict_handstand_push_ups"),
        .init(name: "Strict Ring Muscle-Ups", metric: "Max Reps", storageKey: "strict_ring_muscle_ups"),
        .init(name: "Tabata Squat", metric: "", storageKey: "tabata_squat"),
        .init(name: "Toes To Bar", metric: "Max Reps", storageKey: "toes_to_bar"),
        .init(name: "WallBall", metric: "Max Reps", storageKey: "wallball")
    ]

    // Persistência simples (UserDefaults via AppStorage)
    @AppStorage("student_pr_gymnastic_values_v1")
    private var gymValuesData: Data = Data()

    @AppStorage("student_pr_gymnastic_history_v1")
    private var gymHistoryData: Data = Data()

    // ✅ Persistência dos itens criados pelo aluno
    @AppStorage("student_pr_gymnastic_custom_items_v1")
    private var customItemsData: Data = Data()

    @State private var selectedItem: GymItem?
    @State private var inputValue: String = ""
    @State private var historyItem: GymItem?
    @State private var selectedPRDate: Date = Date()
    @State private var showPRDatePicker: Bool = false

    // ✅ Adicionar item
    @State private var showAddItemSheet: Bool = false
    @State private var newItemName: String = ""
    @State private var newItemMetric: String = ""
    @State private var newItemValue: String = ""
    @State private var addItemErrorMessage: String? = nil

    // ✅ Confirmação de exclusão (apenas itens novos)
    @State private var showDeleteAlert: Bool = false

    private var allItems: [GymItem] {
        let custom = loadCustomItems().map { GymItem(name: $0.name, metric: $0.metric, storageKey: $0.storageKey) }
        return items + custom
    }

    private var canDeleteSelectedItem: Bool {
        guard let key = selectedItem?.storageKey else { return false }
        return key.hasPrefix("custom_gym_")
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

                            HStack(alignment: .center, spacing: 10) {
                                Text("Adicione seu recorde por movimento.")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.55))

                                Spacer()

                                Button {
                                    addItemErrorMessage = nil
                                    newItemName = ""
                                    newItemMetric = ""
                                    newItemValue = ""
                                    showAddItemSheet = true
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.green.opacity(0.85))
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Adicionar novo item")
                            }

                            tableContainer()

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
                    kind: .agendaSobrePerfil(
                        isAgendaSelected: false,
                        isSobreSelected: true,
                        isPerfilSelected: false
                    )
                )
                .frame(height: Theme.Layout.footerHeight)
                .background(Theme.Colors.footerBackground)
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
        .blur(radius: (selectedItem != nil || historyItem != nil || showPRDatePicker || showAddItemSheet) ? 4 : 0)
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
                Text("Gymnastic")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .topBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(item: $selectedItem) { item in
            editSheet(item: item)
        }
        .sheet(isPresented: $showAddItemSheet) {
            addItemSheet()
        }
    }

    private func tableContainer() -> some View {
        VStack(spacing: 0) {

            tableHeader()

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)

            let list = allItems

            ForEach(Array(list.enumerated()), id: \.element.id) { index, item in

                tableRow(item: item)

                if index != list.count - 1 {
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 1)
                        .padding(.leading, 14)
                }
            }
        }
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func tableHeader() -> some View {
        HStack(spacing: 10) {

            Color.clear
                .frame(width: 26, height: 1)

            Text("Movimento")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.55))

            Spacer()

            Text("PR")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.55))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func tableRow(item: GymItem) -> some View {
        let value = bestDisplayValue(for: item.storageKey, metadata: item.metric)

        return Button {
            selectedItem = item
            inputValue = bestDisplayValue(for: item.storageKey, metadata: item.metric) ?? ""
            selectedPRDate = Date()
        } label: {
            HStack(spacing: 10) {

                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundColor(.green.opacity(0.85))
                    .font(.system(size: 15))
                    .frame(width: 26)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    if !item.metric.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(item.metric)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.45))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                }

                Spacer()

                if let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(value)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.88))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                } else {
                    Text("-")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.45))
                }

                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.25))
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.leading, 6)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func editSheet(item: GymItem) -> some View {
        let canDelete = item.storageKey.hasPrefix("custom_gym_")

        return ZStack {
            Theme.Colors.headerBackground
                .ignoresSafeArea()

            VStack(spacing: 14) {

                Capsule()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 44, height: 5)
                    .padding(.top, 10)

                Text(item.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 4)

                if !item.metric.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(item.metric)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.55))
                }

                Text("Informe seu recorde. Para remover, deixe vazio.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.60))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Resultado:")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))

                    TextField("Ex: 50 / 1,90m / 3:25", text: $inputValue)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(Theme.Colors.cardBackground)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)

                if canDelete {
                    Text("Ao excluir, o registro será removido do seu histórico. Esta ação não pode ser desfeita.")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.50))
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                }

                dateAndHistorySection(key: item.storageKey, metadata: item.metric, historyAction: {
                    historyItem = item
                })
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .sheet(item: $historyItem) { selected in
                    historySheet(title: selected.name, key: selected.storageKey)
                }
                .sheet(isPresented: $showPRDatePicker) {
                    ZStack {
                        Theme.Colors.headerBackground.ignoresSafeArea()
                        VStack(spacing: 16) {
                            DatePicker("Data do PR", selection: $selectedPRDate, in: ...Date(), displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .environment(\.locale, Locale(identifier: "pt_BR"))
                            Button { showPRDatePicker = false } label: {
                                Text("Confirmar")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.black.opacity(0.85))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.green.opacity(0.90))
                                    .cornerRadius(14)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(16)
                    }
                    .presentationDetents([.medium])
                }

                HStack(spacing: 12) {

                    Button {
                        selectedItem = nil
                    } label: {
                        Text("Cancelar")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.10))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        saveCurrentInput()
                        selectedItem = nil
                    } label: {
                        Text("Salvar")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.black.opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.green.opacity(0.90))
                            .cornerRadius(14)
                    }
                    .buttonStyle(.plain)

                    if canDelete {
                        Button {
                            showDeleteAlert = true
                        } label: {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.white.opacity(0.92))
                                .font(.system(size: 16, weight: .bold))
                                .frame(width: 50, height: 50)
                                .background(Color.red.opacity(0.85))
                                .cornerRadius(14)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Excluir item")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)

                Spacer()
            }
        }
        .presentationDetents([.fraction(0.75)])
        .onAppear {
            inputValue = bestDisplayValue(for: item.storageKey, metadata: item.metric) ?? ""
            selectedPRDate = Date()
        }
        .alert("Excluir registro", isPresented: $showDeleteAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Excluir", role: .destructive) {
                deleteSelectedItem()
            }
        } message: {
            Text("Deseja excluir o registro de \"\(item.name)\"?")
        }
    }

    private func addItemSheet() -> some View {
        ZStack {
            Theme.Colors.headerBackground
                .ignoresSafeArea()

            VStack(spacing: 14) {

                Capsule()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 44, height: 5)
                    .padding(.top, 10)

                Text("Novo item")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 4)

                Text("Crie um item e, se quiser, já informe seu recorde.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.60))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 10) {

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nome do movimento")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))

                        TextField("Ex: Rope Climb", text: $newItemName)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled(true)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.92))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tipo / Métrica (opcional)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))

                        TextField("Ex: Max Reps / For Time / Max Distance", text: $newItemMetric)
                            .textInputAutocapitalization(.sentences)
                            .autocorrectionDisabled(true)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.92))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recorde (opcional)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))

                        TextField("Ex: 50 / 1,90m / 3:25", text: $newItemValue)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.92))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    }

                    if let msg = addItemErrorMessage {
                        Text(msg)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.yellow.opacity(0.85))
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)

                HStack(spacing: 12) {

                    Button {
                        showAddItemSheet = false
                    } label: {
                        Text("Cancelar")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.10))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        addNewItem()
                    } label: {
                        Text("Adicionar")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.black.opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.green.opacity(0.90))
                            .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)

                Spacer()
            }
        }
        .presentationDetents([.medium])
    }

    private func addNewItem() {
        addItemErrorMessage = nil

        let cleanName = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else {
            addItemErrorMessage = "Informe o nome do movimento."
            return
        }

        let existingNames = allItems.map { $0.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
        if existingNames.contains(cleanName.lowercased()) {
            addItemErrorMessage = "Este item já existe na sua lista."
            return
        }

        let id = UUID().uuidString
        let key = "custom_gym_\(id)"

        let metric = newItemMetric.trimmingCharacters(in: .whitespacesAndNewlines)

        var list = loadCustomItems()
        list.append(CustomGymItem(id: id, name: cleanName, metric: metric, storageKey: key))
        saveCustomItems(list)

        let trimmedValue = newItemValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedValue.isEmpty {
            saveValue(trimmedValue, for: key)
            saveHistoryValue(trimmedValue, for: key, date: Date())
        }

        showAddItemSheet = false
    }

    private func saveCurrentInput() {
        guard let item = selectedItem else { return }
        let trimmed = inputValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            removeValue(for: item.storageKey)
            return
        }
        let metadata = item.metric
        let shouldSave = shouldUpdatePrimary(trimmed, key: item.storageKey, metadata: metadata)
        saveHistoryValue(trimmed, for: item.storageKey, date: selectedPRDate)
        if shouldSave {
            saveValue(trimmed, for: item.storageKey)
        }
    }

    private func deleteSelectedItem() {
        guard let item = selectedItem else { return }

        let key = item.storageKey

        guard key.hasPrefix("custom_gym_") else {
            selectedItem = nil
            return
        }

        removeValue(for: key)
        removeHistory(for: key)

        var list = loadCustomItems()
        list.removeAll { $0.storageKey == key }
        saveCustomItems(list)

        selectedItem = nil
    }


    @ViewBuilder
    private func dateAndHistorySection(key: String, metadata: String, historyAction: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Data")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.75))

            Button {
                showPRDatePicker = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .foregroundColor(.green.opacity(0.85))
                    Text(formatPRDate(selectedPRDate))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.25))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Evolução", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.75))
                Spacer()
                Button(action: historyAction) {
                    Label("Histórico", systemImage: "clock.arrow.circlepath")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.green.opacity(0.90))
                }
                .buttonStyle(.plain)
            }
            historyChart(for: key, metadata: metadata)
        }
    }

    private func historySheet(title: String, key: String) -> some View {
        let entries = historyEntries(for: key)
        return ZStack {
            Theme.Colors.headerBackground.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                    if entries.isEmpty {
                        Text("Nenhum histórico de evolução registrado ainda.")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.60))
                    } else {
                        VStack(spacing: 0) {
                            ForEach(entries.reversed()) { entry in
                                HStack {
                                    Text(entry.value)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.92))
                                    Spacer()
                                    Text(entry.createdAt.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year().locale(Locale(identifier: "pt_BR"))))
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.45))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                if entry.id != entries.first?.id {
                                    Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1).padding(.leading, 14)
                                }
                            }
                        }
                        .background(Theme.Colors.cardBackground)
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
                    }
                }
                .frame(maxWidth: contentMaxWidth)
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
            }
        }
        .presentationDetents([.large])
    }

    @ViewBuilder
    private func historyChart(for key: String, metadata: String) -> some View {
        let entries = historyChartPoints(for: key, metadata: metadata)
        if !entries.isEmpty {
            Chart(entries) { entry in
                LineMark(x: .value("Data", entry.date), y: .value("Resultado", entry.value))
                    .foregroundStyle(.green)
                    .interpolationMethod(.linear)
                PointMark(x: .value("Data", entry.date), y: .value("Resultado", entry.value))
                    .foregroundStyle(.green)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) {
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(Color.white.opacity(0.12))
                    AxisValueLabel(format: .dateTime.day(.twoDigits).month(.twoDigits).year()).foregroundStyle(Color.white.opacity(0.55))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(Color.white.opacity(0.12))
                    AxisValueLabel().foregroundStyle(Color.white.opacity(0.55))
                }
            }
            .frame(height: 170)
            .padding(14)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
    }

    private func formatPRDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "dd 'de' MMMM, yyyy"
        return formatter.string(from: date)
    }

    private func metricComparison(for metadata: String) -> PRMetricComparison? {
        let normalized = metadata.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current).lowercased()
        if normalized.contains("for time") || normalized.contains("para tempo") || normalized.contains("por tempo") || normalized.contains("30 reps for time") {
            return .time
        }
        if normalized.contains("max reps") || normalized.contains("max height") || normalized.contains("max distance") || normalized.contains("1 rep max") || normalized.contains("1rm") || normalized.contains("max hold") || normalized.contains("amrap") || normalized.contains("for load") || normalized.contains("max") || normalized.contains("reps") || normalized.contains("score") || normalized.contains("load") {
            return .higher
        }
        return nil
    }

    private func numericValue(_ value: String, metadata: String) -> Double? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if metricComparison(for: metadata) == .time {
            let parts = trimmed.split(separator: ":", omittingEmptySubsequences: false)
            if parts.count == 1 {
                return Double(trimmed.replacingOccurrences(of: ",", with: "."))
            }
            guard (2...3).contains(parts.count), let last = Int(parts.last ?? ""), last >= 0,
                  let middle = Int(parts[parts.count - 2]), middle >= 0, middle < 60, last < 60 else { return nil }
            if parts.count == 2 { return Double(middle * 60 + last) }
            guard let first = Int(parts[0]), first >= 0 else { return nil }
            return Double(first * 3600 + middle * 60 + last)
        }
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        let suffixes = ["repeticoes", "reps", "rep", "pontos", "pts", "pt", "cals", "cal", "kgs", "kg", "lbs", "lb", "cm", "m"]
        let numericText = suffixes.first(where: { normalized.lowercased().hasSuffix($0) }).map {
            String(normalized.dropLast($0.count)).trimmingCharacters(in: .whitespacesAndNewlines)
        } ?? normalized
        guard let parsed = Double(numericText), parsed.isFinite else { return nil }
        return parsed
    }

    private func bestDisplayValue(for key: String, metadata: String) -> String? {
        guard let comparison = metricComparison(for: metadata) else { return loadValue(for: key) }
        var candidates: [(String, Double)] = historyEntries(for: key).compactMap { entry in
            numericValue(entry.value, metadata: metadata).map { (entry.value, $0) }
        }
        if let legacy = loadValue(for: key), let value = numericValue(legacy, metadata: metadata) {
            candidates.append((legacy, value))
        }
        guard var best = candidates.first else { return loadValue(for: key) }
        for candidate in candidates.dropFirst() {
            if comparison == .time ? candidate.1 < best.1 : candidate.1 > best.1 { best = candidate }
        }
        return best.0
    }

    private func shouldUpdatePrimary(_ value: String, key: String, metadata: String) -> Bool {
        guard let comparison = metricComparison(for: metadata), let incoming = numericValue(value, metadata: metadata) else {
            return loadValue(for: key) == nil
        }
        var values = historyEntries(for: key).compactMap { numericValue($0.value, metadata: metadata) }
        if let legacy = loadValue(for: key), let legacyValue = numericValue(legacy, metadata: metadata) { values.append(legacyValue) }
        guard let best = comparison == .time ? values.min() : values.max() else { return true }
        return comparison == .time ? incoming < best : incoming > best
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

// MARK: - Persistência (JSON em Data)
private extension StudentGymnasticPersonalRecordsView {

    func loadMap() -> [String: String] {
        guard !gymValuesData.isEmpty else { return [:] }
        do {
            return try JSONDecoder().decode([String: String].self, from: gymValuesData)
        } catch {
            return [:]
        }
    }

    func saveMap(_ map: [String: String]) {
        do {
            gymValuesData = try JSONEncoder().encode(map)
        } catch {
            gymValuesData = Data()
        }
    }



    private func loadHistoryMap() -> [String: [PRHistoryEntry]] {
        guard !gymHistoryData.isEmpty else { return [:] }
        do { return try JSONDecoder().decode([String: [PRHistoryEntry]].self, from: gymHistoryData) } catch { return [:] }
    }

    private func saveHistoryMap(_ map: [String: [PRHistoryEntry]]) {
        do { gymHistoryData = try JSONEncoder().encode(map) } catch { gymHistoryData = Data() }
    }

    private func historyEntries(for key: String) -> [PRHistoryEntry] {
        loadHistoryMap()[key, default: []].sorted { $0.createdAt < $1.createdAt }
    }

    private func historyChartPoints(for key: String, metadata: String) -> [HistoryChartPoint] {
        historyEntries(for: key).compactMap { entry in
            numericValue(entry.value, metadata: metadata).map { HistoryChartPoint(id: entry.id, date: entry.createdAt, value: $0) }
        }
    }

    private func saveHistoryValue(_ value: String, for key: String, date: Date) {
        var map = loadHistoryMap()
        var entries = map[key, default: []]
        let normalizedDate = Calendar.current.startOfDay(for: date)
        guard !entries.contains(where: { $0.value == value && Calendar.current.isDate($0.createdAt, inSameDayAs: normalizedDate) }) else { return }
        entries.append(PRHistoryEntry(id: UUID().uuidString, value: value, createdAt: normalizedDate))
        map[key] = entries
        saveHistoryMap(map)
    }

    private func removeHistory(for key: String) {
        var map = loadHistoryMap()
        map.removeValue(forKey: key)
        saveHistoryMap(map)
    }

    func loadValue(for key: String) -> String? {
        let map = loadMap()
        return map[key]
    }

    func saveValue(_ value: String, for key: String) {
        var map = loadMap()
        map[key] = value
        saveMap(map)
    }

    func removeValue(for key: String) {
        var map = loadMap()
        map.removeValue(forKey: key)
        saveMap(map)
    }

    private func loadCustomItems() -> [CustomGymItem] {
        guard !customItemsData.isEmpty else { return [] }
        do {
            return try JSONDecoder().decode([CustomGymItem].self, from: customItemsData)
        } catch {
            return []
        }
    }

    private func saveCustomItems(_ list: [CustomGymItem]) {
        do {
            customItemsData = try JSONEncoder().encode(list)
        } catch {
            customItemsData = Data()
        }
    }
}
