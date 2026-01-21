// StudentDayDetailView.swift — Detalhe de um dia de treino com edição (professor) e visualização (aluno)
import SwiftUI
import UIKit
import Foundation

struct StudentDayDetailView: View {

    // Bindings e parâmetros necessários (weekId para operações Firestore)
    @Binding var path: [AppRoute]
    let weekId: String
    let day: TrainingDayFS
    let weekTitle: String

    @EnvironmentObject private var session: AppSession

    private let contentMaxWidth: CGFloat = 380

    // Estados de edição/exclusão
    @State private var showEditSheet: Bool = false
    @State private var showDeleteConfirm: Bool = false
    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil

    // Campos de edição locais
    @State private var editTitle: String = ""
    @State private var editDescription: String = ""
    @State private var editBlocks: [BlockFS] = []

    @State private var didPrepareEditFields: Bool = false

    private var isTeacherViewing: Bool { session.userType == .TRAINER }

    // ✅ Player de vídeo (mesmo comportamento da TeacherImportVideosView)
    @State private var activeLockedPlayer: LockedPlayerItem? = nil

    // ✅ Remoção do vídeo do dia
    @State private var showRemoveVideoConfirm: Bool = false
    @State private var videoPendingRemove: VideoDayItem? = nil

    // MARK: - Modelo local para exibir vídeo vindo de BlockFS
    private struct VideoDayItem: Identifiable, Hashable {
        let blockId: String
        let videoId: String
        let url: String

        var id: String { "video-\(blockId)" }
    }

    // ✅ Detecta blocos "Vídeo" e extrai o videoId
    private var videoItems: [VideoDayItem] {
        day.blocks.compactMap { b in
            let nameTrim = b.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard nameTrim.caseInsensitiveCompare("Vídeo") == .orderedSame else { return nil }

            let urlTrim = b.details.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let vid = YouTubeVideoImporter.extractYoutubeVideoId(from: urlTrim) else { return nil }

            return VideoDayItem(blockId: b.id, videoId: vid, url: urlTrim)
        }
    }

    // ✅ Blocos normais (sem os blocos de vídeo)
    private var nonVideoBlocks: [BlockFS] {
        if videoItems.isEmpty { return day.blocks }
        let videoIds = Set(videoItems.map { $0.blockId })
        return day.blocks.filter { !videoIds.contains($0.id) }
    }

    // ✅ Quando existe vídeo no dia: remover "Visualizar no ambiente", blocos e agora também o card "Treino"
    private var shouldShowOnlyVideoForStudent: Bool {
        !isTeacherViewing && !videoItems.isEmpty
    }

    // MARK: - ✅ NOVO: % do PR (Barbell) no dia

