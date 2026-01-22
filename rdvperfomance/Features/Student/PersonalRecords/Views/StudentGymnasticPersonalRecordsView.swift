import SwiftUI

// Tela do Aluno: Recorde Pessoal > Gymnastic (lista fixa + registros)
struct StudentGymnasticPersonalRecordsView: View {

    @Binding var path: [AppRoute]

    private let contentMaxWidth: CGFloat = 380

    private struct GymItem: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let metric: String
        let storageKey: String
    }

    private struct CustomGymItem: Identifiable, Hashable, Codable {
        let id: String
        let name: String
        let metric: String
        let storageKey: String
    }

    // ✅ Dados fixos conforme solicitado
    private let items: [GymItem] = [
        .init(name: "Abmat", metric: "Max Reps", storageKey: "abmat"),
        .init(name: "Air Squat", metric: "Max Reps", storageKey: "air_squat"),
        .init(name: "Bar Muscle-Ups", metric: "Max Reps", storageKey: "bar_muscle_ups"),
        .init(name: "Box Jump", metric: "Max Height", storageKey: "box_jump"),
        .init(name: "Double Unders", metric: "Max Reps", storageKey: "double_unders"),
        .init(name: "Handstand Push-Ups", metric: "Max", storageKey: "handstand_push_ups"),
        .init(name: "Handstand Walk", metric: "Max Distance", storageKey: "handstand_walk"),
        .init(name: "L-Sit", metric: "Max Hold", storageKey: "l_sit"),
        .init(name: "Muscle-Ups", metric: "30 Reps for Time", storageKey: "muscle_ups_30_for_time"),
        .init(name: "Pull-Up (Weighted)", metric: "1 Rep Max", storageKey: "pull_up_weighted_1rm"),
        .init(name: "Pull-Ups (Chest To Bar)", metric: "Max Reps", storageKey: "pull_ups_ctb"),
        .init(name: "Pull-Ups (Strict Chest To Bar)", metric: "Max Reps", storageKey: "pull_ups_strict_ctb"),
        .init(name: "Pull-Ups (Strict)", metric: "Max Reps", storageKey: "pull_ups_strict"),
        .init(name: "Pull-Ups", metric: "Max Reps", storageKey: "pull_ups"),
        .init(name: "Push-Ups", metric: "Max Reps", storageKey: "push_ups"),
        .init(name: "Ring Dips", metric: "Max Reps", storageKey: "ring_dips"),
        .init(name: "Ring Muscle-Ups", metric: "Max Reps", storageKey: "ring_muscle_ups"),
        .init(name: "Ring Row", metric: "", storageKey: "ring_row"),
        .init(name: "Single Unders", metric: "Max Reps", storageKey: "single_unders"),
        .init(name: "Sit Up", metric: "Max Reps 1'", storageKey: "sit_up_max_reps_1min"),
        .init(name: "Strict Handstand Push-Ups", metric: "Max Reps", storageKey: "strict_handstand_push_ups"),
        .init(name: "Strict Ring Muscle-Ups", metric: "Max Reps", storageKey: "strict_ring_muscle_ups"),
        .init(name: "Tabata Squat", metric: "", storageKey: "tabata_squat"),
        .init(name: "Toes To Bar", metric: "Max Reps", storageKey: "toes_to_bar"),
        .init(name: "WallBall", metric: "Max Reps", storageKey: "wallball")
    ]

    // Persistência simples (UserDefaults via AppStorage)
    @AppStorage("student_pr_gymnastic_values_v1")
    private var gymValuesData: Data = Data()

    // ✅ Persistência dos itens criados pelo aluno
    @AppStorage("student_pr_gymnastic_custom_items_v1")
    private var customItemsData: Data = Data()

    @State private var selectedItem: GymItem?
    @State private var inputValue: String = ""

    // ✅ Adicionar item
    @State private var showAddItemSheet: Bool = false
    @State private var newItemName: String = ""
    @State private var newItemMetric: String = ""
    @State private var newItemValue: String = ""
    @State private var addItemErrorMessage: String? = nil

    // ✅ Confirmação de exclusão (apenas itens novos)
    @State private var showDeleteAlert: Bool = false

    private var allItems: [GymItem] {
        let custom = loadCustomItems().map { GymItem(name: $0.name, metric: $0.metric, storageKey: $0.storageKey) }
        return items + custom
    }

    private var canDeleteSelectedItem: Bool {
        guard let key = selectedItem?.storageKey else { return false }
        return key.hasPrefix("custom_gym_")
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
                                Text("Adicione seu recorde por movimento.")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.55))

                                Spacer()

                                Button {
                                    addItemErrorMessage = nil
                                    newItemName = ""
                                    newItemMetric = ""
                                    newItemValue = ""
                                    showAddItemSheet = true
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.green.opacity(0.85))
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Adicionar novo item")
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
                Text("Gymnastic")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(item: $selectedItem) { item in
            editSheet(item: item)
        }
        .sheet(isPresented: $showAddItemSheet) {
            addItemSheet()
        }
    }

    private func tableContainer() -> some View {
        VStack(spacing: 0) {

            tableHeader()

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)

            let list = allItems

            ForEach(Array(list.enumerated()), id: \.element.id) { index, item in

                tableRow(item: item)

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

            Text("PR")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.55))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func tableRow(item: GymItem) -> some View {
        let value = loadValue(for: item.storageKey)

        return Button {
            selectedItem = item
            inputValue = value ?? ""
        } label: {
            HStack(spacing: 10) {

                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundColor(.green.opacity(0.85))
                    .font(.system(size: 15))
                    .frame(width: 26)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    if !item.metric.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(item.metric)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.45))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                }

                Spacer()

                if let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(value)
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

    private func editSheet(item: GymItem) -> some View {
        let canDelete = item.storageKey.hasPrefix("custom_gym_")

        return ZStack {
            Theme.Colors.headerBackground
                .ignoresSafeArea()

            VStack(spacing: 14) {

                Capsule()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 44, height: 5)
                    .padding(.top, 10)

                Text(item.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 4)

                if !item.metric.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(item.metric)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.55))
                }

                Text("Informe seu recorde. Para remover, deixe vazio.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.60))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Resultado:")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))

                    TextField("Ex: 50 / 1,90m / 3:25", text: $inputValue)
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

                if canDelete {
                    Text("Ao excluir, o registro será removido do seu histórico. Esta ação não pode ser desfeita.")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.50))
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                }

                HStack(spacing: 12) {

                    Button {
                        selectedItem = nil
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
                        selectedItem = nil
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

                    if canDelete {
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
                        .accessibilityLabel("Excluir item")
                    }
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
                deleteSelectedItem()
            }
        } message: {
            Text("Deseja excluir o registro de \"\(item.name)\"?")
        }
    }

    private func addItemSheet() -> some View {
        ZStack {
            Theme.Colors.headerBackground
                .ignoresSafeArea()

            VStack(spacing: 14) {

                Capsule()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 44, height: 5)
                    .padding(.top, 10)

                Text("Novo item")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 4)

                Text("Crie um item e, se quiser, já informe seu recorde.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.60))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 10) {

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nome do movimento")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))

                        TextField("Ex: Rope Climb", text: $newItemName)
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
                        Text("Tipo / Métrica (opcional)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))

                        TextField("Ex: Max Reps / For Time / Max Distance", text: $newItemMetric)
                            .textInputAutocapitalization(.sentences)
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
                        Text("Recorde (opcional)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))

                        TextField("Ex: 50 / 1,90m / 3:25", text: $newItemValue)
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

                    if let msg = addItemErrorMessage {
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
                        showAddItemSheet = false
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
                        addNewItem()
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

    private func addNewItem() {
        addItemErrorMessage = nil

        let cleanName = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else {
            addItemErrorMessage = "Informe o nome do movimento."
            return
        }

        let existingNames = allItems.map { $0.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
        if existingNames.contains(cleanName.lowercased()) {
            addItemErrorMessage = "Este item já existe na sua lista."
            return
        }

        let id = UUID().uuidString
        let key = "custom_gym_\(id)"

        let metric = newItemMetric.trimmingCharacters(in: .whitespacesAndNewlines)

        var list = loadCustomItems()
        list.append(CustomGymItem(id: id, name: cleanName, metric: metric, storageKey: key))
        saveCustomItems(list)

        let trimmedValue = newItemValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedValue.isEmpty {
            saveValue(trimmedValue, for: key)
        }

        showAddItemSheet = false
    }

    private func saveCurrentInput() {
        guard let item = selectedItem else { return }

        let trimmed = inputValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            removeValue(for: item.storageKey)
            return
        }

        saveValue(trimmed, for: item.storageKey)
    }

    private func deleteSelectedItem() {
        guard let item = selectedItem else { return }

        let key = item.storageKey

        guard key.hasPrefix("custom_gym_") else {
            selectedItem = nil
            return
        }

        removeValue(for: key)

        var list = loadCustomItems()
        list.removeAll { $0.storageKey == key }
        saveCustomItems(list)

        selectedItem = nil
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

// MARK: - Persistência (JSON em Data)
private extension StudentGymnasticPersonalRecordsView {

    func loadMap() -> [String: String] {
        guard !gymValuesData.isEmpty else { return [:] }
        do {
            return try JSONDecoder().decode([String: String].self, from: gymValuesData)
        } catch {
            return [:]
        }
    }

    func saveMap(_ map: [String: String]) {
        do {
            gymValuesData = try JSONEncoder().encode(map)
        } catch {
            gymValuesData = Data()
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

    private func loadCustomItems() -> [CustomGymItem] {
        guard !customItemsData.isEmpty else { return [] }
        do {
            return try JSONDecoder().decode([CustomGymItem].self, from: customItemsData)
        } catch {
            return []
        }
    }

    private func saveCustomItems(_ list: [CustomGymItem]) {
        do {
            customItemsData = try JSONEncoder().encode(list)
        } catch {
            customItemsData = Data()
        }
    }
}

