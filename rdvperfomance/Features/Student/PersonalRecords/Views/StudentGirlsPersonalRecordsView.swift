import SwiftUI

// Tela do Aluno: Recorde Pessoal > Girls (lista fixa de WODs + score numérico)
struct StudentGirlsPersonalRecordsView: View {

    @Binding var path: [AppRoute]

    private let contentMaxWidth: CGFloat = 380

    private struct GirlWOD: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let storageKey: String
    }

    // ✅ Dados fixos conforme solicitado (ordem + nomes)
    private let wods: [GirlWOD] = [
        .init(name: "Amanda", storageKey: "girls_amanda"),
        .init(name: "Angie", storageKey: "girls_angie"),
        .init(name: "Annie", storageKey: "girls_annie"),
        .init(name: "Barbara Ann", storageKey: "girls_barbara_ann"),
        .init(name: "Barbara", storageKey: "girls_barbara"),
        .init(name: "Charlotte", storageKey: "girls_charlotte"),
        .init(name: "Chelsea", storageKey: "girls_chelsea"),
        .init(name: "Christine", storageKey: "girls_christine"),
        .init(name: "Cindy", storageKey: "girls_cindy"),
        .init(name: "Diane", storageKey: "girls_diane"),
        .init(name: "Elizabeth", storageKey: "girls_elizabeth"),
        .init(name: "Emily", storageKey: "girls_emily"),
        .init(name: "Eva", storageKey: "girls_eva"),
        .init(name: "Fran", storageKey: "girls_fran"),
        .init(name: "Grettel", storageKey: "girls_grettel"),
        .init(name: "Grace", storageKey: "girls_grace"),
        .init(name: "Gwen", storageKey: "girls_gwen"),
        .init(name: "Helen", storageKey: "girls_helen"),
        .init(name: "lasmim", storageKey: "girls_lasmim"),
        .init(name: "Ingrid", storageKey: "girls_ingrid"),
        .init(name: "Isabel", storageKey: "girls_isabel"),
        .init(name: "Jackie", storageKey: "girls_jackie"),
        .init(name: "Karen", storageKey: "girls_karen"),
        .init(name: "Kelly", storageKey: "girls_kelly"),
        .init(name: "Lesley", storageKey: "girls_lesley"),
        .init(name: "Linda", storageKey: "girls_linda"),
        .init(name: "Lola", storageKey: "girls_lola"),
        .init(name: "Lyla", storageKey: "girls_lyla"),
        .init(name: "Lynne", storageKey: "girls_lynne"),
        .init(name: "Mary", storageKey: "girls_mary"),
        .init(name: "Megan", storageKey: "girls_megan"),
        .init(name: "Nancy", storageKey: "girls_nancy"),
        .init(name: "Nicole", storageKey: "girls_nicole"),
        .init(name: "Oleta", storageKey: "girls_oleta"),
        .init(name: "Yvonne", storageKey: "girls_yvonne")
    ]

    // Persistência simples (UserDefaults via AppStorage)
    @AppStorage("student_pr_girls_values_v1")
    private var girlsValuesData: Data = Data()

    // ✅ Correção: usar o próprio item como gatilho da sheet (igual ao Heroes)
    @State private var selectedWod: GirlWOD? = nil
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

                            Text("Adicione seu melhor resultado por treino.")
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
                Text("Girls")
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

            // ✅ Se não existir treino relacionado (texto vazio), remove o item da lista
            let list = wods.filter { !wodDetailText(for: $0.storageKey).isEmpty }

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

            Text("Treino")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.55))

            Spacer()

            Text("Tempo / Score")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.55))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func tableRow(wod: GirlWOD) -> some View {
        let storedValue = loadValue(for: wod.storageKey)

        return Button {
            // ✅ Agora a sheet só abre quando selectedWod já está definido
            selectedWod = wod
        } label: {
            HStack(spacing: 10) {

                Image(systemName: "list.bullet.clipboard.fill")
                    .foregroundColor(.green.opacity(0.85))
                    .font(.system(size: 15))
                    .frame(width: 26)

                Text(wod.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer()

                if let storedValue {
                    Text(formatNumber(storedValue))
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

    // MARK: - Sheet (editar Score)
    private func editSheet(for wod: GirlWOD) -> some View {
        let wodText = wodDetailText(for: wod.storageKey)

        return ZStack {
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

                Text("Informe seu tempo/score. Para remover, deixe vazio.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.60))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 10) {

                    // ✅ Ajuste solicitado: bloco WOD igual ao Notables (com ícone)
                    if !wodText.isEmpty {
                        wodCard(title: wod.name, description: wodText)
                            .padding(.horizontal, 16)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tempo / Score:")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))

                        TextField("Ex: 12.34", text: $inputValue)
                            .keyboardType(.decimalPad)
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
                    .padding(.top, 2)
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
        .presentationDetents([.large])
        .onAppear {
            // ✅ Garante carregar o score sempre que abrir pela primeira vez (igual ao Heroes)
            if let stored = loadValue(for: wod.storageKey) {
                inputValue = formatNumber(stored)
            } else {
                inputValue = ""
            }
        }
    }

    /// Card visual do WOD dentro do modal (mesmo layout do Notables)
    private func wodCard(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundColor(.green.opacity(0.90))

                VStack(alignment: .leading, spacing: 2) {
                    Text("WOD")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.60))

                    Text(title)
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

    private func saveCurrentInput(for wod: GirlWOD) {
        let trimmed = inputValue
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            removeValue(for: wod.storageKey)
            return
        }

        if let value = Double(trimmed), value > 0 {
            saveValue(value, for: wod.storageKey)
        }
    }

    private func formatNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.decimalSeparator = "."
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    // MARK: - WOD Details (texto fixo por registro)
    private func wodDetailText(for key: String) -> String {
        switch key {

        case "girls_amanda":
            return """
9-7-5
• Muscle-ups
• Snatch (61/43 kg)
"""

        case "girls_angie":
            return """
(For Time)
• 100 Pull-ups
• 100 Push-ups
• 100 Sit-ups
• 100 Air Squats
"""

        case "girls_annie":
            return """
(For Time)
50-40-30-20-10
• Double-unders
• Sit-ups
"""

        case "girls_barbara_ann":
            return """
(For Time)
• 50 Pull-ups
• 100 Sit-ups
• 150 Air Squats
• 200 Double-unders
"""

        case "girls_barbara":
            return """
(5 Rounds – Rest 3 min entre rounds)
• 20 Pull-ups
• 30 Push-ups
• 40 Sit-ups
• 50 Air Squats
"""

        case "girls_charlotte":
            return """
(3 Rounds For Time)
• 21 Overhead Squats (43/30 kg)
• 21 Sit-ups
• 21 Clean (43/30 kg)
"""

        case "girls_chelsea":
            return """
(EMOM 30 min)
A cada minuto:
• 5 Pull-ups
• 10 Push-ups
• 15 Air Squats
"""

        case "girls_christine":
            return """
(3 Rounds For Time)
• 500m Row
• 12 Deadlifts (61/43 kg)
• 21 Box Jumps (61/51 cm)
"""

        case "girls_cindy":
            return """
(AMRAP 20 min)
• 5 Pull-ups
• 10 Push-ups
• 15 Air Squats
"""

        case "girls_diane":
            return """
(For Time)
21-15-9
• Deadlift (102/70 kg)
• Handstand Push-ups
"""

        case "girls_elizabeth":
            return """
(For Time)
21-15-9
• Clean (61/43 kg)
• Ring Dips
"""

        case "girls_emily":
            return """
(For Time)
• 30 Squat Cleans (43/30 kg)
• 30 Ring Dips
• 30 Box Jumps
"""

        case "girls_eva":
            return """
(5 Rounds For Time)
• 800m Run
• 30 Kettlebell Swings (24/16 kg)
• 30 Pull-ups
"""

        case "girls_fran":
            return """
(For Time)
21-15-9
• Thrusters (43/30 kg)
• Pull-ups
"""

        case "girls_grettel":
            return """
(For Time)
• 3 Rounds:
  • 10 Deadlifts (102/70 kg)
  • 3 Handstand Walks (15m)
"""

        case "girls_grace":
            return """
(For Time)
• 30 Clean & Jerks (61/43 kg)
"""

        case "girls_gwen":
            return """
(For Time – Unbroken)
15-12-9
• Clean & Jerk (escolha a carga, sem soltar a barra entre repetições)
"""

        case "girls_helen":
            return """
(3 Rounds For Time)
• 400m Run
• 21 Kettlebell Swings (24/16 kg)
• 12 Pull-ups
"""

        case "girls_lasmim":
            return """
Jasmine (AMRAP 20 min)
• 10 Push-ups
• 10 Sit-ups
• 10 Air Squats
"""

        case "girls_ingrid":
            return """
(For Time)
• 100 Double-unders
• 20 Deadlifts (61/43 kg)
• 100 Double-unders
• 20 Power Snatches (43/30 kg)
• 100 Double-unders
"""

        case "girls_isabel":
            return """
(For Time)
• 30 Snatches (61/43 kg)
"""

        case "girls_jackie":
            return """
(For Time)
• 1000m Row
• 50 Thrusters (20/15 kg)
• 30 Pull-ups
"""

        case "girls_karen":
            return """
(For Time)
• 150 Wall Balls (9/6 kg)
"""

        case "girls_kelly":
            return """
(5 Rounds For Time)
• 400m Run
• 30 Box Jumps (61/51 cm)
• 30 Wall Balls (9/6 kg)
"""

        case "girls_lesley":
            return """
(5 Rounds For Time)
• 400m Run
• 15 Thrusters (43/30 kg)
• 15 Pull-ups
"""

        case "girls_linda":
            return """
(For Time – “3 Bars of Death”)
10-9-8-7-6-5-4-3-2-1
• Deadlift (1.5x BW)
• Bench Press (BW)
• Clean (0.75x BW)
"""

        case "girls_lola":
            return """
(5 Rounds For Time)
• 400m Run
• 20 Pull-ups
• 20 Push-ups
"""

        case "girls_lyla":
            return """
(AMRAP 20 min)
• 10 Toes-to-Bar
• 10 Thrusters (43/30 kg)
• 200m Run
"""

        case "girls_lynne":
            return """
(5 Rounds – Max Reps)
• Max Bench Press (BW)
• Max Pull-ups
"""

        case "girls_mary":
            return """
(AMRAP 20 min)
• 5 Handstand Push-ups
• 10 Pistols
• 15 Pull-ups
"""

        case "girls_megan":
            return """
(For Time)
• 21-15-9
  • Burpees
  • Kettlebell Swings (24/16 kg)
"""

        case "girls_nancy":
            return """
(5 Rounds For Time)
• 400m Run
• 15 Overhead Squats (43/30 kg)
"""

        case "girls_nicole":
            return """
(AMRAP 20 min)
• 400m Run
• Max Pull-ups
"""

        case "girls_oleta":
            return """
(For Time)
• 21-15-9
  • Deadlift (61/43 kg)
  • Sit-ups
"""

        case "girls_yvonne":
            return """
(For Time)
• 5 Rounds:
  • 25 Wall Balls (9/6 kg)
  • 25 Sit-ups
"""

        default:
            return ""
        }
    }
}

// MARK: - Persistência (JSON em Data)
private extension StudentGirlsPersonalRecordsView {

    func loadMap() -> [String: Double] {
        guard !girlsValuesData.isEmpty else { return [:] }
        do {
            return try JSONDecoder().decode([String: Double].self, from: girlsValuesData)
        } catch {
            return [:]
        }
    }

    func saveMap(_ map: [String: Double]) {
        do {
            girlsValuesData = try JSONEncoder().encode(map)
        } catch {
            girlsValuesData = Data()
        }
    }

    func loadValue(for key: String) -> Double? {
        let map = loadMap()
        return map[key]
    }

    func saveValue(_ value: Double, for key: String) {
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