    private struct BarbellMove: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let storageKey: String
    }

    private let barbellMoves: [BarbellMove] = [
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

    // ✅ Fonte do PR (mesma chave usada na tela Barbell)
    @AppStorage("student_pr_barbell_values_v1")
    private var barbellValuesData: Data = Data()

    // ✅ Persistência por dia (movimento + porcentagem)
    @AppStorage("student_day_pr_calc_v1")
    private var dayCalcData: Data = Data()

    private struct DayCalcState: Codable, Hashable {
        var movementKey: String
        var percent: Double
    }

    @State private var showMovementPicker: Bool = false
    @State private var selectedMovementKey: String? = nil
    @State private var selectedMovementName: String? = nil
    @State private var percentText: String = ""

    // Corpo principal com header, conteúdo do dia, blocos e footer
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
                    VStack(spacing: 16) {
                        header

                        if let err = errorMessage {
                            messageCard(text: err)
                        }

                        // ✅ Se for vídeo para aluno, não mostra o card "Treino"
                        if !shouldShowOnlyVideoForStudent {
                            trainingCard
                        }

                        // ✅ Card de vídeos (quando houver)
                        if !videoItems.isEmpty {
                            videosCard
                        }

                        // ✅ Blocos (somente quando não há vídeo para aluno)
                        if !shouldShowOnlyVideoForStudent {
                            blocksCard
                        }

                        // ✅ NOVO: cálculo % PR (somente aluno e quando não é "somente vídeo") — no final
                        if !isTeacherViewing && !shouldShowOnlyVideoForStudent {
                            prPercentCard
                        }
                    }
                    .frame(maxWidth: contentMaxWidth)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                    .frame(maxWidth: .infinity)
                }

                footer
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

            // ✅ ALTERADO: título do cabeçalho agora é o dia (ex: "Dia 1")
            ToolbarItem(placement: .principal) {
                Text(day.subtitleText)
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if isTeacherViewing {
                    Menu {
                        Button {
                            didPrepareEditFields = false
                            showEditSheet = true
                        } label: {
                            Label("Editar", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Excluir", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)
                }

                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .alert("Excluir dia?", isPresented: $showDeleteConfirm) {
            Button("Cancelar", role: .cancel) {}
            Button("Excluir", role: .destructive) {
                Task { await deleteDay() }
            }
        } message: {
            Text("O dia \"\(day.title)\" será excluído.")
        }
        .alert("Remover vídeo?", isPresented: $showRemoveVideoConfirm) {
            Button("Cancelar", role: .cancel) {
                videoPendingRemove = nil
            }
            Button("Remover", role: .destructive) {
                guard let item = videoPendingRemove else { return }
                Task { await removeVideoFromDay(item: item) }
            }
        } message: {
            Text("Este vídeo será removido do dia de treino.")
        }
        .sheet(isPresented: $showEditSheet, onDismiss: {
            didPrepareEditFields = false
        }) {
            editDaySheet
                .onAppear {
                    guard !didPrepareEditFields else { return }
                    prepareEditFields()
                    didPrepareEditFields = true
                }
        }
        .sheet(isPresented: $showMovementPicker) {
            movementPickerSheet
        }
        .fullScreenCover(item: $activeLockedPlayer) { item in
            TeacherYoutubeLockedPlayerSheet(title: item.title, videoId: item.videoId)
        }
        .onAppear {
            loadSavedCalcIfExists()
        }
        .onChange(of: selectedMovementKey) { _, _ in
            autoSaveCalcState()
        }
        .onChange(of: percentText) { _, _ in
            autoSaveCalcState()
        }
    }

    // Footer padrão da Agenda
    private var footer: some View {
        FooterBar(
            path: $path,
            kind: .agendaSobrePerfil(
                isAgendaSelected: true,
                isSobreSelected: false,
                isPerfilSelected: false
            )
        )
        .frame(height: Theme.Layout.footerHeight)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.footerBackground)
    }

    // Header com título e subtítulo
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {

            // ✅ ALTERADO: manter apenas a semana no corpo (o dia foi para o cabeçalho)
            Text("Semana: \(weekTitle)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Card principal do treino
    private var trainingCard: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text("Treino")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.75))

            VStack(alignment: .leading, spacing: 6) {
                Text(day.title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))

                if let dateText = formattedDate(day.date) {
                    Text(dateText)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.45))
                }

                if !day.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(day.description)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.65))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    // MARK: - ✅ NOVO CARD: cálculo % do PR
    // ✅ ALTERADO: Movimento em uma linha; % e Peso na linha de baixo; alinhamento/laterais igual aos outros cards.

    private var prPercentCard: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text("Cálculo por % do PR (Barbell)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.75))

            VStack(spacing: 10) {

                // Linha 1: Movimento (full)
                Button {
                    showMovementPicker = true
                } label: {
                    HStack(spacing: 10) {

                        Image(systemName: "dumbbell.fill")
                            .foregroundColor(.green.opacity(0.85))
                            .font(.system(size: 14))
                            .frame(width: 22)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Movimento")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.55))

                            Text(selectedMovementName ?? "Selecionar")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.92))
                                .lineLimit(1)
                        }

                        Spacer(minLength: 6)

                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.35))
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                // Linha 2: Porcentagem + Peso
                HStack(spacing: 10) {

                    // % (largura fixa)
                    HStack(spacing: 10) {

                        Image(systemName: "percent")
                            .foregroundColor(.green.opacity(0.85))
                            .font(.system(size: 14))
                            .frame(width: 22)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("%")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.55))

                            TextField("Ex: 50", text: $percentText)
                                .keyboardType(.decimalPad)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.92))
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .frame(width: 120)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )

                    // Peso (ocupa o resto)
                    HStack(spacing: 10) {

                        Image(systemName: "scalemass.fill")
                            .foregroundColor(.green.opacity(0.85))
                            .font(.system(size: 14))
                            .frame(width: 22)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Peso")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.55))

                            Text(calculatedWeightText())
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.92))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
            }

            Text("Os dados ficam salvos automaticamente para este dia.")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.45))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    private var movementPickerSheet: some View {
        ZStack {
            Theme.Colors.headerBackground
                .ignoresSafeArea()

            VStack(spacing: 14) {

                Capsule()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 44, height: 5)
                    .padding(.top, 10)

                Text("Selecione o movimento")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 4)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(Array(barbellMoves.enumerated()), id: \.element.id) { idx, move in

                            Button {
                                selectedMovementKey = move.storageKey
                                selectedMovementName = move.name
                                showMovementPicker = false
                            } label: {
                                HStack(spacing: 12) {

                                    Image(systemName: "dumbbell.fill")
                                        .foregroundColor(.green.opacity(0.85))
                                        .font(.system(size: 15))
                                        .frame(width: 26)

                                    Text(move.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.92))
                                        .lineLimit(1)

                                    Spacer()

                                    if move.storageKey == selectedMovementKey {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green.opacity(0.90))
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.white.opacity(0.18))
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if idx < barbellMoves.count - 1 {
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
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .padding(.bottom, 18)
                }

                Button {
                    showMovementPicker = false
                } label: {
                    Text("Fechar")
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
                        .padding(.horizontal, 16)
                }
                .buttonStyle(.plain)

                Spacer(minLength: 10)
            }
        }
        .presentationDetents([.large])
    }

    private func calculatedWeightText() -> String {
        guard let key = selectedMovementKey else { return "—" }
        guard let pr = loadPR(for: key), pr > 0 else { return "—" }
        guard let pct = parsePercent(), pct > 0 else { return "—" }

        let result = pr * (pct / 100.0)
        return "\(formatNumber(result)) kg"
    }

    private func parsePercent() -> Double? {
        let trimmed = percentText
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed)
    }

    private func formatNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.decimalSeparator = "."
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func loadPRMap() -> [String: Double] {
        guard !barbellValuesData.isEmpty else { return [:] }
        do {
            return try JSONDecoder().decode([String: Double].self, from: barbellValuesData)
        } catch {
            return [:]
        }
    }

    private func loadPR(for key: String) -> Double? {
        let map = loadPRMap()
        return map[key]
    }

    private func calcStorageKeyForThisDay() -> String {
        let dayId = (day.id ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let safeDayId = dayId.isEmpty ? "dayIndex_\(day.dayIndex)" : dayId
        return "wk_\(weekId)_\(safeDayId)"
    }

    private func loadCalcMap() -> [String: DayCalcState] {
        guard !dayCalcData.isEmpty else { return [:] }
        do {
            return try JSONDecoder().decode([String: DayCalcState].self, from: dayCalcData)
        } catch {
            return [:]
        }
    }

    private func saveCalcMap(_ map: [String: DayCalcState]) {
        do {
            dayCalcData = try JSONEncoder().encode(map)
        } catch {
            dayCalcData = Data()
        }
    }

    private func loadSavedCalcIfExists() {
        let map = loadCalcMap()
        let key = calcStorageKeyForThisDay()

        guard let saved = map[key] else { return }

        selectedMovementKey = saved.movementKey
        selectedMovementName = barbellMoves.first(where: { $0.storageKey == saved.movementKey })?.name
        percentText = formatNumber(saved.percent)
    }

    private func autoSaveCalcState() {
        guard !isTeacherViewing else { return }

        let storageKey = calcStorageKeyForThisDay()
        var map = loadCalcMap()

        guard let movementKey = selectedMovementKey,
              let pct = parsePercent() else {
            map.removeValue(forKey: storageKey)
            saveCalcMap(map)
            return
        }

        map[storageKey] = DayCalcState(movementKey: movementKey, percent: pct)
        saveCalcMap(map)
    }

    // MARK: - ✅ Vídeos (mesma UI da TeacherImportVideosView, só com Remover)

    private var videosCard: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text("Vídeos")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.75))

            VStack(spacing: 0) {
                ForEach(Array(videoItems.enumerated()), id: \.offset) { idx, item in
                    videoRow(item: item)
                        .contentShape(Rectangle())

                    if idx < videoItems.count - 1 {
                        innerDivider(leading: 14)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    private func openLockedPlayer(item: VideoDayItem) {
        let titleTrim = day.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeTitle = titleTrim.isEmpty ? "Vídeo do YouTube" : titleTrim

        activeLockedPlayer = LockedPlayerItem(
            title: safeTitle,
            videoId: item.videoId
        )
    }

    private func requestRemoveVideo(item: VideoDayItem) {
        errorMessage = nil
        videoPendingRemove = item
        showRemoveVideoConfirm = true
    }

    private func videoRow(item: VideoDayItem) -> some View {
        HStack(spacing: 12) {

            thumbnailView(videoId: item.videoId)

            VStack(alignment: .leading, spacing: 4) {
                let titleTrim = day.title.trimmingCharacters(in: .whitespacesAndNewlines)
                Text(titleTrim.isEmpty ? "Vídeo do YouTube" : titleTrim)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(1)

                Text("YouTube")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(1)
            }

            Spacer()

            Menu {
                Button(role: .destructive) {
                    requestRemoveVideo(item: item)
                } label: {
                    Label("Remover", systemImage: "trash.fill")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.55))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                openLockedPlayer(item: item)
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.35))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .onTapGesture {
            openLockedPlayer(item: item)
        }
    }

    private func thumbnailView(videoId: String) -> some View {
        let thumb = "https://img.youtube.com/vi/\(videoId)/hqdefault.jpg"

        return ZStack(alignment: .bottomTrailing) {
            AsyncImage(url: URL(string: thumb)) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color.white.opacity(0.06)
                        ProgressView().tint(.white.opacity(0.8))
                    }
                case .success(let img):
                    img.resizable().scaledToFill()
                case .failure:
                    ZStack {
                        Color.white.opacity(0.06)
                        Image(systemName: "video.fill")
                            .foregroundColor(.green.opacity(0.85))
                    }
                @unknown default:
                    Color.white.opacity(0.06)
                }
            }
            .frame(width: 66, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )

            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.45))
                Image(systemName: "play.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.95))
                    .padding(.leading, 1)
            }
            .frame(width: 18, height: 18)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .padding(6)
        }
    }

    private func removeVideoFromDay(item: VideoDayItem) async {
        errorMessage = nil

        guard let dayId = day.id, !dayId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Dia inválido: id não encontrado."
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let updatedBlocks = day.blocks.filter { $0.id != item.blockId }

            _ = try await FirestoreRepository.shared.upsertDay(
                weekId: weekId,
                dayId: dayId,
                dayIndex: day.dayIndex,
                dayName: day.dayName,
                date: day.date ?? Date(),
                title: day.title,
                description: day.description,
                blocks: updatedBlocks
            )

            // Mantém fluxo estável, igual ao salvar edição: volta para recarregar.
            pop()

        } catch {
            errorMessage = (error as NSError).localizedDescription
        }
    }

    // Lista de blocos do dia
    private var blocksCard: some View {
        VStack(alignment: .leading, spacing: 10) {

            if nonVideoBlocks.isEmpty && videoItems.isEmpty {
                Text("Nenhum bloco cadastrado.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.55))
            } else if nonVideoBlocks.isEmpty {
                // ✅ Se só existem vídeos, não exibe mensagem "nenhum bloco"
                EmptyView()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(nonVideoBlocks.enumerated()), id: \.offset) { idx, block in
                        VStack(alignment: .leading, spacing: 6) {

                            Text(block.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.92))
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if !block.details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(block.details)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.65))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)

                        if idx < nonVideoBlocks.count - 1 {
                            innerDivider(leading: 0)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    // Mensagem de erro/aviso estilizada
    private func messageCard(text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow.opacity(0.85))
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.75))
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.35))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func innerDivider(leading: CGFloat) -> some View {
        Divider()
            .background(Theme.Colors.divider)
            .padding(.leading, leading)
    }

    private func formattedDate(_ date: Date?) -> String? {
        guard let date else { return nil }
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateStyle = .medium
        return f.string(from: date)
    }

    // Edit helpers: prepara os campos de edição a partir do modelo atual
    private func prepareEditFields() {
        editTitle = day.title
        editDescription = day.description
        editBlocks = day.blocks
        errorMessage = nil
    }

    // Sheet de edição com campos e botões de ação
    private var editDaySheet: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {

                Text("Editar dia de treino")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))

                UnderlineTextField(
                    title: "Título",
                    text: $editTitle,
                    isSecure: false,
                    showPassword: .constant(false),
                    lineColor: Theme.Colors.divider,
                    textColor: .white.opacity(0.92),
                    placeholderColor: .white.opacity(0.55)
                )

                UnderlineTextField(
                    title: "Descrição",
                    text: $editDescription,
                    isSecure: false,
                    showPassword: .constant(false),
                    lineColor: Theme.Colors.divider,
                    textColor: .white.opacity(0.92),
                    placeholderColor: .white.opacity(0.55)
                )

                Divider().background(Theme.Colors.divider)

                // Blocos editor section
                blocksEditorSection

                Divider().background(Theme.Colors.divider)

                HStack(spacing: 10) {

                    Button { showEditSheet = false } label: {
                        Text("Cancelar")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.90))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.10))
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)

                    Button { Task { await saveDayEdits() } } label: {
                        HStack(spacing: 8) {
                            if isSaving { ProgressView().tint(.white) }
                            Text("Salvar")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.green.opacity(0.16))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green.opacity(0.35), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)

                    Spacer()
                }

                Spacer()
            }
            .padding(16)
            .frame(maxWidth: 420)
        }
        .presentationDetents([.medium])
    }

    private var blocksEditorSection: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text("Blocos")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.75))

            if editBlocks.isEmpty {
                Text("Nenhum bloco cadastrado para este dia.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.55))
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(editBlocks.indices, id: \.self) { i in
                            VStack(alignment: .leading, spacing: 8) {

                                Text(editBlocks[i].name)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.92))

                                TextEditor(text: Binding(
                                    get: { editBlocks[i].details },
                                    set: { editBlocks[i].details = $0 }
                                ))
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.85))
                                .scrollContentBackground(.hidden)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(10)
                                .frame(minHeight: 70)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.top, 2)
                }
                .frame(maxHeight: 220)
            }
        }
    }

    private func saveDayEdits() async {
        errorMessage = nil

        guard let dayId = day.id, !dayId.isEmpty else {
            errorMessage = "Dia inválido: id não encontrado."
            return
        }

        let t = editTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else {
            errorMessage = "Informe o título do dia."
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            _ = try await FirestoreRepository.shared.upsertDay(
                weekId: weekId,
                dayId: dayId,
                dayIndex: day.dayIndex,
                dayName: day.dayName,
                date: day.date ?? Date(),
                title: t,
                description: editDescription,
                blocks: editBlocks
            )
            showEditSheet = false

            // ✅ Mantém fluxo estável: volta para a tela anterior para evitar estado desatualizado.
            pop()

        } catch {
            errorMessage = (error as NSError).localizedDescription
        }
    }

    // Exclui dia do Firestore
    private func deleteDay() async {
        errorMessage = nil

        guard let dayId = day.id, !dayId.isEmpty else {
            errorMessage = "Dia inválido: id não encontrado."
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            try await FirestoreRepository.shared.deleteTrainingDay(weekId: weekId, dayId: dayId)
            pop()
        } catch {
            errorMessage = (error as NSError).localizedDescription
        }
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

