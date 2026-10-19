import SwiftUI
import Charts

// Tela do Aluno: Recorde Pessoal > Barbell (lista fixa de movimentos + carga máxima)
struct BarbellPersonalRecordsView: View {
    @Environment(\.locale) private var locale
    @Environment(\.appTheme) private var appTheme

    // Paleta do Tema Claro (mesmos valores da `LightColors` da TrainingWeeksView; Tema Escuro usa os valores originais)
    private enum LightColors {
        static let cardSurface = Color(red: 0xDD / 255, green: 0xED / 255, blue: 0xDC / 255)  // #DDEDDC
        static let iconSurface = Color(red: 0x85 / 255, green: 0xC9 / 255, blue: 0x95 / 255)  // #85C995
        static let iconInk = Color(red: 0x25 / 255, green: 0x48 / 255, blue: 0x2B / 255)      // #25482B
        static let primaryText = Color(red: 0x17 / 255, green: 0x1C / 255, blue: 0x17 / 255)  // #171C17
        static let chevron = Color(red: 0x29 / 255, green: 0x4A / 255, blue: 0x2F / 255)      // #294A2F
        static let border = Color(red: 0xC9 / 255, green: 0xDF / 255, blue: 0xC9 / 255)       // #C9DFC9
        static let contentSurface = Color(red: 0xF0 / 255, green: 0xF7 / 255, blue: 0xEF / 255) // #F0F7EF
    }

    @Binding var path: [AppRoute]

    /// Presente apenas no contexto de aluno (dentro de `StudentRootView`).
    var onSelectSection: (StudentMainSection) -> Void = { _ in }
    var navigationContext: PersonalRecordsNavigationContext = .student

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
    @State private var isEditingExistingPR: Bool = false
    @State private var editingHistoryEntryID: String? = nil
    @State private var historyEntryPendingDeletion: BarbellPRHistoryEntry?
    @State private var showHistoryEntryDeletionAlert: Bool = false

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

            AppThemeBackgroundImage()

            VStack(spacing: 0) {

                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)

                ScrollView(showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 0)

