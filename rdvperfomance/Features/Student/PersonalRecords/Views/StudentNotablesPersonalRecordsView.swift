import SwiftUI
import Charts

// Tela do Aluno: Recorde Pessoal > Notables (lista fixa + PR em texto)
struct StudentNotablesPersonalRecordsView: View {

    @Binding var path: [AppRoute]

    private let contentMaxWidth: CGFloat = 380

    private struct NotableMove: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let storageKey: String
    }

    /// Modelo para representar o WOD que será exibido no modal.
    private struct NotableWod: Hashable {
        let title: String
        let subtitle: String   // Ex: (For Time), (For Load), (Tabata)...
        let description: String // Texto completo (multilinhas)
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
    private let moves: [NotableMove] = [
        .init(name: "Black Jack", storageKey: "black_jack"),
        .init(name: "Bear Complex", storageKey: "bear_complex"),
        .init(name: "Broomstick Mile", storageKey: "broomstick_mile"),
        .init(name: "Circus", storageKey: "circus"),
        .init(name: "Crossfit Total", storageKey: "crossfit_total"),
        .init(name: "Death by Pull-Ups", storageKey: "death_by_pull_ups"),
        .init(name: "Fat Amy", storageKey: "fat_amy"),
        .init(name: "Fight Gone Bad", storageKey: "fight_gone_bad"),
        .init(name: "Filthy Fifty", storageKey: "filthy_fifty"),
        .init(name: "Hope", storageKey: "hope"),
        .init(name: "Iron Triathlon", storageKey: "iron_triathlon"),
        .init(name: "Jeremy", storageKey: "jeremy"),
        .init(name: "King Kong", storageKey: "king_kong"),

        // ✅ Corrigido nome (mantive storageKey igual para não perder PR salvo)
        .init(name: "Nasty Girls", storageKey: "nasty_gilrs"),

        .init(name: "Tabata Something Else", storageKey: "tabata_something_else"),
        .init(name: "Tabata This", storageKey: "tabata_this"),
        .init(name: "The 300", storageKey: "the_300"),
        .init(name: "The Chief", storageKey: "the_chief")
    ]

    // ✅ “Banco” local de WODs (por storageKey)
    private let wodsByKey: [String: NotableWod] = [
        "black_jack": .init(
            title: "Black Jack",
            subtitle: "(For Time)",
            description:
"""
20 Deadlifts (61/43 kg)
20 Box Jumps (61/51 cm)
20 Kettlebell Swings (24/16 kg)
20 Burpees
20 Wall Balls (9/6 kg)
20 Push Press (43/30 kg)
20 Double-unders
"""
        ),

        "bear_complex": .init(
            title: "Bear Complex",
            subtitle: "(For Load)",
            description:
"""
7 Rounds (sem soltar a barra):
Cada round:
- Power Clean
- Front Squat
- Push Press
- Back Squat
- Push Press

Aumente a carga a cada round.
"""
        ),

        "broomstick_mile": .init(
            title: "Broomstick Mile",
            subtitle: "(For Time)",
            description:
"""
1 Mile Run
Segurando um PVC / vassoura acima da cabeça o tempo todo.
"""
        ),

        "circus": .init(
            title: "Circus",
            subtitle: "(3 Rounds For Time)",
            description:
"""
5 Muscle-ups
10 Front Squats (61/43 kg)
15 Ring Dips
20 Double-unders
"""
        ),

        "crossfit_total": .init(
            title: "CrossFit Total",
            subtitle: "(For Load)",
            description:
"""
1RM Back Squat
1RM Shoulder Press
1RM Deadlift

Score = Soma dos três máximos.
"""
        ),

        "death_by_pull_ups": .init(
            title: "Death by Pull-Ups",
            subtitle: "(EMOM Progressivo)",
            description:
"""
Minuto 1: 1 Pull-up
Minuto 2: 2 Pull-ups

Continue adicionando 1 repetição por minuto até falhar.
"""
        ),

        "fat_amy": .init(
            title: "Fat Amy",
            subtitle: "(For Time)",
            description:
"""
50-40-30-20-10
- Thrusters (43/30 kg)
- Pull-ups
"""
        ),

        "fight_gone_bad": .init(
            title: "Fight Gone Bad",
            subtitle: "(3 Rounds — 1 min por estação)",
            description:
"""
Wall Ball (9/6 kg)
Sumo Deadlift High Pull (34/25 kg)
Box Jump (51/41 cm)
Push Press (34/25 kg)
Row (calorias)

Descanso: 1 min entre rounds
Score = Total de reps/calorias
"""
        ),

        "filthy_fifty": .init(
            title: "Filthy Fifty",
            subtitle: "(For Time)",
            description:
"""
50 Box Jumps (61/51 cm)
50 Jumping Pull-ups
50 Kettlebell Swings (24/16 kg)
50 Walking Lunges
50 Knees-to-Elbows
50 Push Press (20/15 kg)
50 Back Extensions
50 Wall Balls (9/6 kg)
50 Burpees
50 Double-unders
"""
        ),

        "hope": .init(
            title: "Hope",
            subtitle: "(3 Rounds — 1 min por estação)",
            description:
"""
Burpees
Power Snatch (34/25 kg)
Box Jump (51/41 cm)
Thrusters (34/25 kg)
Chest-to-Bar Pull-ups

Score = Total de reps
(1 min descanso entre rounds)
"""
        ),

        "iron_triathlon": .init(
            title: "Iron Triathlon",
            subtitle: "(For Time)",
            description:
"""
20 Deadlifts (102/70 kg)
20 Hang Power Cleans (61/43 kg)
20 Push Jerks (61/43 kg)
"""
        ),

        "jeremy": .init(
            title: "Jeremy",
            subtitle: "(For Time)",
            description:
"""
21-15-9
- Overhead Squats (43/30 kg)
- Pull-ups
"""
        ),

        "king_kong": .init(
            title: "King Kong",
            subtitle: "(For Time)",
            description:
"""
3 Rounds:
1 Deadlift (206/147 kg)
2 Muscle-ups
3 Squat Cleans (113/79 kg)
4 Handstand Push-ups
"""
        ),

        "nasty_gilrs": .init(
            title: "Nasty Girls",
            subtitle: "(3 Rounds For Time)",
            description:
"""
50 Air Squats
7 Muscle-ups
10 Hang Power Cleans (61/43 kg)
"""
        ),

        "tabata_something_else": .init(
            title: "Tabata Something Else",
            subtitle: "(Tabata)",
            description:
"""
20s ON / 10s OFF — 8 Rounds por movimento:
- Pull-ups
- Push-ups
- Sit-ups
- Air Squats

Score = Menor número de reps em qualquer intervalo.
"""
        ),

        "tabata_this": .init(
            title: "Tabata This",
            subtitle: "(Tabata)",
            description:
"""
20s ON / 10s OFF — 8 Rounds cada:
- Air Squats
- Push-ups
- Sit-ups
- Pull-ups

Score = Soma das menores séries de cada exercício.
"""
        ),

        "the_300": .init(
            title: "The 300",
            subtitle: "(For Time)",
            description:
"""
25 Pull-ups
50 Deadlifts (61/43 kg)
50 Push-ups
50 Box Jumps (61/51 cm)
50 Floor Wipers (61/43 kg)
50 Kettlebell Swings (24/16 kg)
25 Pull-ups
"""
        ),

        "the_chief": .init(
            title: "The Chief",
            subtitle: "(5 Rounds — AMRAP 3 min)",
            description:
"""
Em cada round (3 min):
3 Power Cleans (61/43 kg)
6 Push-ups
9 Air Squats

Descanso: 1 min entre rounds.
"""
        )
    ]

    // Persistência simples (UserDefaults via AppStorage)
    @AppStorage("student_pr_notables_values_v1")
    private var notablesValuesData: Data = Data()

    @AppStorage("student_pr_notables_history_v1")
    private var notablesHistoryData: Data = Data()

    @State private var selectedMove: NotableMove?
    @State private var inputValue: String = ""
    @State private var historyMove: NotableMove?
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

                            Text("Adicione seu melhor resultado por item.")
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
        .blur(radius: (selectedMove != nil || historyMove != nil || showPRDatePicker) ? 4 : 0)
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
                Text("Notables")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .topBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(item: $selectedMove) { move in
            editSheet(move: move)
        }
    }

    // MARK: - Tabela
    private func tableContainer() -> some View {
        VStack(spacing: 0) {

            tableHeader()

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)

            let list = moves

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

            Text("Benchmark")
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

    private func tableRow(move: NotableMove) -> some View {
        let displayValue = bestDisplayValue(for: move.storageKey, metadata: wodsByKey[move.storageKey]?.subtitle ?? "")

        return Button {
            inputValue = bestDisplayValue(for: move.storageKey, metadata: wodsByKey[move.storageKey]?.subtitle ?? "") ?? ""
            selectedPRDate = Date()
            selectedMove = move
        } label: {
            HStack(spacing: 10) {

                Image(systemName: "bolt.fill")
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
    private func editSheet(move: NotableMove) -> some View {
        let wod: NotableWod? = wodsByKey[move.storageKey]

        return ZStack {
            Theme.Colors.headerBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {

                Capsule()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 44, height: 5)
                    .padding(.top, 10)

                Text(move.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 4)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                    Text("Informe seu melhor resultado. Para remover, deixe vazio.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.60))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)

                    if let wod {
                        wodCard(wod)
                            .padding(.horizontal, 16)
                            .padding(.top, 2)
                            .layoutPriority(1)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Resultado:")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))

                        TextField("Ex: 7:32 ou 210 reps ou 450 pts", text: $inputValue)
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

                    dateAndHistorySection(key: move.storageKey, metadata: wodsByKey[move.storageKey]?.subtitle ?? "", historyAction: {
                        historyMove = move
                    })
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .sheet(item: $historyMove) { selected in
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

                    }
                }

                HStack(spacing: 12) {

                    Button {
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
                        saveCurrentInput(move: move)
                        selectedMove = nil
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
                .padding(.bottom, 16)
            }
        }
        .presentationDetents([.fraction(0.80)])
        .onAppear {
            inputValue = bestDisplayValue(for: move.storageKey, metadata: wodsByKey[move.storageKey]?.subtitle ?? "") ?? ""
            selectedPRDate = Date()
        }
    }

    /// Card visual do WOD dentro do modal
    private func wodCard(_ wod: NotableWod) -> some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundColor(.green.opacity(0.90))

                VStack(alignment: .leading, spacing: 2) {
                    Text("WOD")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.60))

                    Text("\(wod.title) \(wod.subtitle)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.92))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                Spacer()
            }

            ScrollView {
                Text(wod.description)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.78))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
            }
            .frame(height: 140)
        }
        .padding(14)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func saveCurrentInput(move: NotableMove) {
        guard let move = selectedMove else { return }
        let trimmed = inputValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            removeValue(for: move.storageKey)
            return
        }
        let metadata = wodsByKey[move.storageKey]?.subtitle ?? ""
        let shouldSave = shouldUpdatePrimary(trimmed, key: move.storageKey, metadata: metadata)
        saveHistoryValue(trimmed, for: move.storageKey, date: selectedPRDate)
        if shouldSave {
            saveValue(trimmed, for: move.storageKey)
        }
    }


    @ViewBuilder
    private func dateAndHistorySection(key: String, metadata: String, historyAction: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
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
private extension StudentNotablesPersonalRecordsView {

    func loadMap() -> [String: String] {
        guard !notablesValuesData.isEmpty else { return [:] }
        do {
            return try JSONDecoder().decode([String: String].self, from: notablesValuesData)
        } catch {
            return [:]
        }
    }

    func saveMap(_ map: [String: String]) {
        do {
            notablesValuesData = try JSONEncoder().encode(map)
        } catch {
            notablesValuesData = Data()
        }
        PersonalRecordsSyncService.shared.didMutateLocalRecords()
    }



    private func loadHistoryMap() -> [String: [PRHistoryEntry]] {
        guard !notablesHistoryData.isEmpty else { return [:] }
        do { return try JSONDecoder().decode([String: [PRHistoryEntry]].self, from: notablesHistoryData) } catch { return [:] }
    }

    private func saveHistoryMap(_ map: [String: [PRHistoryEntry]]) {
        do { notablesHistoryData = try JSONEncoder().encode(map) } catch { notablesHistoryData = Data() }
        PersonalRecordsSyncService.shared.didMutateLocalRecords()
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
