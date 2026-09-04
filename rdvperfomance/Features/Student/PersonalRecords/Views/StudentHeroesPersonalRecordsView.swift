import SwiftUI
import Charts

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

    @AppStorage("student_pr_heroes_history_v1")
    private var heroesHistoryData: Data = Data()

    // ✅ Correção: usar o próprio item como gatilho da sheet (evita abrir sem dados prontos)
    @State private var selectedWod: HeroWOD? = nil
    @State private var inputValue: String = ""
    @State private var historyWod: HeroWOD?
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
                Text("The Heroes")
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
        let stored = bestDisplayValue(for: wod.storageKey, metadata: wod.descriptionLines.joined(separator: " "))

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

            VStack(spacing: 0) {

                Capsule()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 44, height: 5)
                    .padding(.top, 10)

                Text(wod.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 4)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                    // ✅ Bloco do WOD no mesmo padrão do Notables (card + ícone)
                    if !wod.descriptionLines.isEmpty {
                        wodCard(wod)
                            .padding(.horizontal, 16)
                            .padding(.top, 2)
                            .layoutPriority(1)
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

                    }
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
                .padding(.bottom, 16)
            }
        }
        .presentationDetents([.fraction(0.80)])
        .onAppear {
            // ✅ Garante carregar o PR sempre que abrir pela primeira vez
            inputValue = bestDisplayValue(for: wod.storageKey, metadata: wod.descriptionLines.joined(separator: " ")) ?? ""
            selectedPRDate = Date()
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

    private func saveCurrentInput(for wod: HeroWOD) {
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



    private func loadHistoryMap() -> [String: [PRHistoryEntry]] {
        guard !heroesHistoryData.isEmpty else { return [:] }
        do { return try JSONDecoder().decode([String: [PRHistoryEntry]].self, from: heroesHistoryData) } catch { return [:] }
    }

    private func saveHistoryMap(_ map: [String: [PRHistoryEntry]]) {
        do { heroesHistoryData = try JSONEncoder().encode(map) } catch { heroesHistoryData = Data() }
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
