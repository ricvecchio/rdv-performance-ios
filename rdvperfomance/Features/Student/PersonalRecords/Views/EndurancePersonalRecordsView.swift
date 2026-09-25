import SwiftUI
import Charts

// Tela do Aluno: Recorde Pessoal > Endurance (lista fixa + PR em texto)
struct EndurancePersonalRecordsView: View {

    @Binding var path: [AppRoute]

    /// Presente apenas no contexto de aluno (dentro de `StudentRootView`).
    var onSelectSection: (StudentMainSection) -> Void = { _ in }
    var navigationContext: PersonalRecordsNavigationContext = .student

    private let contentMaxWidth: CGFloat = 380

    private struct EnduranceMove: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let storageKey: String
    }


    private struct CustomEnduranceMove: Identifiable, Hashable, Codable {
        let id: String
        let name: String
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
    private let moves: [EnduranceMove] = [
        .init(name: "Air Bike (100 Cal)", storageKey: "air_bike_100_cal"),
        .init(name: "Air Bike (50 Cal)", storageKey: "air_bike_50_cal"),
        .init(name: "Air Bike (Máx Cal 1)", storageKey: "air_bike_max_cal_1"),
        .init(name: "Row 1 km", storageKey: "row_1_km"),
        .init(name: "Row 10 km", storageKey: "row_10_km"),
        .init(name: "Row 100m", storageKey: "row_100_m"),
        .init(name: "Row 2 km", storageKey: "row_2_km"),
        .init(name: "Row 21 km", storageKey: "row_21_km"),
        .init(name: "Row 5 km", storageKey: "row_5_km"),
        .init(name: "Row 500m", storageKey: "row_500_m"),
        .init(name: "Run 1.200m", storageKey: "run_1200_m"),
        .init(name: "Run 10 km", storageKey: "run_10_km"),
        .init(name: "Run 100m", storageKey: "run_100_m"),
        .init(name: "Run 15 km", storageKey: "run_15_km"),
        .init(name: "Run 1600m", storageKey: "run_1600_m"),
        .init(name: "Run 1km", storageKey: "run_1_km"),
        .init(name: "Run 2 km", storageKey: "run_2_km"),
        .init(name: "Run 200m", storageKey: "run_200_m"),
        .init(name: "Run 300m", storageKey: "run_300_m"),
        .init(name: "Run 400m", storageKey: "run_400_m"),
        .init(name: "Run 5 km", storageKey: "run_5_km"),
        .init(name: "Run 500m", storageKey: "run_500_m"),
        .init(name: "Run 700m", storageKey: "run_700_m"),
        .init(name: "Run 800m", storageKey: "run_800_m")
    ]

    // Persistência simples (UserDefaults via AppStorage)
    @AppStorage("student_pr_endurance_values_v1")
    private var enduranceValuesData: Data = Data()

    @AppStorage("student_pr_endurance_history_v1")
    private var enduranceHistoryData: Data = Data()

    @AppStorage("student_pr_endurance_custom_items_v1")
    private var customEnduranceItemsData: Data = Data()

    @State private var selectedMove: EnduranceMove?
    @State private var inputValue: String = ""
    @State private var historyMove: EnduranceMove?
    @State private var selectedPRDate: Date = Date()
    @State private var showPRDatePicker: Bool = false
    @State private var isEditingExistingPR: Bool = false
    @State private var editingHistoryEntryID: String? = nil
    @State private var historyEntryPendingDeletion: PRHistoryEntry? = nil
    @State private var showHistoryEntryDeletionAlert: Bool = false

    @State private var showAddItemSheet: Bool = false
    @State private var newItemName: String = ""
    @State private var newItemValue: String = ""
    @State private var addItemErrorMessage: String? = nil
    @State private var showDeleteAlert: Bool = false

    private var allMoves: [EnduranceMove] {
        moves + loadCustomItems().map { EnduranceMove(name: $0.name, storageKey: $0.storageKey) }
    }

    private var canDeleteSelectedItem: Bool {
        selectedMove?.storageKey.hasPrefix("custom_endurance_") == true
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
                                Text("Adicione seu melhor resultado por item.")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.55))

                                Spacer()

                                Button {
                                    addItemErrorMessage = nil
                                    newItemName = ""
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

                PersonalRecordsFooter(
                    path: $path,
                    navigationContext: navigationContext,
                    studentFooterKind: .studentHomeTreinosRecordsProfile(
                        isHomeSelected: false,
                        isTreinosSelected: false,
                        isRecordsSelected: true,
                        isPerfilSelected: false
                    ),
                    onSelectStudentSection: onSelectSection
                )
                .frame(height: Theme.Layout.footerHeight)
                .background(Theme.Colors.footerBackground)
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
        .blur(radius: (selectedMove != nil || historyMove != nil || showPRDatePicker || showAddItemSheet) ? 4 : 0)
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
                Text("Endurance")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .topBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(item: $selectedMove, onDismiss: {
            resetExistingPREditing()
        }) { move in
            editSheet(move: move)
        }
        .sheet(isPresented: $showAddItemSheet) {
            addItemSheet()
        }
    }

    // MARK: - Tabela
    private func tableContainer() -> some View {
        VStack(spacing: 0) {

            tableHeader()

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)

            let list = allMoves

            ForEach(Array(list.enumerated()), id: \.element.id) { index, move in

                tableRow(move: move)

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

            Text("Item")
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

    private func tableRow(move: EnduranceMove) -> some View {
        let displayValue = bestDisplayValue(for: move.storageKey, metadata: move.name)

        return Button {
            inputValue = ""
            selectedPRDate = Date()
            resetExistingPREditing()
            selectedMove = move
        } label: {
            HStack(spacing: 10) {

                Image(systemName: "figure.run")
                    .foregroundColor(.green.opacity(0.85))
                    .font(.system(size: 15))
                    .frame(width: 26)

                Text(move.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer()

                if let displayValue, !displayValue.isEmpty {
                    Text(displayValue)
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

    // MARK: - Sheet (editar PR)
    private func editSheet(move: EnduranceMove) -> some View {
        ZStack {
            Theme.Colors.headerBackground
                .ignoresSafeArea()

            VStack(spacing: 14) {

                Capsule()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 44, height: 5)
                    .padding(.top, 10)

                Text(move.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 4)

                Text("Informe seu melhor resultado. Para remover, deixe vazio.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.60))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Resultado:")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))
                    }

                    TextField("Ex: 3:45 ou 120 ou 10:32", text: $inputValue)
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

                dateAndHistorySection(key: move.storageKey, metadata: move.name, historyAction: {
                    historyMove = move
                })
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .sheet(item: $historyMove) { selected in
                    historySheet(title: selected.name, key: selected.storageKey, metadata: selected.name)
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
                                    .frame(maxWidth: .infinity)
                                    .primaryGreenActionButton()
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(16)
                    }
                    .presentationDetents([.medium])
                }

                HStack(spacing: 12) {

                    Button {
                        resetExistingPREditing()
                        selectedMove = nil
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
                        resetExistingPREditing()
                        selectedMove = nil
                    } label: {
                        Text("Salvar")
                            .frame(maxWidth: .infinity)
                            .primaryGreenActionButton()
                    }
                    .buttonStyle(.plain)

                    if canDeleteSelectedItem {
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
        .alert("Excluir registro", isPresented: $showDeleteAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Excluir", role: .destructive) {
                deleteSelectedItem()
            }
        } message: {
            Text("Deseja excluir o registro de \(selectedMove?.name ?? "este item")?")
        }
        .onAppear {
            inputValue = ""
            selectedPRDate = Date()
            resetExistingPREditing()
        }
    }

    private func beginEditingExistingPR(for move: EnduranceMove) {
        let metadata = move.name
        guard let value = bestDisplayValue(for: move.storageKey, metadata: metadata) else { return }

        inputValue = value
        if let entry = currentPRHistoryEntry(for: move.storageKey, metadata: metadata),
           let entryValue = numericValue(entry.value, metadata: metadata),
           let bestValue = numericValue(value, metadata: metadata),
           abs(entryValue - bestValue) < 0.000_001 {
            editingHistoryEntryID = entry.id
            selectedPRDate = entry.createdAt
        } else {
            editingHistoryEntryID = nil
        }
        isEditingExistingPR = true
    }

    private func saveExistingPREdit() {
        guard let move = selectedMove else { return }

        let trimmed = inputValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let key = move.storageKey
        let metadata = move.name
        var history = loadHistoryMap()
        var primaryCandidates: [String]

        if let entryID = editingHistoryEntryID {
            var entries = history[key, default: []]
            guard let index = entries.firstIndex(where: { $0.id == entryID }) else {
                primaryCandidates = entries.map(\.value) + [trimmed]
                saveHistoryValue(trimmed, for: key, date: selectedPRDate)
                if let primaryValue = bestValue(from: primaryCandidates, metadata: metadata) {
                    saveValue(primaryValue, for: key)
                }
                return
            }

            let entry = entries[index]
            entries[index] = PRHistoryEntry(
                id: entry.id,
                value: trimmed,
                createdAt: Calendar.current.startOfDay(for: selectedPRDate)
            )
            history[key] = entries
            saveHistoryMap(history)
            primaryCandidates = entries.map(\.value)
        } else {
            primaryCandidates = history[key, default: []].map(\.value) + [trimmed]
            saveHistoryValue(trimmed, for: key, date: selectedPRDate)
        }

        saveValue(bestValue(from: primaryCandidates, metadata: metadata) ?? trimmed, for: key)
    }

    private func resetExistingPREditing() {
        isEditingExistingPR = false
        editingHistoryEntryID = nil
    }

    private func currentPRHistoryEntry(for key: String, metadata: String) -> PRHistoryEntry? {
        guard let comparison = metricComparison(for: metadata) else { return nil }
        let candidates = historyEntries(for: key).compactMap { entry -> (PRHistoryEntry, Double)? in
            numericValue(entry.value, metadata: metadata).map { (entry, $0) }
        }
        return candidates.sorted { lhs, rhs in
            if lhs.1 == rhs.1 { return lhs.0.createdAt > rhs.0.createdAt }
            return comparison == .time ? lhs.1 < rhs.1 : lhs.1 > rhs.1
        }.first?.0
    }

    private func bestValue(from values: [String], metadata: String) -> String? {
        guard let comparison = metricComparison(for: metadata) else { return values.last }
        let candidates = values.compactMap { value -> (String, Double)? in
            numericValue(value, metadata: metadata).map { (value, $0) }
        }
        guard var best = candidates.first else { return values.last }
        for candidate in candidates.dropFirst() {
            if comparison == .time ? candidate.1 < best.1 : candidate.1 > best.1 {
                best = candidate
            }
        }
        return best.0
    }

    private func saveCurrentInput() {
        guard let move = selectedMove else { return }
        let trimmed = inputValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return
        }
        let metadata = move.name
        let shouldSave = shouldUpdatePrimary(trimmed, key: move.storageKey, metadata: metadata)
        saveHistoryValue(trimmed, for: move.storageKey, date: selectedPRDate)
        if shouldSave {
            saveValue(trimmed, for: move.storageKey)
        }
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

    private func historySheet(title: String, key: String, metadata: String) -> some View {
        let entries = historyEntries(for: key)
        let recordID = currentPRHistoryEntry(for: key, metadata: metadata)?.id
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
                                    if entry.id == recordID {
                                        Text("RECORDE")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.green)
                                    }
                                    Spacer()
                                    Text(entry.createdAt.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year().locale(Locale(identifier: "pt_BR"))))
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.45))
                                    Button {
                                        historyEntryPendingDeletion = entry
                                        showHistoryEntryDeletionAlert = true
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red.opacity(0.85))
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Excluir registro")
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
        .alert("Excluir registro", isPresented: $showHistoryEntryDeletionAlert) {
            Button("Cancelar", role: .cancel) { historyEntryPendingDeletion = nil }
            Button("Excluir", role: .destructive) {
                if let entry = historyEntryPendingDeletion {
                    deleteHistoryEntry(entry, for: key, metadata: metadata)
                }
                historyEntryPendingDeletion = nil
            }
        } message: {
            Text("Deseja excluir este registro do histórico? Esta ação não pode ser desfeita.")
        }
    }

    private func deleteHistoryEntry(_ entry: PRHistoryEntry, for key: String, metadata: String) {
        var history = loadHistoryMap()
        var entries = history[key, default: []]
        entries.removeAll { $0.id == entry.id }
        if entries.isEmpty {
            history.removeValue(forKey: key)
        } else {
            history[key] = entries
        }

        var values = loadMap()
        if let primary = bestValue(from: entries.map(\.value), metadata: metadata) {
            values[key] = primary
        } else {
            values.removeValue(forKey: key)
        }
        saveRecords(values: values, history: history, deletedHistoryEntryID: entry.id)
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
        if !normalized.contains("max cal") {
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
    private func addItemSheet() -> some View {
        ZStack {
            Theme.Colors.headerBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    Capsule()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 44, height: 5)
                        .padding(.top, 10)

                    Text("Novo item de Endurance")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 4)

                    Text("Crie um item e, se quiser, já informe seu resultado inicial.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.60))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 10) {
                    addItemField("Nome do item", placeholder: "Ex: Corrida 3 km", text: $newItemName)

                    addItemField("Resultado inicial (opcional)", placeholder: "Ex: 12:34 ou 500", text: $newItemValue)

                        if let message = addItemErrorMessage {
                            Text(message)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.yellow.opacity(0.85))
                        }
                    }
                    .padding(.horizontal, 16)

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
                                .frame(maxWidth: .infinity)
                                .primaryGreenActionButton()
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .padding(.bottom, 24)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func addItemField(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.75))

            TextField(placeholder, text: text)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled(true)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
    }

    private func addNewItem() {
        addItemErrorMessage = nil
        let cleanName = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else {
            addItemErrorMessage = "Informe o nome do item."
            return
        }

        let existingNames = allMoves.map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        guard !existingNames.contains(cleanName.lowercased()) else {
            addItemErrorMessage = "Este item já existe na sua lista."
            return
        }

        let id = UUID().uuidString
        let key = "custom_endurance_\(id)"
        let customItem = CustomEnduranceMove(id: id, name: cleanName, storageKey: key)
        var list = loadCustomItems()
        list.append(customItem)
        saveCustomItems(list)

        let item = EnduranceMove(name: customItem.name, storageKey: customItem.storageKey)
        let trimmedValue = newItemValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedValue.isEmpty {
            saveValue(trimmedValue, for: key)
            saveHistoryValue(trimmedValue, for: key, date: Date())
        }
        showAddItemSheet = false
    }

    private func deleteSelectedItem() {
        guard let item = selectedMove, item.storageKey.hasPrefix("custom_endurance_") else { return }
        removeValue(for: item.storageKey)
        removeHistory(for: item.storageKey)
        var list = loadCustomItems()
        list.removeAll { $0.storageKey == item.storageKey }
        saveCustomItems(list)
        selectedMove = nil
    }

    private func loadCustomItems() -> [CustomEnduranceMove] {
        guard !customEnduranceItemsData.isEmpty else { return [] }
        return (try? JSONDecoder().decode([CustomEnduranceMove].self, from: customEnduranceItemsData)) ?? []
    }

    private func saveCustomItems(_ list: [CustomEnduranceMove]) {
        customEnduranceItemsData = (try? JSONEncoder().encode(list)) ?? Data()
        PersonalRecordsSyncService.shared.didMutateLocalRecords()
    }

}