                        VStack(alignment: .leading, spacing: 14) {
                            tableContainer()

                            Color.clear.frame(height: Theme.Layout.footerHeight + 20)
                        }
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        Spacer(minLength: 0)
                    }
                }

                PersonalRecordsFooter(
                    path: $path,
                    navigationContext: navigationContext,
                    studentFooterKind: .studentHomeTreinosRecordsProfile(
                        isHomeSelected: false,
                        isTreinosSelected: false,
                        isRecordsSelected: true,
                        isPerfilSelected: false
                    ),
                    onSelectStudentSection: onSelectSection
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
                            .foregroundStyle(Theme.Colors.systemAccentForeground())
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("personal_records_barbell.barbell")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundStyle(Theme.Colors.ink())
            }

            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button {
                        addMoveErrorMessage = nil
                        newMoveName = ""
                        newMoveValue = ""
                        showAddMoveSheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                            Text("common.add")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink(0.92))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.green.opacity(0.16)))
                    }
                    .buttonStyle(.plain)

                    HeaderAvatarView(size: 38)
                }
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .appThemeLightHeaderColorScheme()
        .sheet(item: $selectedMove, onDismiss: {
            resetExistingPREditing()
        }) { move in
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
                .fill(Theme.Colors.ink(0.08))
                .frame(height: 1)

            let list = allMoves

            ForEach(Array(list.enumerated()), id: \.element.id) { index, move in

                tableRow(move: move)

                if index != list.count - 1 {
                    Rectangle()
                        .fill(Theme.Colors.ink(0.08))
                        .frame(height: 1)
                        .padding(.leading, 14)
                }
            }
        }
        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.cardSurface))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.border), lineWidth: 1)
        )
        .shadow(
            color: appTheme == .light ? .black.opacity(0.25) : .clear,
            radius: appTheme == .light ? 10 : 0,
            y: appTheme == .light ? 6 : 0
        )
    }

    private func tableHeader() -> some View {
        HStack(spacing: 10) {

            Color.clear
                .frame(width: 26, height: 1)

            Text("personal_records.movement")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.55), light: LightColors.primaryText))

            Spacer()

            Text(
                String(
                    format: AppLocalization.string("personal_records.barbell.pr_with_unit", locale: locale),
                    locale: locale,
                    arguments: [preferredWeightUnit.shortLabel]
                )
            )
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.55), light: LightColors.primaryText))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func tableRow(move: BarbellMove) -> some View {
        let storedKgValue = currentPRValueKg(for: move.storageKey)
        let displayValue = storedKgValue.map { convertFromStorageKgToPreferredUnit($0) }

        return Button {
            inputValue = ""
            selectedPRDate = Date()
            resetExistingPREditing()
            selectedMove = move
        } label: {
            HStack(spacing: 10) {

                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(AppThemeColor(dark: Color.green.opacity(0.14), light: LightColors.iconSurface))
                        .frame(width: 34, height: 34)

                    Image(systemName: "dumbbell.fill")
                        .foregroundStyle(AppThemeColor(dark: Color.green.opacity(0.85), light: LightColors.iconInk))
                        .font(.system(size: 16, weight: .semibold))
                }

                Text(move.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer()

                if let displayValue {
                    Text(formatNumber(displayValue))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.Colors.ink(0.88))
                } else {
                    Text("-")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.Colors.ink(0.45))
                }

                Image(systemName: "chevron.right")
                    .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.25), light: LightColors.chevron))
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
            Theme.Colors.sheetBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {

                Capsule()
                    .fill(Theme.Colors.ink(0.18))
                    .frame(width: 44, height: 5)
                    .padding(.top, 10)

                Text(move.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.Colors.ink())
                    .padding(.top, 4)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(
                            String(
                                format: AppLocalization.string("personal_records.barbell.max_load_with_unit", locale: locale),
                                locale: locale,
                                arguments: [preferredWeightUnit.shortLabel]
                            )
                        )
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.Colors.ink(0.75))

                        HStack(spacing: 10) {
                            TextField("personal_records_barbell.e_g_90_50", text: $inputValue)
                                .keyboardType(.decimalPad)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Theme.Colors.ink(0.92))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                // Tema Claro: superfície de conteúdo (#F0F7EF) e borda (#C9DFC9) da TrainingWeeksView. Tema Escuro: valores originais.
                                .background(AppThemeColor(dark: Theme.Colors.cardBackground.dark, light: LightColors.contentSurface))
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(AppThemeColor(dark: Theme.Colors.ink(0.08).dark, light: LightColors.border), lineWidth: 1)
                                )

                            Text(preferredWeightUnit.shortLabel)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Theme.Colors.ink(0.70))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            showPRDatePicker = true
                        } label: {
                            // Tema Claro: cores do agrupador de dias da TrainingWeeksView. Tema Escuro: valores originais.
                            HStack(spacing: 10) {
                                Image(systemName: "calendar")
                                    .foregroundStyle(AppThemeColor(dark: Theme.Colors.icon(Theme.Colors.systemAccentForeground(0.85)).dark, light: LightColors.iconInk))
                                    // Fundo do ícone (#85C995) apenas no Tema Claro; o background não altera o tamanho/layout
                                    .background {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(AppThemeColor(dark: .clear, light: LightColors.iconSurface))
                                            .frame(width: 28, height: 28)
                                    }

                                Text(formatPRDate(selectedPRDate))
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(AppThemeColor(dark: Theme.Colors.ink(0.92).dark, light: LightColors.primaryText))

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(AppThemeColor(dark: Theme.Colors.chevron(0.25).dark, light: LightColors.chevron))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                            .background(AppThemeColor(dark: Theme.Colors.cardBackground.dark, light: LightColors.cardSurface))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(AppThemeColor(dark: Theme.Colors.ink(0.08).dark, light: LightColors.border), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .foregroundStyle(Theme.Colors.icon(.green.opacity(0.90)))

                                Text("personal_records.progress")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Theme.Colors.ink(0.75))
                            }

                            Spacer()

                            Button {
                                historyMove = move
                            } label: {
                                Label {
                                    Text(LocalizedStringKey("personal_records.history"))
                                } icon: {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .foregroundStyle(Theme.Colors.icon(.green.opacity(0.90)))
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.green.opacity(0.90))
                            }
                            .buttonStyle(.plain)
                        }

                        historyChart(for: move)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    if canDeleteSelectedMove {
                        Text("personal_records_barbell.deleting_will_remove_this_record_from_your_history_this_action_cannot_be_undone")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.Colors.ink(0.50))
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                    }

                    }
                }

                HStack(spacing: 12) {

                    Button {
                        resetExistingPREditing()
                        selectedMove = nil
                    } label: {
                        Text("common.cancel")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Theme.Colors.ink(0.85))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.Colors.ink(0.10))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Theme.Colors.ink(0.10), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        saveCurrentInput()
                        resetExistingPREditing()
                        selectedMove = nil
                    } label: {
                        if appTheme == .light {
                            // Tema Claro: padrão do botão Sair da ProfileView (verde militar 80%/90% e texto branco),
                            // mantendo as dimensões/raio do `primaryGreenActionButton()`
                            Text("common.save")
                                .frame(maxWidth: .infinity)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.white)
                                .padding(.vertical, 14)
                                .background(AppThemePalette.lightBar.opacity(0.80))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppThemePalette.lightBar.opacity(0.90), lineWidth: 1)
                                )
                        } else {
                            Text("common.save")
                                .frame(maxWidth: .infinity)
                                .primaryGreenActionButton()
                        }
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
                        .accessibilityLabel("personal_records_barbell.delete_movement")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 16)
            }
        }
        .presentationDetents([.fraction(0.80)])
        .alert("personal_records_barbell.delete_record", isPresented: $showDeleteAlert) {
            Button("common.cancel", role: .cancel) { }
            Button("common.delete", role: .destructive) {
                deleteSelectedMove()
            }
        } message: {
            let format = AppLocalization.string("personal_records.barbell.delete_named_record_confirmation",
                locale: locale
            )
            Text(
                String(
                    format: format,
                    locale: locale,
                    arguments: [selectedMove?.name ?? ""]
                )
            )
        }
        .sheet(item: $historyMove) { move in
            historySheet(move: move)
        }
        .sheet(isPresented: $showPRDatePicker) {
            ZStack {
                Theme.Colors.sheetBackground
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    DatePicker(
                        "Data do PR",
                        selection: $selectedPRDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)

                    Button {
                        showPRDatePicker = false
                    } label: {
                        Text("common.confirm")
                            .frame(maxWidth: .infinity)
                            .primaryGreenActionButton()
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
        let recordID = currentPRValueKg(for: move.storageKey).flatMap {
            currentPRHistoryEntry(for: move.storageKey, valueKg: $0)?.id
        }

        return ZStack {
            Theme.Colors.sheetBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    Capsule()
                        .fill(Theme.Colors.ink(0.18))
                        .frame(width: 44, height: 5)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)

                    Text(move.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Theme.Colors.ink())
                        .frame(maxWidth: .infinity, alignment: .center)

                    Text("personal_records.history")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Theme.Colors.ink(0.92))

                    if entries.isEmpty {
                        Text("personal_records_barbell.no_progress_history_recorded_yet")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.Colors.ink(0.60))

                        Text("personal_records_barbell.save_new_prs_to_track_your_progress")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.Colors.ink(0.45))
                    } else {
                        VStack(spacing: 0) {
                            ForEach(entries.reversed()) { entry in
                                HStack(spacing: 10) {
                                    Image(systemName: entry.id == recordID ? "trophy.fill" : "medal.fill")
                                        .foregroundStyle(Theme.Colors.icon(Theme.Colors.systemAccentForeground(0.85)))
                                        .frame(width: 22)

                                    Text(
                                        String(
                                            format: AppLocalization.string("personal_records.barbell.value_with_unit",
                                                locale: locale
                                            ),
                                            locale: locale,
                                            arguments: [
                                                formatNumber(convertFromStorageKgToPreferredUnit(entry.valueKg)),
                                                preferredWeightUnit.shortLabel
                                            ]
                                        )
                                    )
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(Theme.Colors.ink(0.92))

                                    if entry.id == recordID {
                                        Text("personal_records_barbell.record")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(Theme.Colors.systemAccentForeground())
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color.green.opacity(0.70), lineWidth: 1)
                                            )
                                    }

                                    Spacer()

                                    Text(entry.createdAt.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year().locale(locale)))
                                        .font(.system(size: 14))
                                        .foregroundStyle(Theme.Colors.ink(0.45))

                                    Button {
                                        historyEntryPendingDeletion = entry
                                        showHistoryEntryDeletionAlert = true
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.red.opacity(0.85))
                                            .frame(width: 28, height: 28)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("personal_records_barbell.delete_record")
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)

                                if entry.id != entries.first?.id {
                                    Rectangle()
                                        .fill(Theme.Colors.ink(0.08))
                                        .frame(height: 1)
                                        .padding(.leading, 14)
                                }
                            }
                        }
                        .background(Theme.Colors.cardBackground)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Theme.Colors.ink(0.08), lineWidth: 1)
                        )
                    }
                }
                .frame(maxWidth: contentMaxWidth)
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .presentationDetents([.large])
        .alert("personal_records_barbell.delete_record", isPresented: $showHistoryEntryDeletionAlert) {
            Button("common.cancel", role: .cancel) {
                historyEntryPendingDeletion = nil
            }
            Button("common.delete", role: .destructive) {
                if let entry = historyEntryPendingDeletion {
                    deleteHistoryEntry(entry, for: move.storageKey)
                }
                historyEntryPendingDeletion = nil
            }
        } message: {
            Text("personal_records_barbell.do_you_want_to_delete_this_history_record_this_action_cannot_be_undone")
        }
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
                .foregroundStyle(Theme.Colors.systemAccentForeground())
                .interpolationMethod(.linear)

                PointMark(
                    x: .value("Data", entry.createdAt),
                    y: .value("Carga", convertFromStorageKgToPreferredUnit(entry.valueKg))
                )
                .foregroundStyle(Theme.Colors.systemAccentForeground())
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) {
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Theme.Colors.ink(0.12))
                    AxisValueLabel(format: .dateTime.day(.twoDigits).month(.twoDigits).year())
                        .foregroundStyle(Theme.Colors.ink(0.55))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Theme.Colors.ink(0.12))
                    AxisValueLabel()
                        .foregroundStyle(Theme.Colors.ink(0.55))
                }
            }
            .frame(height: 170)
            .padding(14)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.Colors.ink(0.08), lineWidth: 1)
            )
        }
    }

    // MARK: - Sheet (adicionar movimento)
    private func addMoveSheet() -> some View {
        ZStack {
            Theme.Colors.sheetBackground
                .ignoresSafeArea()

            VStack(spacing: 14) {

                Capsule()
                    .fill(Theme.Colors.ink(0.18))
                    .frame(width: 44, height: 5)
                    .padding(.top, 10)

                Text("personal_records_barbell.new_movement")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.Colors.ink())
                    .padding(.top, 4)

                Text(
                    String(
                        format: AppLocalization.string("personal_records.barbell.new_movement_description",
                            locale: locale
                        ),
                        locale: locale,
                        arguments: [preferredWeightUnit.shortLabel]
                    )
                )
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.ink(0.60))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 10) {

                    VStack(alignment: .leading, spacing: 8) {
                        Text("personal_records_barbell.movement_name")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.Colors.ink(0.75))

                        TextField("personal_records_barbell.e_g_bulgarian_split_squat", text: $newMoveName)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled(true)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.Colors.ink(0.92))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Theme.Colors.ink(0.08), lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(
                            String(
                                format: AppLocalization.string("personal_records.barbell.max_load_optional_with_unit",
                                    locale: locale
                                ),
                                locale: locale,
                                arguments: [preferredWeightUnit.shortLabel]
                            )
                        )
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.Colors.ink(0.75))

                        HStack(spacing: 10) {
                            TextField("personal_records_barbell.e_g_90_50", text: $newMoveValue)
                                .keyboardType(.decimalPad)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Theme.Colors.ink(0.92))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .background(Theme.Colors.cardBackground)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Theme.Colors.ink(0.08), lineWidth: 1)
                                )

                            Text(preferredWeightUnit.shortLabel)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Theme.Colors.ink(0.70))
                        }
                    }

                    if let msg = addMoveErrorMessage {
                        Text(msg)
                            .font(.system(size: 14, weight: .semibold))
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
                        Text("common.cancel")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Theme.Colors.ink(0.85))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.Colors.ink(0.10))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Theme.Colors.ink(0.10), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        addNewMove()
                    } label: {
                        Text("common.add")
                            .frame(maxWidth: .infinity)
                            .primaryGreenActionButton()
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
            addMoveErrorMessage = AppLocalization.string("personal_records.barbell.movement_name_required",
                locale: locale
            )
            return
        }

        let existingNames = allMoves.map { $0.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
        if existingNames.contains(cleanName.lowercased()) {
            addMoveErrorMessage = AppLocalization.string("personal_records.barbell.duplicate_movement",
                locale: locale
            )
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
            saveCurrentPR(storageKg, for: key, date: Date())
        }

        showAddMoveSheet = false
    }

    private func saveCurrentInput() {
        guard let move = selectedMove else { return }

        let trimmed = inputValue.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return
        }

        // ✅ Usa WeightParser que aceita vírgula e ponto, valida casas decimais
        if let value = WeightParser.parse(trimmed), value > 0 {
            let storageKg = convertFromPreferredUnitToStorageKg(value)
            saveCurrentPR(storageKg, for: move.storageKey, date: selectedPRDate)
        }
    }

    private func beginEditingExistingPR(for move: BarbellMove) {
        guard let valueKg = currentPRValueKg(for: move.storageKey) else { return }

        inputValue = formatNumber(convertFromStorageKgToPreferredUnit(valueKg))
        if let entry = currentPRHistoryEntry(for: move.storageKey, valueKg: valueKg) {
            editingHistoryEntryID = entry.id
            selectedPRDate = entry.createdAt
        } else {
            editingHistoryEntryID = nil
        }
        isEditingExistingPR = true
    }

    private func beginNewPR() {
        inputValue = ""
        selectedPRDate = Date()
        resetExistingPREditing()
    }

    private func saveExistingPREdit() {
        guard let move = selectedMove else { return }

        let trimmed = inputValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = WeightParser.parse(trimmed), value > 0 else { return }

        let valueKg = convertFromPreferredUnitToStorageKg(value)
        let key = move.storageKey
        var history = loadHistoryMap()

        if let entryID = editingHistoryEntryID {
            var entries = history[key, default: []]
            guard let index = entries.firstIndex(where: { $0.id == entryID }) else {
                var values = loadMap()
                values[key] = valueKg
                saveBarbellRecords(values: values, history: history)
                return
            }

            let entry = entries[index]
            entries[index] = BarbellPRHistoryEntry(
                id: entry.id,
                valueKg: valueKg,
                createdAt: Calendar.current.startOfDay(for: selectedPRDate)
            )
            history[key] = entries
            var values = loadMap()
            values[key] = entries.map(\.valueKg).max()
            saveBarbellRecords(values: values, history: history)
        } else {
            var values = loadMap()
            values[key] = valueKg
            saveBarbellRecords(values: values, history: history)
        }
    }

    private func resetExistingPREditing() {
        isEditingExistingPR = false
        editingHistoryEntryID = nil
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
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("dMMMMyyyy")
        return formatter.string(from: date)
    }

    private func currentPRValueKg(for key: String) -> Double? {
        historyEntries(for: key).map(\.valueKg).max() ?? loadValue(for: key)
    }

    private func currentPRHistoryEntry(for key: String, valueKg: Double) -> BarbellPRHistoryEntry? {
        historyEntries(for: key)
            .filter { abs($0.valueKg - valueKg) < 0.000_001 }
            .max { $0.createdAt < $1.createdAt }
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
private extension BarbellPersonalRecordsView {

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
        PersonalRecordsSyncService.shared.didMutateLocalRecords()
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
        PersonalRecordsSyncService.shared.didMutateLocalRecords()
    }

    private func historyEntries(for key: String) -> [BarbellPRHistoryEntry] {
        loadHistoryMap()[key, default: []].sorted { $0.createdAt < $1.createdAt }
    }

    private func saveCurrentPR(_ valueKg: Double, for key: String, date: Date) {
        var values = loadMap()
        var map = loadHistoryMap()
        var entries = map[key, default: []].sorted { $0.createdAt < $1.createdAt }
        let normalizedDate = Calendar.current.startOfDay(for: date)

        entries.append(
            BarbellPRHistoryEntry(
                id: UUID().uuidString,
                valueKg: valueKg,
                createdAt: normalizedDate
            )
        )
        map[key] = entries
        values[key] = entries.map(\.valueKg).max()
        saveBarbellRecords(values: values, history: map)
    }

    private func deleteHistoryEntry(_ entry: BarbellPRHistoryEntry, for key: String) {
        var values = loadMap()
        var history = loadHistoryMap()
        var entries = history[key, default: []]
        entries.removeAll { $0.id == entry.id }

        if entries.isEmpty {
            history.removeValue(forKey: key)
            values.removeValue(forKey: key)
        } else {
            history[key] = entries
            values[key] = entries.map(\.valueKg).max()
        }

        saveBarbellRecords(
            values: values,
            history: history,
            deletedHistoryEntryID: entry.id
        )
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

    private func saveBarbellRecords(
        values: [String: Double],
        history: [String: [BarbellPRHistoryEntry]],
        deletedHistoryEntryID: String? = nil
    ) {
        do {
            barbellValuesData = try JSONEncoder().encode(values)
            barbellHistoryData = try JSONEncoder().encode(history)
            if let deletedHistoryEntryID {
                PersonalRecordsSyncService.shared.didDeleteBarbellHistoryEntry(id: deletedHistoryEntryID)
            } else {
                PersonalRecordsSyncService.shared.didMutateLocalRecords()
            }
        } catch {
            #if DEBUG
            print("[BarbellPR] Falha ao preparar valores e histórico: \(error.localizedDescription)")
            #endif
        }
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
        PersonalRecordsSyncService.shared.didMutateLocalRecords()
    }

}
