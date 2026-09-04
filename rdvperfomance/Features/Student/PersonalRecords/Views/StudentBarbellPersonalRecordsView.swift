import SwiftUI
import Charts

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

    private struct BarbellPRHistoryEntry: Identifiable, Codable, Hashable {
        let id: String
        let valueKg: Double
        let createdAt: Date
    }

    private enum WeightUnit: String {
        case kg
        case lbs

        var shortLabel: String {
            switch self {
            case .kg:  return "kg"
            case .lbs: return "lb"   // ✅ Abreviação padrão (não "lbs")
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
        .init(name: "Snatch Pull", storageKey: "snatch_pull"),
        .init(name: "Split Jerk", storageKey: "split_jerk"),
        .init(name: "Squat Jerk", storageKey: "squat_jerk"),
        .init(name: "Squat Snatch", storageKey: "squat_snatch"),
        .init(name: "Sumo Deadlift", storageKey: "sumo_deadlift"),
        .init(name: "Sumo Deadlift High Pull", storageKey: "sumo_deadlift_high_pull"),
        .init(name: "Thruster", storageKey: "thruster")
    ]

    // Persistência simples (UserDefaults via AppStorage)
    @AppStorage("student_pr_barbell_values_v1")
    private var barbellValuesData: Data = Data()

    @AppStorage("student_pr_barbell_history_v1")
    private var barbellHistoryData: Data = Data()

    // ✅ NOVO: persistência dos movimentos criados pelo aluno
    @AppStorage("student_pr_barbell_custom_moves_v1")
    private var customMovesData: Data = Data()

    @State private var selectedMove: BarbellMove?
    @State private var inputValue: String = ""
    @State private var historyMove: BarbellMove?
    @State private var selectedPRDate: Date = Date()
    @State private var showPRDatePicker: Bool = false

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

    // ✅ NOVO: só movimentos criados pelo botão + podem ser excluídos
    private var canDeleteSelectedMove: Bool {
        guard let key = selectedMove?.storageKey else { return false }
        return key.hasPrefix("custom_barbell_")
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
        .blur(radius: (selectedMove != nil || historyMove != nil || showAddMoveSheet) ? 4 : 0)
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
                Text("Barbell")
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
        let storedKgValue = bestPRValueKg(for: move.storageKey)
        let displayValue = storedKgValue.map { convertFromStorageKgToPreferredUnit($0) }

        return Button {
            inputValue = displayValue.map { formatNumber($0) } ?? ""
            selectedPRDate = Date()
            selectedMove = move
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
    private func editSheet(move: BarbellMove) -> some View {
        ZStack {
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
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Carga máxima (\(preferredWeightUnit.shortLabel)):")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))

                        HStack(spacing: 10) {
                            TextField("Ex: 90,50", text: $inputValue)
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
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .foregroundColor(.green.opacity(0.90))

                                Text("Evolução")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.75))
                            }

                            Spacer()

                            Button {
                                historyMove = move
                            } label: {
                                Label("Histórico", systemImage: "clock.arrow.circlepath")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.green.opacity(0.90))
                            }
                            .buttonStyle(.plain)
                        }

                        historyChart(for: move)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    if canDeleteSelectedMove {
                        Text("Ao excluir, o registro será removido do seu histórico. Esta ação não pode ser desfeita.")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.50))
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
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
                        saveCurrentInput()
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

                    if canDeleteSelectedMove {
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
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 16)
            }
        }
        .presentationDetents([.fraction(0.80)])
        .alert("Excluir registro", isPresented: $showDeleteAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Excluir", role: .destructive) {
                deleteSelectedMove()
            }
        } message: {
            Text("Deseja excluir o registro de \"\(selectedMove?.name ?? "este movimento")\"?")
        }
        .sheet(item: $historyMove) { move in
            historySheet(move: move)
        }
        .sheet(isPresented: $showPRDatePicker) {
            ZStack {
                Theme.Colors.headerBackground
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    DatePicker(
                        "Data do PR",
                        selection: $selectedPRDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .environment(\.locale, Locale(identifier: "pt_BR"))

                    Button {
                        showPRDatePicker = false
                    } label: {
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

    private func historySheet(move: BarbellMove) -> some View {
        let entries = historyEntries(for: move.storageKey)
        let recordID = entries.max(by: { $0.valueKg < $1.valueKg })?.id

        return ZStack {
            Theme.Colors.headerBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    Capsule()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 44, height: 5)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)

                    Text(move.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Text("Histórico")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white.opacity(0.92))

                    if entries.isEmpty {
                        Text("Nenhum histórico de evolução registrado ainda.")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.60))

                        Text("Salve novos PRs para acompanhar sua evolução.")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.45))
                    } else {
                        VStack(spacing: 0) {
                            ForEach(entries.reversed()) { entry in
                                HStack(spacing: 10) {
                                    Image(systemName: entry.id == recordID ? "trophy.fill" : "medal.fill")
                                        .foregroundColor(.green.opacity(0.85))
                                        .frame(width: 22)

                                    Text("\(formatNumber(convertFromStorageKgToPreferredUnit(entry.valueKg))) \(preferredWeightUnit.shortLabel)")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.92))

                                    if entry.id == recordID {
                                        Text("RECORDE")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.green)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color.green.opacity(0.70), lineWidth: 1)
                                            )
                                    }

                                    Spacer()

                                    Text(entry.createdAt.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year().locale(Locale(identifier: "pt_BR"))))
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.45))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)

                                if entry.id != entries.first?.id {
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
                }
                .frame(maxWidth: contentMaxWidth)
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .presentationDetents([.large])
    }

    @ViewBuilder
    private func historyChart(for move: BarbellMove) -> some View {
        let entries = historyEntries(for: move.storageKey)

        if !entries.isEmpty {
            Chart(entries) { entry in
                LineMark(
                    x: .value("Data", entry.createdAt),
                    y: .value("Carga", convertFromStorageKgToPreferredUnit(entry.valueKg))
                )
                .foregroundStyle(.green)
                .interpolationMethod(.linear)

                PointMark(
                    x: .value("Data", entry.createdAt),
                    y: .value("Carga", convertFromStorageKgToPreferredUnit(entry.valueKg))
                )
                .foregroundStyle(.green)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) {
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.white.opacity(0.12))
                    AxisValueLabel(format: .dateTime.day(.twoDigits).month(.twoDigits).year())
                        .foregroundStyle(Color.white.opacity(0.55))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.white.opacity(0.12))
                    AxisValueLabel()
                        .foregroundStyle(Color.white.opacity(0.55))
                }
            }
            .frame(height: 170)
            .padding(14)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
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
                            TextField("Ex: 90,50", text: $newMoveValue)
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

        let trimmedValue = newMoveValue.trimmingCharacters(in: .whitespacesAndNewlines)

        // ✅ Usa WeightParser que aceita vírgula e ponto
        if !trimmedValue.isEmpty, let value = WeightParser.parse(trimmedValue), value > 0 {
            let storageKg = convertFromPreferredUnitToStorageKg(value)
            saveValue(storageKg, for: key)
            saveHistoryValue(storageKg, for: key, date: Date())
        }

        showAddMoveSheet = false
    }

    private func saveCurrentInput() {
        guard let move = selectedMove else { return }

        let trimmed = inputValue.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            removeValue(for: move.storageKey)
            return
        }

        // ✅ Usa WeightParser que aceita vírgula e ponto, valida casas decimais
        if let value = WeightParser.parse(trimmed), value > 0 {
            let storageKg = convertFromPreferredUnitToStorageKg(value)
            if let currentBest = bestPRValueKg(for: move.storageKey) {
                if storageKg > currentBest {
                    saveValue(storageKg, for: move.storageKey)
                }
            } else {
                saveValue(storageKg, for: move.storageKey)
            }
            saveHistoryValue(storageKg, for: move.storageKey, date: selectedPRDate)
        }
    }

    private func deleteSelectedMove() {
        guard let move = selectedMove else { return }

        let key = move.storageKey

        guard key.hasPrefix("custom_barbell_") else {
            selectedMove = nil
            return
        }

        removeValue(for: key)
        removeHistory(for: key)

        var list = loadCustomMoves()
        list.removeAll { $0.storageKey == key }
        saveCustomMoves(list)

        selectedMove = nil
    }

    /// Formata um `Double` para exibição com convenção brasileira (vírgula decimal, 2 casas).
    private func formatNumber(_ value: Double) -> String {
        WeightParser.brazilianFormat(value)
    }

    private func formatPRDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "dd 'de' MMMM, yyyy"
        return formatter.string(from: date)
    }

    private func bestPRValueKg(for key: String) -> Double? {
        let historyBest = historyEntries(for: key)
            .map(\.valueKg)
            .max()
        let legacyValue = loadValue(for: key)

        switch (historyBest, legacyValue) {
        case let (history?, legacy?):
            return max(history, legacy)
        case let (history?, nil):
            return history
        case let (nil, legacy?):
            return legacy
        case (nil, nil):
            return nil
        }
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

    private func loadHistoryMap() -> [String: [BarbellPRHistoryEntry]] {
        guard !barbellHistoryData.isEmpty else { return [:] }
        do {
            return try JSONDecoder().decode([String: [BarbellPRHistoryEntry]].self, from: barbellHistoryData)
        } catch {
            return [:]
        }
    }

    private func saveHistoryMap(_ map: [String: [BarbellPRHistoryEntry]]) {
        do {
            barbellHistoryData = try JSONEncoder().encode(map)
        } catch {
            barbellHistoryData = Data()
        }
    }

    private func historyEntries(for key: String) -> [BarbellPRHistoryEntry] {
        loadHistoryMap()[key, default: []].sorted { $0.createdAt < $1.createdAt }
    }

    private func saveHistoryValue(_ valueKg: Double, for key: String, date: Date) {
        var map = loadHistoryMap()
        var entries = map[key, default: []].sorted { $0.createdAt < $1.createdAt }
        let normalizedDate = Calendar.current.startOfDay(for: date)

        if entries.contains(where: {
            abs($0.valueKg - valueKg) < 0.000_001 &&
            Calendar.current.isDate($0.createdAt, inSameDayAs: normalizedDate)
        }) {
            return
        }

        entries.append(
            BarbellPRHistoryEntry(
                id: UUID().uuidString,
                valueKg: valueKg,
                createdAt: normalizedDate
            )
        )
        map[key] = entries
        saveHistoryMap(map)
    }

    private func removeHistory(for key: String) {
        var map = loadHistoryMap()
        map.removeValue(forKey: key)
        saveHistoryMap(map)
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
