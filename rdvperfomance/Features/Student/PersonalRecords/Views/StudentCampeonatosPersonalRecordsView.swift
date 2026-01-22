import SwiftUI

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
        )
    ]

    // Persistência simples (UserDefaults via AppStorage) — armazenando PR como texto (ex: 12:34)
    @AppStorage("student_pr_campeonatos_values_v1")
    private var campeonatosValuesData: Data = Data()

    @State private var selectedWod: CampeonatoWOD? = nil
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
                Text("Campeonatos")
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
        let stored = loadValue(for: wod.storageKey)

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

