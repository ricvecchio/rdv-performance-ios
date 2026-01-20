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

            ToolbarItem(placement: .principal) {
                Text("Dia de treino")
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
        .fullScreenCover(item: $activeLockedPlayer) { item in
            TeacherYoutubeLockedPlayerSheet(title: item.title, videoId: item.videoId)
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

            Text("Semana: \(weekTitle)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.55))

            Text(day.subtitleText)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))
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

