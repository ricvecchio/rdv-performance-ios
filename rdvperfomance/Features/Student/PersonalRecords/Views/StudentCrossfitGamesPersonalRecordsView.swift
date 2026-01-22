import SwiftUI

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

    @State private var selectedWod: GamesWOD? = nil
    @State private var inputValue: String = ""

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
                Text("Crossfit Games")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
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
        let stored = loadValue(for: wod.storageKey)

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
        .presentationDetents([.large])
        .onAppear {
            inputValue = loadValue(for: wod.storageKey) ?? ""
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
        let trimmed = inputValue.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            removeValue(for: wod.storageKey)
            return
        }

        saveValue(trimmed, for: wod.storageKey)
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

