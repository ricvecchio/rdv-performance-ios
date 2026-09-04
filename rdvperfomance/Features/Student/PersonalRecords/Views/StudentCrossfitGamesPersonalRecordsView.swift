import SwiftUI
import Charts

// Tela do Aluno: Recorde Pessoal > Crossfit Games (lista fixa por ano + PR de tempo)
struct StudentCrossfitGamesPersonalRecordsView: View {

    @Binding var path: [AppRoute]

    private let contentMaxWidth: CGFloat = 380

    private struct GamesWOD: Identifiable, Hashable {
        let id = UUID()
        let yearTitle: String
        let name: String
        let storageKey: String
        let descriptionLines: [String]
    }

    private struct GamesSection: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let items: [GamesWOD]
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

    private let sections: [GamesSection] = [
        .init(
            title: "CrossFit Games 2023 – Provas Individuais (Elite)",
            items: [
                .init(
                    yearTitle: "2023",
                    name: "Ride",
                    storageKey: "cfg_2023_ride",
                    descriptionLines: [
                        "Máximo de voltas em 40 min em bicicleta de montanha."
                    ]
                ),
                .init(
                    yearTitle: "2023",
                    name: "Pig Chipper",
                    storageKey: "cfg_2023_pig_chipper",
                    descriptionLines: [
                        "10 pig flips, 25 chest-to-bar pull-ups, 50 toes-to-bars, 100 wall-ball shots e reverso."
                    ]
                ),
                .init(
                    yearTitle: "2023",
                    name: "Inverted Medley",
                    storageKey: "cfg_2023_inverted_medley",
                    descriptionLines: [
                        "Sequência complexa de handstand walk, handstand push-ups e passos sobre obstáculos."
                    ]
                ),
                .init(
                    yearTitle: "2023",
                    name: "The Alpaca Redux",
                    storageKey: "cfg_2023_alpaca_redux",
                    descriptionLines: [
                        "Sled push e rounds com rope climbs, kettlebell clean & jerks e sled push progressivo."
                    ]
                ),
                .init(
                    yearTitle: "2023",
                    name: "Ski-Bag",
                    storageKey: "cfg_2023_ski_bag",
                    descriptionLines: [
                        "SkiErg e sandbag squats em sequência."
                    ]
                ),
                .init(
                    yearTitle: "2023",
                    name: "Helena",
                    storageKey: "cfg_2023_helena",
                    descriptionLines: [
                        "3 rounds:",
                        "• corrida 400 m",
                        "• 12 bar muscle-ups",
                        "• 21 dumbbell snatches"
                    ]
                ),
                .init(
                    yearTitle: "2023",
                    name: "Cross-Country 5K",
                    storageKey: "cfg_2023_cross_country_5k",
                    descriptionLines: [
                        "Corrida de 5 km para tempo."
                    ]
                ),
                .init(
                    yearTitle: "2023",
                    name: "Intervals",
                    storageKey: "cfg_2023_intervals",
                    descriptionLines: [
                        "Intervalos combinados de box jump-overs, remo e burpee box jump-overs."
                    ]
                ),
                .init(
                    yearTitle: "2023",
                    name: "Olympic Total",
                    storageKey: "cfg_2023_olympic_total",
                    descriptionLines: [
                        "Teste de força com 1RM Snatch e 1RM Clean & Jerk."
                    ]
                ),
                .init(
                    yearTitle: "2023",
                    name: "Muscle-Up Logs",
                    storageKey: "cfg_2023_muscle_up_logs",
                    descriptionLines: [
                        "5 rounds de muscle-ups e sandbag sobre logs."
                    ]
                ),
                .init(
                    yearTitle: "2023",
                    name: "Parallel-bar Pull",
                    storageKey: "cfg_2023_parallel_bar_pull",
                    descriptionLines: [
                        "8 rounds de travessia em paralelas + rope double-unders e sled pull."
                    ]
                ),
                .init(
                    yearTitle: "2023",
                    name: "Echo Thruster Final",
                    storageKey: "cfg_2023_echo_thruster_final",
                    descriptionLines: [
                        "21-18-15 de Echo Bike calorias com thrusters e overhead walking lunges."
                    ]
                )
            ]
        ),
        .init(
            title: "CrossFit Games 2024 – Provas Individuais (Elite)",
            items: [
                .init(
                    yearTitle: "2024",
                    name: "Lake Day (Run + Swim)",
                    storageKey: "cfg_2024_lake_day",
                    descriptionLines: [
                        "Corrida de 3.5 milhas seguida de natação 800 m antes de parte do dia ser cancelada."
                    ]
                ),
                .init(
                    yearTitle: "2024",
                    name: "Midline Climb",
                    storageKey: "cfg_2024_midline_climb",
                    descriptionLines: [
                        "Prova em ginásio com deadlifts, rope climbs, ski erg e GHD sit-ups."
                    ]
                ),
                .init(
                    yearTitle: "2024",
                    name: "Firestorm",
                    storageKey: "cfg_2024_firestorm",
                    descriptionLines: [
                        "Rounds de Echo-bike e burpees sobre barricada (parte da programação)."
                    ]
                ),
                .init(
                    yearTitle: "2024",
                    name: "Track & Field",
                    storageKey: "cfg_2024_track_field",
                    descriptionLines: [
                        "Corrida 1,600 m seguida por sprints e bag carries."
                    ]
                ),
                .init(
                    yearTitle: "2024",
                    name: "Chad",
                    storageKey: "cfg_2024_chad",
                    descriptionLines: [
                        "1,000 step-ups com peso."
                    ]
                ),
                .init(
                    yearTitle: "2024",
                    name: "Clean Ladder",
                    storageKey: "cfg_2024_clean_ladder",
                    descriptionLines: [
                        "Ladder de cleans em rounds progressivos."
                    ]
                ),
                .init(
                    yearTitle: "2024",
                    name: "Push Pull 2.0",
                    storageKey: "cfg_2024_push_pull_2",
                    descriptionLines: [
                        "Combinação de double-unders, chest-to-bar pull-ups e máximos no Echo-bike."
                    ]
                ),
                .init(
                    yearTitle: "2024",
                    name: "Dickies Triplet",
                    storageKey: "cfg_2024_dickies_triplet",
                    descriptionLines: [
                        "Sequência de run, toes-to-bars e dumbbell snatches (nome popularizado pela comunidade)."
                    ]
                ),
                .init(
                    yearTitle: "2024",
                    name: "Final 2421",
                    storageKey: "cfg_2024_final_2421",
                    descriptionLines: [
                        "Thrusters + chest-to-bar pull-ups + yoke carry."
                    ]
                ),
                .init(
                    yearTitle: "2024",
                    name: "Final 1815",
                    storageKey: "cfg_2024_final_1815",
                    descriptionLines: [
                        "Outra final combinada de thrusters e bar muscle-ups (muitas vezes agrupada com o Final 2421 nos resultados)."
                    ]
                )
            ]
        ),
        .init(
            title: "CrossFit Games 2025 – Provas Individuais (Elite)",
            items: [
                .init(
                    yearTitle: "2025",
                    name: "Run/Row/Run",
                    storageKey: "cfg_2025_run_row_run",
                    descriptionLines: [
                        "4-mile run → 3000 m row → 2-mile run (prova de resistência)."
                    ]
                ),
                .init(
                    yearTitle: "2025",
                    name: "All Crossed Up",
                    storageKey: "cfg_2025_all_crossed_up",
                    descriptionLines: [
                        "Sequência de wall walks, dumbbell shoulder-to-overhead, double-under crossovers e toes-to-bars para tempo."
                    ]
                ),
                .init(
                    yearTitle: "2025",
                    name: "Climbing Couplet",
                    storageKey: "cfg_2025_climbing_couplet",
                    descriptionLines: [
                        "4-3-2-1 reps pegboard + squat clean + front squat (prova combinada de força e técnica)."
                    ]
                ),
                .init(
                    yearTitle: "2025",
                    name: "Albany Grip Trip",
                    storageKey: "cfg_2025_albany_grip_trip",
                    descriptionLines: [
                        "5 rodadas de:",
                        "• 400 m corrida",
                        "• 12 deadlifts",
                        "• 100 ft handstand walk",
                        "(força, corrida e habilidades de equilíbrio)"
                    ]
                ),
                .init(
                    yearTitle: "2025",
                    name: "1RM Back Squat",
                    storageKey: "cfg_2025_1rm_back_squat",
                    descriptionLines: [
                        "Back squat máximo de uma repetição (teste de força absoluta)."
                    ]
                ),
                .init(
                    yearTitle: "2025",
                    name: "Throttle Up",
                    storageKey: "cfg_2025_throttle_up",
                    descriptionLines: [
                        "35 calorias Ski Erg → 28 chest-to-bar pull-ups → 24 burpee box jump-overs (prova para tempo)."
                    ]
                ),
                .init(
                    yearTitle: "2025",
                    name: "Hammer Down",
                    storageKey: "cfg_2025_hammer_down",
                    descriptionLines: [
                        "35 calorias no Echo Bike → 28 bar muscle-ups → 24 burpee box jump-overs (segundo teste consecutivo com pouco descanso)."
                    ]
                ),
                .init(
                    yearTitle: "2025",
                    name: "Going Dark",
                    storageKey: "cfg_2025_going_dark",
                    descriptionLines: [
                        "50/40 calorias no Echo Bike → 100 ft yoke carry → 30 deficit handstand push-ups → repetição (teste de resistência e força)."
                    ]
                ),
                .init(
                    yearTitle: "2025",
                    name: "Running Isabel",
                    storageKey: "cfg_2025_running_isabel",
                    descriptionLines: [
                        "5 rodadas de:",
                        "• 200 ft corrida",
                        "• 6 snatches (com barra)",
                        "Para tempo."
                    ]
                ),
                .init(
                    yearTitle: "2025",
                    name: "Atlas",
                    storageKey: "cfg_2025_atlas",
                    descriptionLines: [
                        "9/15/21 thrusters",
                        "3/5/7 rope climbs,",
                        "seguido de 100 ft overhead walking lunge (teste combinado de força, resistência e técnica)."
                    ]
                )
            ]
        )
    ]

