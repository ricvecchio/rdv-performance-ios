import SwiftUI
import Charts

// Tela do Aluno: Recorde Pessoal > Campeonatos (lista fixa + PR em texto)
struct StudentCampeonatosPersonalRecordsView: View {

    @Binding var path: [AppRoute]

    private let contentMaxWidth: CGFloat = 380

    private struct CampeonatoWOD: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let storageKey: String
        let descriptionLines: [String]
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
    private let wods: [CampeonatoWOD] = [
        .init(
            name: "TCB : ORGULHO",
            storageKey: "champ_tcb_orgulho",
            descriptionLines: [
                "3 séries de:",
                "• 5/7 ring muscle ups",
                "• 14 bar facing burpees",
                "• 28 DB squats",
                "Time cap: 9’"
            ]
        ),
        .init(
            name: "TCB: CONFIANÇA",
            storageKey: "champ_tcb_confianca",
            descriptionLines: [
                "4RM de thruster",
                "Time cap: 4’"
            ]
        ),
        .init(
            name: "TCB: POPEYE",
            storageKey: "champ_tcb_popeye",
            descriptionLines: [
                "Por tempo:",
                "• 40 double unders",
                "• 40 box jumps",
                "• 40 double unders",
                "• 30 fat bar deadlift",
                "• 40 double unders",
                "• 20 snatches",
                "• 40 double unders",
                "• 30 chest to bar",
                "• 2/3 legless rope climb",
                "Time cap: 11’"
            ]
        ),
        .init(
            name: "TCB: MÃOS AO ALTO",
            storageKey: "champ_tcb_maos_ao_alto",
            descriptionLines: [
                "Por tempo:",
                "• Buy-in: 50 wall balls",
                "• 3 séries de: 15 cleans, 10 shoulder to overhead, 5 overhead squats",
                "• Buy-out: 50 wall balls",
                "Time cap: 13’"
            ]
        ),
        .init(
            name: "TCB: VAI OU RACHA",
            storageKey: "champ_tcb_vai_ou_racha",
            descriptionLines: [
                "Por tempo:",
                "• 7/10 bar muscle ups",
                "• 15/20 strict HSPU",
                "• 30 toes to bar",
                "• 50 pistols",
                "• (reverso dos movimentos)",
                "Time cap: 10’"
            ]
        ),
        .init(
            name: "Copa Sur: Chipper 22",
            storageKey: "champ_copasur_chipper_22",
            descriptionLines: [
                "For time:",
                "• 50 wall-ball shots",
                "• 50 chest-to-bar pull-ups",
                "• 100 double-unders",
                "• 50 deadlifts",
                "Time cap: 12’"
            ]
        ),
        .init(
            name: "Copa Sur: Run Swim Run",
            storageKey: "champ_copasur_run_swim_run",
            descriptionLines: [
                "For time: 2,000-m run – 500-m swim – 2,000-m run",
                "Time cap: 40’"
            ]
        ),
        .init(
            name: "Copa Sur: Barbell Complex",
            storageKey: "champ_copasur_barbell_complex",
            descriptionLines: [
                "3 cleans + 2 front squats + 1 jerk (max load attempts)"
            ]
        ),
        .init(
            name: "Copa Sur: 2014 Regional Event 5",
            storageKey: "champ_copasur_2014_regional_event_5",
            descriptionLines: [
                "10 rounds: 1 legless rope climb, short run",
                "Time cap: ~11’"
            ]
        ),
        .init(
            name: "Copa Sur: Too Many Rings",
            storageKey: "champ_copasur_too_many_rings",
            descriptionLines: [
                "For time: 100 thrusters + intervals of ring muscle-ups"
            ]
        ),
        .init(
            name: "Copa Sur: Last One Standing 22",
            storageKey: "champ_copasur_last_one_standing_22",
            descriptionLines: [
                "Parte I e Parte II combinadas para eliminação progressiva",
                "Time caps específicos por parte"
            ]
        ),
        .init(
            name: "MURALHA GAMES 2026 - PROVA 1",
            storageKey: "champ_muralha_games_2026_prova_1",
            descriptionLines: [
                "AMRAP 7'",
                "• 15 THRUSTERS (115/85) (95/65) (75/45)",
                "• 15 BJO / BJO / STEP UP",
                "• 15 PULL UP"
            ]
        ),
        .init(
            name: "MURALHA GAMES 2026 - PROVA 2",
            storageKey: "champ_muralha_games_2026_prova_2",
            descriptionLines: [
                "FOR TIME - 12'",
                "21/15/9",
                "• CLEAN AND JERK (135/95) (115/85) (95/65)",
                "• BMU/C2B // C2B/PULL UP // PULL UP // RING ROW"
            ]
        ),
        .init(
            name: "MURALHA GAMES 2026 - PROVA 3",
            storageKey: "champ_muralha_games_2026_prova_3",
            descriptionLines: [
                "5 ROUNDS FOR TIME",
                "TIME CAP: 20'",
                "• 12 SNATCH (115/85)",
                "• 15 HSPU",
                "• 20 BOB SINCRO",
                "• 60 DOUBLE UNDER"
            ]
        )
    ]

    // Persistência simples (UserDefaults via AppStorage) — armazenando PR como texto (ex: 12:34)
    @AppStorage("student_pr_campeonatos_values_v1")
    private var campeonatosValuesData: Data = Data()