// MARK: - Persistência (JSON em Data)
private extension EndurancePersonalRecordsView {

    func loadMap() -> [String: String] {
        guard !enduranceValuesData.isEmpty else { return [:] }
        do {
            return try JSONDecoder().decode([String: String].self, from: enduranceValuesData)
        } catch {
            return [:]
        }
    }

    func saveMap(_ map: [String: String]) {
        do {
            enduranceValuesData = try JSONEncoder().encode(map)
        } catch {
            enduranceValuesData = Data()
        }
        PersonalRecordsSyncService.shared.didMutateLocalRecords()
    }



    private func loadHistoryMap() -> [String: [PRHistoryEntry]] {
        guard !enduranceHistoryData.isEmpty else { return [:] }
        do { return try JSONDecoder().decode([String: [PRHistoryEntry]].self, from: enduranceHistoryData) } catch { return [:] }
    }

    private func saveHistoryMap(_ map: [String: [PRHistoryEntry]]) {
        do { enduranceHistoryData = try JSONEncoder().encode(map) } catch { enduranceHistoryData = Data() }
        PersonalRecordsSyncService.shared.didMutateLocalRecords()
    }

    private func saveRecords(
        values: [String: String],
        history: [String: [PRHistoryEntry]],
        deletedHistoryEntryID: String? = nil
    ) {
        do {
            enduranceValuesData = try JSONEncoder().encode(values)
            enduranceHistoryData = try JSONEncoder().encode(history)
        } catch {
            enduranceValuesData = Data()
            enduranceHistoryData = Data()
        }
        if let deletedHistoryEntryID {
            PersonalRecordsSyncService.shared.didDeleteHistoryEntry(
                id: deletedHistoryEntryID,
                historyKey: "student_pr_endurance_history_v1"
            )
        } else {
            PersonalRecordsSyncService.shared.didMutateLocalRecords()
        }
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
}