    @AppStorage("student_pr_crossfit_games_values_v1")
    private var crossfitGamesValuesData: Data = Data()

    @AppStorage("student_pr_crossfit_games_history_v1")
    private var crossfitGamesHistoryData: Data = Data()

    @State private var selectedWod: GamesWOD? = nil
    @State private var inputValue: String = ""
    @State private var historyWod: GamesWOD?
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

                            Text("Adicione seu melhor tempo por prova.")
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
                Text("Crossfit Games")
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

    private func tableContainer() -> some View {
        VStack(spacing: 0) {

            tableHeader()

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)

            ForEach(Array(sections.enumerated()), id: \.element.id) { sectionIndex, section in

                sectionHeader(title: section.title)

                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 1)

                ForEach(Array(section.items.enumerated()), id: \.element.id) { itemIndex, wod in

                    tableRow(wod: wod)

                    let isLastItemInSection = itemIndex == section.items.count - 1
                    let isLastSection = sectionIndex == sections.count - 1

                    if !isLastItemInSection {
                        Rectangle()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 1)
                            .padding(.leading, 14)
                    } else if !isLastSection {
                        Rectangle()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 1)
                    }
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

            Text("PROVA")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.55))

            Spacer()

            Text("PR (tempo)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.55))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white.opacity(0.75))
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.04))
    }

    private func tableRow(wod: GamesWOD) -> some View {
        let stored = bestDisplayValue(for: wod.storageKey, metadata: wod.descriptionLines.joined(separator: " "))

        return Button {
            selectedWod = wod
        } label: {
            HStack(spacing: 10) {

                Image(systemName: "flame.fill")
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

    private func editSheet(for wod: GamesWOD) -> some View {
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

                // Bloco do WOD (card + ícone) com descrição formatada
                if !wod.descriptionLines.isEmpty {
                    wodCard(wod)
                        .padding(.horizontal, 16)
                        .padding(.top, 2)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Resultado:")
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

    /// Card visual do WOD dentro do modal (mesmo padrão do Notables) + descrição elegante (DE -> PARA)
    private func wodCard(_ wod: GamesWOD) -> some View {
        let description = prettyWodDescription(from: wod.descriptionLines)

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

    private func prettyWodDescription(from lines: [String]) -> String {
        let raw = lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")

        if raw.contains("•") {
            return raw
        }

        var mainPart = raw
        var parenthetical: String? = nil

        if let open = raw.lastIndex(of: "("),
           let close = raw.lastIndex(of: ")"),
           open < close {
            let afterOpen = raw.index(after: open)
            let inside = raw[afterOpen..<close].trimmingCharacters(in: .whitespacesAndNewlines)
            let before = raw[..<open].trimmingCharacters(in: .whitespacesAndNewlines)
            if !inside.isEmpty {
                parenthetical = "(\(inside))"
                mainPart = String(before)
            }
        }

        var text = mainPart
        text = text.replacingOccurrences(of: "→", with: "\n")
        text = text.replacingOccurrences(of: " + ", with: "\n")
        text = text.replacingOccurrences(of: "+", with: "\n")
        text = text.replacingOccurrences(of: " reps: ", with: " reps\n")
        text = text.replacingOccurrences(of: " reps ", with: " reps\n")

        var outLines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if let parenthetical, !parenthetical.isEmpty {
            outLines.append(parenthetical)
        }

        return outLines.joined(separator: "\n")
    }

    private func saveCurrentInput(for wod: GamesWOD) {
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

private extension StudentCrossfitGamesPersonalRecordsView {

    func loadMap() -> [String: String] {
        guard !crossfitGamesValuesData.isEmpty else { return [:] }
        do {
            return try JSONDecoder().decode([String: String].self, from: crossfitGamesValuesData)
        } catch {
            return [:]
        }
    }

    func saveMap(_ map: [String: String]) {
        do {
            crossfitGamesValuesData = try JSONEncoder().encode(map)
        } catch {
            crossfitGamesValuesData = Data()
        }
    }



    private func loadHistoryMap() -> [String: [PRHistoryEntry]] {
        guard !crossfitGamesHistoryData.isEmpty else { return [:] }
        do { return try JSONDecoder().decode([String: [PRHistoryEntry]].self, from: crossfitGamesHistoryData) } catch { return [:] }
    }

    private func saveHistoryMap(_ map: [String: [PRHistoryEntry]]) {
        do { crossfitGamesHistoryData = try JSONEncoder().encode(map) } catch { crossfitGamesHistoryData = Data() }
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
