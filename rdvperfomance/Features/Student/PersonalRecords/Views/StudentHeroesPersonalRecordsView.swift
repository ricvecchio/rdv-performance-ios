import SwiftUI

// Tela do Aluno: Recorde Pessoal > The Heroes (lista fixa de Hero WODs + PR de tempo)
struct StudentHeroesPersonalRecordsView: View {

    @Binding var path: [AppRoute]

    private let contentMaxWidth: CGFloat = 380

    private struct HeroWOD: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let storageKey: String
        let descriptionLines: [String]
    }

    // ✅ Dados fixos conforme solicitado
    private let wods: [HeroWOD] = [
        .init(
            name: "Abbate",
            storageKey: "hero_abbate",
            descriptionLines: [
                "Para tempo:",
                "• 40 Deadlifts (225/155 lb)",
                "• 30 Box Jumps (24/20\")",
                "• 20 Power Cleans (135/95 lb)",
                "• 10 Bar Muscle-Ups"
            ]
        ),
        .init(
            name: "Adam Brown",
            storageKey: "hero_adam_brown",
            descriptionLines: [
                "Para tempo:",
                "• 2 mile Run",
                "• 25 Pull-ups",
                "• 50 Sit-ups",
                "• 100 Air Squats",
                "• 25 Pull-ups",
                "• 2 mile Run"
            ]
        ),
        .init(
            name: "Adrian",
            storageKey: "hero_adrian",
            descriptionLines: [
                "7 rounds:",
                "• 3 Rope Climbs (15 ft)",
                "• 5 Deadlifts (315/225 lb)",
                "• 7 Box Jumps (24/20\")"
            ]
        ),
        .init(
            name: "Alexander",
            storageKey: "hero_alexander",
            descriptionLines: [
                "5 rounds:",
                "• 31 Back Squats (135/95 lb)",
                "• 12 Power Cleans (185/135 lb)",
                "• 5 Ring Muscle-Ups"
            ]
        ),
        .init(
            name: "Andy",
            storageKey: "hero_andy",
            descriptionLines: [
                "Para tempo:",
                "• 100 Pull-ups",
                "• 100 Push-ups",
                "• 100 Sit-ups",
                "• 100 Air Squats",
                "• 1 mile Run"
            ]
        ),
        .init(
            name: "Bert",
            storageKey: "hero_bert",
            descriptionLines: [
                "Para tempo:",
                "• 50 Burpees",
                "• 400 m Run",
                "• 100 Push-ups",
                "• 400 m Run",
                "• 150 Walking Lunges",
                "• 400 m Run",
                "• 200 Air Squats",
                "• 400 m Run",
                "• 300 Sit-ups",
                "• 400 m Run",
                "• 400 m Bear Crawl"
            ]
        ),
        .init(
            name: "Big Sexy",
            storageKey: "hero_big_sexy",
            descriptionLines: [
                "5 rounds:",
                "• 10 Deadlifts (275/185 lb)",
                "• 10 Hang Power Cleans (185/125 lb)",
                "• 10 Front Squats (185/125 lb)",
                "• 10 Push Jerks (185/125 lb)",
                "• 10 Back Squats (185/125 lb)"
            ]
        ),
        .init(
            name: "Blake",
            storageKey: "hero_blake",
            descriptionLines: [
                "4 rounds:",
                "• 100 ft Walking Lunge (45/35 lb plate overhead)",
                "• 30 Box Jumps (24/20\")",
                "• 20 Wall Balls (20/14 lb)",
                "• 10 Handstand Push-ups"
            ]
        ),
        .init(
            name: "Bowen",
            storageKey: "hero_bowen",
            descriptionLines: [
                "3 rounds:",
                "• 800 m Run",
                "• 7 Deadlifts (275/185 lb)",
                "• 10 Burpees",
                "• 14 Pull-ups"
            ]
        ),
        .init(
            name: "Bradley",
            storageKey: "hero_bradley",
            descriptionLines: [
                "10 rounds:",
                "• 100 m Sprint",
                "• 10 Pull-ups",
                "• 10 Burpees"
            ]
        ),
        .init(
            name: "Bradshaw",
            storageKey: "hero_bradshaw",
            descriptionLines: [
                "10 rounds:",
                "• 3 Deadlifts (225/155 lb)",
                "• 6 Handstand Push-ups",
                "• 12 Pull-ups",
                "• 24 Double-Unders"
            ]
        ),
        .init(
            name: "Brehm",
            storageKey: "hero_brehm",
            descriptionLines: [
                "Para tempo:",
                "• 10 Rope Climbs (15 ft)",
                "• 20 Back Squats (225/155 lb)",
                "• 30 Handstand Push-ups",
                "• 40 Cal Row"
            ]
        ),
        .init(
            name: "Brian",
            storageKey: "hero_brian",
            descriptionLines: [
                "3 rounds:",
                "• 5 Rope Climbs",
                "• 25 Back Squats (185/125 lb)",
                "• 50 Double-Unders"
            ]
        ),
        .init(
            name: "Bruck",
            storageKey: "hero_bruck",
            descriptionLines: [
                "4 rounds:",
                "• 400 m Run",
                "• 24 Back Squats (185/125 lb)",
                "• 24 Handstand Push-ups"
            ]
        ),
        .init(
            name: "Bulger",
            storageKey: "hero_bulger",
            descriptionLines: [
                "10 rounds:",
                "• 150 m Run",
                "• 7 Chest-to-Bar Pull-ups",
                "• 7 Front Squats (135/95 lb)",
                "• 7 Handstand Push-ups"
            ]
        ),
        .init(
            name: "Bull",
            storageKey: "hero_bull",
            descriptionLines: [
                "2 rounds:",
                "• 200 Double-Unders",
                "• 50 Overhead Squats (135/95 lb)",
                "• 50 Pull-ups",
                "• 1 mile Run"
            ]
        ),
        .init(
            name: "Cameron",
            storageKey: "hero_cameron",
            descriptionLines: [
                "Para tempo:",
                "• 50 Walking Lunges",
                "• 25 Chest-to-Bar Pull-ups",
                "• 50 Box Jumps (24/20\")",
                "• 25 Toes-to-Bar",
                "• 50 Wall Balls (20/14 lb)"
            ]
        ),
        .init(
            name: "Capoot",
            storageKey: "hero_capoot",
            descriptionLines: [
                "Para tempo:",
                "• 100 Push-ups",
                "• 800 m Run",
                "• 75 Push-ups",
                "• 1200 m Run",
                "• 50 Push-ups",
                "• 1600 m Run",
                "• 25 Push-ups"
            ]
        ),
        .init(
            name: "Carse",
            storageKey: "hero_carse",
            descriptionLines: [
                "Para tempo:",
                "• 21 Thrusters (95/65 lb)",
                "• 18 Deadlifts (155/105 lb)",
                "• 15 Burpees",
                "• 12 Cleans (185/125 lb)",
                "• 9 Box Jumps"
            ]
        ),
        .init(
            name: "Chad",
            storageKey: "hero_chad",
            descriptionLines: [
                "Para tempo:",
                "• 1000 Box Step-Ups (20\") com mochila (45/35 lb)"
            ]
        ),
        .init(
            name: "Coe",
            storageKey: "hero_coe",
            descriptionLines: [
                "10 rounds:",
                "• 10 Deadlifts (225/155 lb)",
                "• 10 Push-ups",
                "• 10 Box Jumps (24/20\")"
            ]
        ),
        .init(
            name: "Coffey",
            storageKey: "hero_coffey",
            descriptionLines: [
                "5 rounds:",
                "• 800 m Run",
                "• 20 Back Squats (135/95 lb)",
                "• 20 Push-ups"
            ]
        ),
        .init(
            name: "Garrett",
            storageKey: "hero_garrett",
            descriptionLines: [
                "3 rounds:",
                "• 75 Air Squats",
                "• 25 Ring Handstand Push-ups",
                "• 25 L-Sit Pull-ups"
            ]
        ),
        .init(
            name: "Gator",
            storageKey: "hero_gator",
            descriptionLines: [
                "8 rounds:",
                "• 5 Front Squats (185/135 lb)",
                "• 26 Ring Push-ups"
            ]
        ),
        .init(
            name: "Gaza",
            storageKey: "hero_gaza",
            descriptionLines: [
                "5 rounds:",
                "• 35 Kettlebell Swings (53/35 lb)",
                "• 30 Push-ups",
                "• 25 Pull-ups"
            ]
        ),
        .init(
            name: "Glen",
            storageKey: "hero_glen",
            descriptionLines: [
                "Para tempo:",
                "• 30 Clean & Jerks (135/95 lb)",
                "• 1 mile Run",
                "• 10 Rope Climbs",
                "• 1 mile Run",
                "• 100 Burpees"
            ]
        ),
        .init(
            name: "Griff",
            storageKey: "hero_griff",
            descriptionLines: [
                "Para tempo:",
                "• 800 m Run",
                "• 400 m Run (backwards)",
                "• 800 m Run",
                "• 400 m Run (backwards)"
            ]
        ),
        .init(
            name: "Hall",
            storageKey: "hero_hall",
            descriptionLines: [
                "5 rounds:",
                "• 3 Clean & Jerks (225/155 lb)",
                "• 200 m Sprint",
                "• 20 Kettlebell Swings (53/35 lb)"
            ]
        ),
        .init(
            name: "Hamilton",
            storageKey: "hero_hamilton",
            descriptionLines: [
                "3 rounds:",
                "• 1000 m Row",
                "• 50 Push-ups",
                "• 1000 m Run",
                "• 50 Pull-ups"
            ]
        ),
        .init(
            name: "Hammer",
            storageKey: "hero_hammer",
            descriptionLines: [
                "5 rounds:",
                "• 5 Power Cleans (185/135 lb)",
                "• 10 Front Squats (185/135 lb)",
                "• 5 Jerks (185/135 lb)",
                "• 20 Pull-ups"
            ]
        ),
        .init(
            name: "Hansen",
            storageKey: "hero_hansen",
            descriptionLines: [
                "5 rounds:",
                "• 30 Kettlebell Swings (53/35 lb)",
                "• 30 Burpees",
                "• 30 GHD Sit-ups"
            ]
        ),
        .init(
            name: "Murph",
            storageKey: "hero_murph",
            descriptionLines: [
                "Para tempo (com colete 20/14 lb):",
                "• 1 mile Run",
                "• 100 Pull-ups",
                "• 200 Push-ups",
                "• 300 Air Squats",
                "• 1 mile Run"
            ]
        ),
        .init(
            name: "JT",
            storageKey: "hero_jt",
            descriptionLines: [
                "21-15-9:",
                "• Handstand Push-ups",
                "• Ring Dips",
                "• Push-ups"
            ]
        ),
        .init(
            name: "Michael",
            storageKey: "hero_michael",
            descriptionLines: [
                "3 rounds:",
                "• 800 m Run",
                "• 50 Back Extensions",
                "• 50 Sit-ups"
            ]
        ),
        .init(
            name: "Sisson",
            storageKey: "hero_sisson",
            descriptionLines: [
                "8 rounds:",
                "• 600 m Run",
                "• 5 Weighted Pull-ups",
                "• 20 Walking Lunges (45/35 lb)",
                "• 15 Thrusters (135/95 lb)"
            ]
        ),
        .init(
            name: "Randy",
            storageKey: "hero_randy",
            descriptionLines: [
                "Para tempo:",
                "• 75 Power Snatches (75/55 lb)"
            ]
        )
    ]

    // Persistência simples (UserDefaults via AppStorage) — armazenando PR como texto (ex: 12:34)
    @AppStorage("student_pr_heroes_values_v1")
    private var heroesValuesData: Data = Data()

    // ✅ Correção: usar o próprio item como gatilho da sheet (evita abrir sem dados prontos)
    @State private var selectedWod: HeroWOD? = nil
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

                            Text("Adicione seu melhor tempo por WOD.")
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
                Text("The Heroes")
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

            Text("WOD")
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

    private func tableRow(wod: HeroWOD) -> some View {
        let stored = loadValue(for: wod.storageKey)

        return Button {
            // ✅ Agora a sheet só abre quando selectedWod já está definido
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

    // MARK: - Sheet (editar PR)
    private func editSheet(for wod: HeroWOD) -> some View {
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
            // ✅ Garante carregar o PR sempre que abrir pela primeira vez
            inputValue = loadValue(for: wod.storageKey) ?? ""
        }
    }

    /// Card visual do WOD dentro do modal (mesmo padrão do Notables)
    private func wodCard(_ wod: HeroWOD) -> some View {
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

    private func saveCurrentInput(for wod: HeroWOD) {
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

// MARK: - Persistência (JSON em Data) — [String: String]
private extension StudentHeroesPersonalRecordsView {

    func loadMap() -> [String: String] {
        guard !heroesValuesData.isEmpty else { return [:] }
        do {
            return try JSONDecoder().decode([String: String].self, from: heroesValuesData)
        } catch {
            return [:]
        }
    }

    func saveMap(_ map: [String: String]) {
        do {
            heroesValuesData = try JSONEncoder().encode(map)
        } catch {
            heroesValuesData = Data()
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

