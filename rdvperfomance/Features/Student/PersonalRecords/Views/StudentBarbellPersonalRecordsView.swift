import SwiftUI

// Tela do Aluno: Recorde Pessoal > Barbell (lista fixa de movimentos + carga máxima)
struct StudentBarbellPersonalRecordsView: View {

    @Binding var path: [AppRoute]

    private let contentMaxWidth: CGFloat = 380

    private struct BarbellMove: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let storageKey: String
    }

    private struct CustomBarbellMove: Identifiable, Hashable, Codable {
        let id: String
        let name: String
        let storageKey: String
    }

    private enum WeightUnit: String {
        case kg
        case lbs

        var shortLabel: String {
            switch self {
            case .kg: return "kg"
            case .lbs: return "lbs"
            }
        }
    }

    private let preferredWeightUnitKey: String = "preferredWeightUnit"

    private var preferredWeightUnit: WeightUnit {
        WeightUnit(rawValue: preferredWeightUnitRawState) ?? .kg
    }

    @AppStorage("preferredWeightUnit")
    private var preferredWeightUnitRawState: String = WeightUnit.kg.rawValue

    // ✅ Dados fixos conforme solicitado
    private let moves: [BarbellMove] = [
        .init(name: "Back Squat", storageKey: "back_squat"),
        .init(name: "Bench Over Row", storageKey: "bench_over_row"),
        .init(name: "Bench Press", storageKey: "bench_press"),
        .init(name: "Clean", storageKey: "clean"),
        .init(name: "Clean & Jerk", storageKey: "clean_and_jerk"),
        .init(name: "Clean Pull", storageKey: "clean_pull"),
        .init(name: "Cluster", storageKey: "cluster"),
        .init(name: "Deadlift", storageKey: "deadlift"),
        .init(name: "Front Squat", storageKey: "front_squat"),
        .init(name: "Hang Power Clean", storageKey: "hang_power_clean"),
        .init(name: "Hang Power Snatch", storageKey: "hang_power_snatch"),
        .init(name: "Hang Squat Clean", storageKey: "hang_squat_clean"),
        .init(name: "Hang Squat Snatch", storageKey: "hang_squat_snatch"),
        .init(name: "Muscle Clean", storageKey: "muscle_clean"),
        .init(name: "Overhead Lunge", storageKey: "overhead_lunge"),
        .init(name: "Power Clean", storageKey: "power_clean"),
        .init(name: "Power Snatch", storageKey: "power_snatch"),
        .init(name: "Push Jerk", storageKey: "push_jerk"),
        .init(name: "Push Press", storageKey: "push_press"),
        .init(name: "Shoulder Press", storageKey: "shoulder_press"),
        .init(name: "Snatch", storageKey: "snatch"),
        .init(name: "Snatch Balance", storageKey: "snatch_balance"),
        .init(name: "Snatch Deadlift", storageKey: "snatch_deadlift"),
        .init(name: "Snatch Pull", storageKey: "snatch_pull")
    ]

    // Persistência simples (UserDefaults via AppStorage)
    @AppStorage("student_pr_barbell_values_v1")
    private var barbellValuesData: Data = Data()

    // ✅ NOVO: persistência dos movimentos criados pelo aluno
    @AppStorage("student_pr_barbell_custom_moves_v1")
    private var customMovesData: Data = Data()

    @State private var showEditSheet: Bool = false
    @State private var selectedMove: BarbellMove?
    @State private var inputValue: String = ""

    // ✅ NOVO: adicionar movimento
    @State private var showAddMoveSheet: Bool = false
    @State private var newMoveName: String = ""
    @State private var newMoveValue: String = ""
    @State private var addMoveErrorMessage: String? = nil

    // ✅ NOVO: confirmação de exclusão pelo modal
    @State private var showDeleteAlert: Bool = false

    private var allMoves: [BarbellMove] {
        let custom = loadCustomMoves().map { BarbellMove(name: $0.name, storageKey: $0.storageKey) }
        return moves + custom
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
                                Text("Adicione sua carga máxima por movimento.")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.55))

                                Spacer()

                                Button {
                                    addMoveErrorMessage = nil
                                    newMoveName = ""
                                    newMoveValue = ""
                                    showAddMoveSheet = true
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.green.opacity(0.85))
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Adicionar novo movimento")
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
                Text("Barbell")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showEditSheet) {
            editSheet()
        }
        .sheet(isPresented: $showAddMoveSheet) {
            addMoveSheet()
        }
        .onAppear {
            let raw = UserDefaults.standard.string(forKey: preferredWeightUnitKey) ?? WeightUnit.kg.rawValue
            if preferredWeightUnitRawState != raw {
                preferredWeightUnitRawState = raw
            }
        }
    }

    // MARK: - Tabela (Sugestão 2)
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

            Text("Movimento")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.55))

            Spacer()

            Text("PR (\(preferredWeightUnit.shortLabel))")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.55))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func tableRow(move: BarbellMove) -> some View {
        let storedKgValue = loadValue(for: move.storageKey)
        let displayValue = storedKgValue.map { convertFromStorageKgToPreferredUnit($0) }

        return Button {
            selectedMove = move
            inputValue = displayValue.map { formatNumber($0) } ?? ""
            showEditSheet = true
        } label: {
            HStack(spacing: 10) {

                Image(systemName: "dumbbell.fill")
                    .foregroundColor(.green.opacity(0.85))
                    .font(.system(size: 15))
                    .frame(width: 26)

                Text(move.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer()

                if let displayValue {
                    Text(formatNumber(displayValue))
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
    private func editSheet() -> some View {
        ZStack {
            Theme.Colors.headerBackground
                .ignoresSafeArea()

            VStack(spacing: 14) {

                Capsule()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 44, height: 5)
                    .padding(.top, 10)

                Text(selectedMove?.name ?? "Movimento")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 4)

                Text("Informe sua carga máxima em \(preferredWeightUnit.shortLabel). Para remover, deixe vazio.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.60))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Carga máxima (\(preferredWeightUnit.shortLabel))")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))

                    HStack(spacing: 10) {
                        TextField("Ex: 90.91", text: $inputValue)
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

                        Text(preferredWeightUnit.shortLabel)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white.opacity(0.70))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)

                Text("Ao excluir, o registro será removido do seu histórico. Esta ação não pode ser desfeita.")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.50))
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)

                HStack(spacing: 12) {

                    Button {
                        showEditSheet = false
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
                        showEditSheet = false
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
                    .accessibilityLabel("Excluir movimento")
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)

                Spacer()
            }
        }
        .presentationDetents([.medium])
        .alert("Excluir registro", isPresented: $showDeleteAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Excluir", role: .destructive) {
                deleteSelectedMove()
            }
        } message: {
            Text("Deseja excluir o registro de \"\(selectedMove?.name ?? "este movimento")\"?")
        }
    }

    // MARK: - Sheet (adicionar movimento)
    private func addMoveSheet() -> some View {
        ZStack {
            Theme.Colors.headerBackground
                .ignoresSafeArea()

            VStack(spacing: 14) {

                Capsule()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 44, height: 5)
                    .padding(.top, 10)

                Text("Novo movimento")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 4)

                Text("Crie um movimento e, se quiser, já informe a carga máxima em \(preferredWeightUnit.shortLabel).")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.60))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 10) {

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nome do movimento")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))

                        TextField("Ex: Bulgarian Split Squat", text: $newMoveName)
                            .textInputAutocapitalization(.words)
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

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Carga máxima (\(preferredWeightUnit.shortLabel)) (opcional)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))

                        HStack(spacing: 10) {
                            TextField("Ex: 90.91", text: $newMoveValue)
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

                            Text(preferredWeightUnit.shortLabel)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.70))
                        }
                    }

                    if let msg = addMoveErrorMessage {
                        Text(msg)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.yellow.opacity(0.85))
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)

                HStack(spacing: 12) {

                    Button {
                        showAddMoveSheet = false
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
                        addNewMove()
                    } label: {
                        Text("Adicionar")
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
        .presentationDetents([.medium])
    }

    private func addNewMove() {
        addMoveErrorMessage = nil

        let cleanName = newMoveName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else {
            addMoveErrorMessage = "Informe o nome do movimento."
            return
        }

        let existingNames = allMoves.map { $0.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
        if existingNames.contains(cleanName.lowercased()) {
            addMoveErrorMessage = "Este movimento já existe na sua lista."
            return
        }

        let id = UUID().uuidString
        let key = "custom_barbell_\(id)"

        var list = loadCustomMoves()
        list.append(CustomBarbellMove(id: id, name: cleanName, storageKey: key))
        saveCustomMoves(list)

        let trimmedValue = newMoveValue
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedValue.isEmpty, let value = Double(trimmedValue), value > 0 {
            let storageKg = convertFromPreferredUnitToStorageKg(value)
            saveValue(storageKg, for: key)
        }

        showAddMoveSheet = false
    }

    private func saveCurrentInput() {
        guard let move = selectedMove else { return }

        let trimmed = inputValue
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            removeValue(for: move.storageKey)
            return
        }

        if let value = Double(trimmed), value > 0 {
            let storageKg = convertFromPreferredUnitToStorageKg(value)
            saveValue(storageKg, for: move.storageKey)
        }
    }

    private func deleteSelectedMove() {
        guard let move = selectedMove else { return }

        let key = move.storageKey

        removeValue(for: key)

        if key.hasPrefix("custom_barbell_") {
            var list = loadCustomMoves()
            list.removeAll { $0.storageKey == key }
            saveCustomMoves(list)
        }

        showEditSheet = false
    }

    private func formatNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.decimalSeparator = "."
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func convertFromStorageKgToPreferredUnit(_ kg: Double) -> Double {
        switch preferredWeightUnit {
        case .kg:
            return kg
        case .lbs:
            return kg * 2.2046226218
        }
    }

    private func convertFromPreferredUnitToStorageKg(_ value: Double) -> Double {
        switch preferredWeightUnit {
        case .kg:
            return value
        case .lbs:
            return value / 2.2046226218
        }
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

// MARK: - Persistência (JSON em Data)
private extension StudentBarbellPersonalRecordsView {

    func loadMap() -> [String: Double] {
        guard !barbellValuesData.isEmpty else { return [:] }
        do {
            return try JSONDecoder().decode([String: Double].self, from: barbellValuesData)
        } catch {
            return [:]
        }
    }

    func saveMap(_ map: [String: Double]) {
        do {
            barbellValuesData = try JSONEncoder().encode(map)
        } catch {
            barbellValuesData = Data()
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

    private func loadCustomMoves() -> [CustomBarbellMove] {
        guard !customMovesData.isEmpty else { return [] }
        do {
            return try JSONDecoder().decode([CustomBarbellMove].self, from: customMovesData)
        } catch {
            return []
        }
    }

    private func saveCustomMoves(_ list: [CustomBarbellMove]) {
        do {
            customMovesData = try JSONEncoder().encode(list)
        } catch {
            customMovesData = Data()
        }
    }

}

