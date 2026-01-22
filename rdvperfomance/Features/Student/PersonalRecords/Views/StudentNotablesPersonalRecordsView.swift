import SwiftUI

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

    @State private var selectedMove: NotableMove?
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
                Text("Notables")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
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
        let displayValue = loadValue(for: move.storageKey)

        return Button {
            inputValue = displayValue ?? ""
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

                if let wod {
                    wodCard(wod)
                        .padding(.horizontal, 16)
                        .padding(.top, 2)
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

                Spacer()
            }
        }
        .presentationDetents([.large])
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

    private func saveCurrentInput(move: NotableMove) {
        let trimmed = inputValue
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            removeValue(for: move.storageKey)
            return
        }

        saveValue(trimmed, for: move.storageKey)
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