    @AppStorage("student_pr_campeonatos_history_v1")
    private var campeonatosHistoryData: Data = Data()

    @State private var selectedWod: CampeonatoWOD? = nil
    @State private var inputValue: String = ""
    @State private var historyWod: CampeonatoWOD?
    @State private var selectedPRDate: Date = Date()
    @State private var showPRDatePicker: Bool = false

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

                            Text("Adicione seu melhor resultado por prova.")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.55))

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
        .blur(radius: (selectedWod != nil || historyWod != nil || showPRDatePicker) ? 4 : 0)
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
                Text("Campeonatos")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .topBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(item: $selectedWod) { wod in
            editSheet(for: wod)
        }
    }

    // MARK: - Tabela
    private func tableContainer() -> some View {
        VStack(spacing: 0) {

            tableHeader()

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)

            let list = wods

            ForEach(Array(list.enumerated()), id: \.element.id) { index, wod in

                tableRow(wod: wod)

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

            Text("Prova")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.55))

            Spacer()

            Text("Resultado:")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.55))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func tableRow(wod: CampeonatoWOD) -> some View {
        let stored = bestDisplayValue(for: wod.storageKey, metadata: wod.descriptionLines.joined(separator: " "))

        return Button {
            selectedWod = wod
        } label: {
            HStack(spacing: 10) {

                Image(systemName: "trophy.fill")
                    .foregroundColor(.green.opacity(0.85))
                    .font(.system(size: 15))
                    .frame(width: 26)

                Text(wod.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer()

                if let stored, !stored.isEmpty {
                    Text(stored)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.88))
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
    private func editSheet(for wod: CampeonatoWOD) -> some View {
        ZStack {
            Theme.Colors.headerBackground
                .ignoresSafeArea()

            VStack(spacing: 14) {

                Capsule()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 44, height: 5)
                    .padding(.top, 10)

                Text(wod.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 4)

                // ✅ Bloco do WOD no mesmo padrão do Notables (card + ícone)
                if !wod.descriptionLines.isEmpty {
                    wodCard(wod)
                        .padding(.horizontal, 16)
                        .padding(.top, 2)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("PR (tempo)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))

                    TextField("Ex: 12:34", text: $inputValue)
                        .keyboardType(.numbersAndPunctuation)
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

                dateAndHistorySection(key: wod.storageKey, metadata: wod.descriptionLines.joined(separator: " "), historyAction: {
                    historyWod = wod
                })
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .sheet(item: $historyWod) { selected in
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
                        selectedWod = nil
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
                        saveCurrentInput(for: wod)
                        selectedWod = nil
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
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)

                Spacer()
            }
        }
        .presentationDetents([.fraction(0.75)])
        .onAppear {
            inputValue = bestDisplayValue(for: wod.storageKey, metadata: wod.descriptionLines.joined(separator: " ")) ?? ""
            selectedPRDate = Date()
        }
    }

    /// Card visual do WOD dentro do modal (mesmo padrão do Notables)
    private func wodCard(_ wod: CampeonatoWOD) -> some View {
        let description = wod.descriptionLines.joined(separator: "\n")

        return VStack(alignment: .leading, spacing: 10) {

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundColor(.green.opacity(0.90))

                VStack(alignment: .leading, spacing: 2) {
                    Text("WOD")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.60))

                    Text(wod.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.92))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                Spacer()
            }

            ScrollView {
                Text(description)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.78))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
            }
            .frame(maxHeight: 140)
        }
        .padding(14)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func saveCurrentInput(for wod: CampeonatoWOD) {
        guard let wod = selectedWod else { return }
        let trimmed = inputValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            removeValue(for: wod.storageKey)
            return
        }
        let metadata = wod.descriptionLines.joined(separator: " ")
        let shouldSave = shouldUpdatePrimary(trimmed, key: wod.storageKey, metadata: metadata)
        saveHistoryValue(trimmed, for: wod.storageKey, date: selectedPRDate)
        if shouldSave {
            saveValue(trimmed, for: wod.storageKey)
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
        if normalized.contains("max reps") || normalized.contains("max height") || normalized.contains("max distance") || normalized.contains("1 rep max") || normalized.contains("1rm") || normalized.contains("4rm") || normalized.contains("max hold") || normalized.contains("amrap") || normalized.contains("for load") || normalized.contains("max") || normalized.contains("reps") || normalized.contains("score") || normalized.contains("load") {
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

// MARK: - Persistência (JSON em Data) — [String: String]
private extension StudentCampeonatosPersonalRecordsView {

    func loadMap() -> [String: String] {
        guard !campeonatosValuesData.isEmpty else { return [:] }
        do {
            return try JSONDecoder().decode([String: String].self, from: campeonatosValuesData)
        } catch {
            return [:]
        }
    }

    func saveMap(_ map: [String: String]) {
        do {
            campeonatosValuesData = try JSONEncoder().encode(map)
        } catch {
            campeonatosValuesData = Data()
        }
    }



    private func loadHistoryMap() -> [String: [PRHistoryEntry]] {
        guard !campeonatosHistoryData.isEmpty else { return [:] }
        do { return try JSONDecoder().decode([String: [PRHistoryEntry]].self, from: campeonatosHistoryData) } catch { return [:] }
    }

    private func saveHistoryMap(_ map: [String: [PRHistoryEntry]]) {
        do { campeonatosHistoryData = try JSONEncoder().encode(map) } catch { campeonatosHistoryData = Data() }
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
