import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import SafariServices
import UIKit
import AVKit
import WebKit
import UniformTypeIdentifiers

import CoreXLSX

struct TeacherImportWorkoutsView: View {

    @Binding var path: [AppRoute]
    let category: TreinoTipo

    private let contentMaxWidth: CGFloat = 380

    @State private var workouts: [TeacherImportedWorkout] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    @State private var isAddSheetPresented: Bool = false

    @State private var isTemplateSharePresented: Bool = false
    @State private var templateFileURL: URL? = nil

    @State private var isImportPickerPresented: Bool = false
    @State private var isImporting: Bool = false

    @State private var activeSheet: ActiveSheet? = nil

    private enum ActiveSheet: Identifiable {
        case detail(TeacherImportedWorkout)

        var id: String {
            switch self {
            case .detail(let w):
                return "detail-\(w.id)"
            }
        }
    }

    private let templateResourceName: String = "rdv_import_treinos_template_pt_crossfit"
    private let templateResourceExtension: String = "xlsx"

    private var xlsxUTType: UTType { UTType(filenameExtension: "xlsx") ?? .data }

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

                            header

                            actionsRow

                            contentCard

                            if isImporting {
                                messageCard(text: "Importando planilha... aguarde.", isError: false)
                            }

                            if let err = errorMessage {
                                messageCard(text: err, isError: true)
                            }

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
                    kind: .teacherHomeAlunosSobrePerfil(
                        selectedCategory: category,
                        isHomeSelected: false,
                        isAlunosSelected: false,
                        isSobreSelected: false,
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
                Text("Importar Treinos")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
                    .lineLimit(1)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await loadWorkouts() }
        .onAppear { Task { await loadWorkouts() } }

        .sheet(isPresented: $isAddSheetPresented) {
            TeacherAddWorkoutSheet { title in
                Task { await addWorkout(title: title) }
            }
        }

        .sheet(isPresented: $isTemplateSharePresented) {
            if let url = templateFileURL {
                ActivityView(activityItems: [url])
                    .ignoresSafeArea()
            } else {
                ZStack {
                    Color.black.opacity(0.95).ignoresSafeArea()
                    VStack(spacing: 12) {

                        Text("Falha ao localizar a planilha no Bundle")
                            .foregroundColor(.white.opacity(0.90))
                            .font(.system(size: 16, weight: .semibold))
                            .multilineTextAlignment(.center)

                        Text(errorMessage ?? "Sem detalhes.")
                            .foregroundColor(.white.opacity(0.70))
                            .font(.system(size: 13))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 18)

                        Button("Fechar") { isTemplateSharePresented = false }
                            .foregroundColor(.green)
                    }
                    .padding()
                }
            }
        }

        .sheet(isPresented: $isImportPickerPresented) {
            DocumentPicker(
                allowedContentTypes: [xlsxUTType],
                onPick: { pickedURL in
                    Task { await handlePickedExcel(url: pickedURL) }
                },
                onCancel: { }
            )
            .ignoresSafeArea()
        }

        .sheet(item: $activeSheet, onDismiss: {
            Task { await loadWorkouts() }
        }) { sheet in
            switch sheet {
            case .detail(let w):
                TeacherImportedWorkoutDetailsSheet(
                    workout: w,
                    onSendToStudent: {
                        sendImportedWorkoutToStudent(workout: w)
                    }
                )
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Importe treinos via planilha para cadastrar automaticamente.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actionsRow: some View {
        HStack(spacing: 10) {

            Button {
                errorMessage = nil
                isImportPickerPresented = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Importar Excel")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.green.opacity(0.16)))
            }
            .buttonStyle(.plain)
            .disabled(isImporting)

            Spacer(minLength: 0)

            Button {
                errorMessage = nil
                prepareTemplateShare()
            } label: {
                HStack {
                    Image(systemName: "arrow.down.doc")
                    Text("Baixar Planilha Excel")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.green.opacity(0.16)))
            }
            .buttonStyle(.plain)
        }
    }

    private var contentCard: some View {
        VStack(spacing: 0) {
            if isLoading {
                loadingView
            } else if workouts.isEmpty {
                emptyView
            } else {
                workoutsList
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var workoutsList: some View {
        VStack(spacing: 0) {
            ForEach(workouts.indices, id: \.self) { idx in
                let w = workouts[idx]

                importedWorkoutRow(workout: w)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        openDetails(for: w)
                    }

                if idx < workouts.count - 1 {
                    innerDivider(leading: 14)
                }
            }
        }
    }

    private func importedWorkoutRow(workout w: TeacherImportedWorkout) -> some View {
        HStack(spacing: 12) {

            Image(systemName: "dumbbell.fill")
                .foregroundColor(.green.opacity(0.85))
                .font(.system(size: 16))
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 4) {
                Text(w.title.isEmpty ? "Treino" : w.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(1)

                Text("Importado via Excel")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(1)
            }

            Spacer()

            Menu {
                Button {
                    sendImportedWorkoutToStudent(workout: w)
                } label: {
                    Label("Enviar para aluno", systemImage: "paperplane.fill")
                }

                Button(role: .destructive) {
                    Task { await deleteWorkout(workoutId: w.id) }
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

            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.35))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }

    private var loadingView: some View {
        VStack(spacing: 10) {
            ProgressView()
            Text("Carregando...")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private var emptyView: some View {
        VStack(spacing: 10) {
            Text("Nenhum treino cadastrado")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))

            Text("Toque em “Importar Excel” para cadastrar treinos via planilha.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 10)
    }

    private func messageCard(text: String, isError: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundColor(isError ? .yellow.opacity(0.85) : .green.opacity(0.85))

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

    private func openDetails(for workout: TeacherImportedWorkout) {
        activeSheet = .detail(workout)
    }

    private func prepareTemplateShare() {
        errorMessage = nil

        let expectedFileName = "\(templateResourceName).\(templateResourceExtension)"

        guard let bundleURL = Bundle.main.resourceURL else {
            templateFileURL = nil
            errorMessage = "DEBUG: Bundle.main.resourceURL é nil."
            isTemplateSharePresented = true
            return
        }

        var foundURL: URL? = nil
        if let en = FileManager.default.enumerator(at: bundleURL, includingPropertiesForKeys: nil) {
            for case let u as URL in en {
                if u.lastPathComponent == expectedFileName {
                    foundURL = u
                    break
                }
            }
        }

        if let foundURL {
            do {
                let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(expectedFileName)
                if FileManager.default.fileExists(atPath: tmp.path) {
                    try FileManager.default.removeItem(at: tmp)
                }
                try FileManager.default.copyItem(at: foundURL, to: tmp)

                templateFileURL = tmp
                errorMessage = "OK: encontrei e copiei para /tmp"
                isTemplateSharePresented = true
                return
            } catch {
                templateFileURL = nil
                errorMessage = "DEBUG: encontrei o arquivo, mas falhei ao copiar para /tmp: \(error.localizedDescription)"
                isTemplateSharePresented = true
                return
            }
        }

        templateFileURL = nil
        errorMessage = "Arquivo da planilha não encontrado no bundle."
        isTemplateSharePresented = true
    }

    private func handlePickedExcel(url: URL) async {
        errorMessage = nil

        let ext = url.pathExtension.lowercased()
        guard ext == "xlsx" else {
            errorMessage = """
            O arquivo selecionado não é um .xlsx.

            Se você editou no Numbers, ele salva como .numbers.
            Faça: ••• → Exportar → Excel (.xlsx) e selecione o arquivo exportado.
            """
            return
        }

        isImporting = true
        defer { isImporting = false }

        let didStart = url.startAccessingSecurityScopedResource()
        defer {
            if didStart { url.stopAccessingSecurityScopedResource() }
        }

        do {
            let teacherId = (Auth.auth().currentUser?.uid ?? "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            guard !teacherId.isEmpty else {
                errorMessage = "Não foi possível identificar o professor logado."
                return
            }

            let parsed = try ExcelWorkoutImporter.parseWorkouts(fromXLSX: url)

            guard !parsed.isEmpty else {
                errorMessage = "Não foi encontrado nenhum treino válido na planilha."
                return
            }

            try await saveImportedWorkoutsBatch(teacherId: teacherId, items: parsed)
            await loadWorkouts()
        } catch {
            let msg = error.localizedDescription
            if msg.contains("CoreXLSX") || msg.contains("CoreXLSXError") {
                errorMessage = """
                Não foi possível ler o arquivo .xlsx.

                Dica: se você abriu no Numbers, use:
                ••• → Exportar → Excel (.xlsx)

                Detalhe técnico:
                \(msg)
                """
            } else {
                errorMessage = msg
            }
        }
    }

    private func saveImportedWorkoutsBatch(teacherId: String, items: [ImportedWorkoutPayload]) async throws {
        let db = Firestore.firestore()

        let col = db
            .collection("teachers")
            .document(teacherId)
            .collection("importedWorkouts")

        let chunks = items.chunked(into: 400)

        for chunk in chunks {
            let batch = db.batch()

            for item in chunk {
                let docRef = col.document()
                batch.setData([
                    "title": item.title,
                    "description": item.description,
                    "aquecimento": item.aquecimento,
                    "tecnica": item.tecnica,
                    "wod": item.wod,
                    "cargasMovimentos": item.cargasMovimentos,
                    "createdAt": Timestamp(date: Date()),
                    "source": "excel"
                ], forDocument: docRef)
            }

            try await batch.commit()
        }
    }

    private func sendImportedWorkoutToStudent(workout: TeacherImportedWorkout) {
        errorMessage = "Enviar para aluno: selecione o fluxo de alunos que você já usa (me diga a rota que abre a lista)."
    }

    private func loadWorkouts() async {
        errorMessage = nil

        let teacherId = (Auth.auth().currentUser?.uid ?? "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !teacherId.isEmpty else {
            workouts = []
            errorMessage = "Não foi possível identificar o professor logado."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let snap = try await Firestore.firestore()
                .collection("teachers")
                .document(teacherId)
                .collection("importedWorkouts")
                .order(by: "createdAt", descending: true)
                .getDocuments()

            let parsed: [TeacherImportedWorkout] = snap.documents.compactMap { doc in
                let data = doc.data()

                let title = (data["title"] as? String ?? "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                let description = (data["description"] as? String ?? "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                let aquecimento = (data["aquecimento"] as? String ?? "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                let tecnica = (data["tecnica"] as? String ?? "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                let wod = (data["wod"] as? String ?? "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                let cargasMovimentos = (data["cargasMovimentos"] as? String ?? "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

                return TeacherImportedWorkout(
                    id: doc.documentID,
                    title: title,
                    description: description,
                    aquecimento: aquecimento,
                    tecnica: tecnica,
                    wod: wod,
                    cargasMovimentos: cargasMovimentos
                )
            }

            workouts = parsed
        } catch {
            workouts = []
            errorMessage = error.localizedDescription
        }
    }

    private func addWorkout(title: String) async {
        errorMessage = nil

        let teacherId = (Auth.auth().currentUser?.uid ?? "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !teacherId.isEmpty else {
            errorMessage = "Não foi possível identificar o professor logado."
            return
        }

        let cleanedTitle = title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !cleanedTitle.isEmpty else {
            errorMessage = "Informe um título para o treino."
            return
        }

        let payload: [String: Any] = [
            "title": cleanedTitle,
            "createdAt": Timestamp(date: Date())
        ]

        isLoading = true
        defer { isLoading = false }

        do {
            try await Firestore.firestore()
                .collection("teachers")
                .document(teacherId)
                .collection("importedWorkouts")
                .addDocument(data: payload)

            await loadWorkouts()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteWorkout(workoutId: String) async {
        errorMessage = nil

        let teacherId = (Auth.auth().currentUser?.uid ?? "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !teacherId.isEmpty else {
            errorMessage = "Não foi possível identificar o professor logado."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await Firestore.firestore()
                .collection("teachers")
                .document(teacherId)
                .collection("importedWorkouts")
                .document(workoutId)
                .delete()

            await loadWorkouts()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

private struct TeacherImportedWorkout: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let aquecimento: String
    let tecnica: String
    let wod: String
    let cargasMovimentos: String
}

private struct ImportedWorkoutPayload: Equatable {
    let title: String
    let description: String
    let aquecimento: String
    let tecnica: String
    let wod: String
    let cargasMovimentos: String
}

private enum ExcelWorkoutImporter {

    enum ImportError: LocalizedError {
        case fileUnreadable
        case workbookInvalid
        case worksheetNotFound
        case headerNotFound
        case missingRequiredColumn(String)

        var errorDescription: String? {
            switch self {
            case .fileUnreadable:
                return "Não foi possível ler o arquivo Excel selecionado."
            case .workbookInvalid:
                return "Planilha inválida. Verifique se é um arquivo .xlsx."
            case .worksheetNotFound:
                return "Não foi possível localizar uma aba de dados na planilha."
            case .headerNotFound:
                return "Não foi possível identificar o cabeçalho na planilha. Verifique se a aba IMPORT_TREINOS existe e contém a linha de títulos."
            case .missingRequiredColumn(let name):
                return "Coluna obrigatória não encontrada: \(name)."
            }
        }
    }

    private static let preferredSheetName = "IMPORT_TREINOS"

    static func parseWorkouts(fromXLSX url: URL) throws -> [ImportedWorkoutPayload] {
        guard let file = XLSXFile(filepath: url.path) else {
            throw ImportError.fileUnreadable
        }

        let sharedStringsOptional = try file.parseSharedStrings()
        let workbooks = try file.parseWorkbooks()

        guard let wb = workbooks.first else {
            throw ImportError.workbookInvalid
        }

        let sheets = try file.parseWorksheetPathsAndNames(workbook: wb)
        guard !sheets.isEmpty else {
            throw ImportError.worksheetNotFound
        }

        if let preferred = sheets.first(where: { normalizeSheetName($0.name ?? "") == normalizeSheetName(preferredSheetName) }) {
            let worksheet = try file.parseWorksheet(at: preferred.path)
            if let parsed = parseWorksheetRows(worksheet, sharedStrings: sharedStringsOptional), !parsed.isEmpty {
                return parsed
            }
        }

        for s in sheets {
            let worksheet = try file.parseWorksheet(at: s.path)
            if let parsed = parseWorksheetRows(worksheet, sharedStrings: sharedStringsOptional), !parsed.isEmpty {
                return parsed
            }
        }

        throw ImportError.headerNotFound
    }

    private static func parseWorksheetRows(_ worksheet: Worksheet, sharedStrings: SharedStrings?) -> [ImportedWorkoutPayload]? {
        let rows = worksheet.data?.rows ?? []
        guard !rows.isEmpty else { return nil }

        guard let headerRow = rows.first(where: { row in
            let values = row.cells.map { cellText($0, sharedStrings: sharedStrings) }
            return values.contains(where: { normalizeHeader($0) == "titulo" })
        }) else {
            return nil
        }

        let headerIndexByName = buildHeaderIndexMap(cells: headerRow.cells, sharedStrings: sharedStrings)

        let colTitulo: Int
        do {
            colTitulo = try requireColumn("titulo", in: headerIndexByName, display: "Título")
        } catch {
            return nil
        }

        let colDescricao = headerIndexByName["descricao"]
        let colAquecimento = headerIndexByName["aquecimento"]
        let colTecnica = headerIndexByName["tecnica"]
        let colWod = headerIndexByName["wod"]
        let colCargas = headerIndexByName["cargasmovimentos"]

        let headerRowNumber = Int(headerRow.reference)

        var result: [ImportedWorkoutPayload] = []
        for row in rows {
            let rowNumber = Int(row.reference)
            guard rowNumber > headerRowNumber else { continue }

            func valueAtColumn(_ colIndex: Int?) -> String {
                guard let colIndex else { return "" }

                if let cell = row.cells.first(where: { cell in
                    let ref = cell.reference
                    let letters = ref.column.value
                    let idx = columnLettersToIndex(letters)
                    return idx == colIndex
                }) {
                    return cellText(cell, sharedStrings: sharedStrings)
                        .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                }

                return ""
            }

            let titulo = valueAtColumn(colTitulo)
            if titulo.isEmpty { continue }

            result.append(
                ImportedWorkoutPayload(
                    title: titulo,
                    description: valueAtColumn(colDescricao),
                    aquecimento: valueAtColumn(colAquecimento),
                    tecnica: valueAtColumn(colTecnica),
                    wod: valueAtColumn(colWod),
                    cargasMovimentos: valueAtColumn(colCargas)
                )
            )
        }

        return result
    }

    private static func buildHeaderIndexMap(cells: [Cell], sharedStrings: SharedStrings?) -> [String: Int] {
        var map: [String: Int] = [:]

        for cell in cells {
            let ref = cell.reference
            let letters = ref.column.value
            let colIndex = columnLettersToIndex(letters)

            let raw = cellText(cell, sharedStrings: sharedStrings)
            let key = normalizeHeader(raw)

            if !key.isEmpty {
                map[key] = colIndex
            }
        }

        return map
    }

    private static func requireColumn(_ normalized: String, in map: [String: Int], display: String) throws -> Int {
        guard let idx = map[normalized] else {
            throw ImportError.missingRequiredColumn(display)
        }
        return idx
    }

    private static func extractSharedStringText(from anyItem: Any) -> String {
        let mirror = Mirror(reflecting: anyItem)

        for child in mirror.children {
            if child.label == "text", let s = child.value as? String {
                return s
            }
        }

        for child in mirror.children {
            if child.label == "richText" {
                let richMirror = Mirror(reflecting: child.value)
                if richMirror.displayStyle == .optional {
                    if let first = richMirror.children.first {
                        return extractRichTextJoined(from: first.value)
                    }
                } else {
                    return extractRichTextJoined(from: child.value)
                }
            }
        }

        return ""
    }

    private static func extractRichTextJoined(from anyRich: Any) -> String {
        let richMirror = Mirror(reflecting: anyRich)
        if richMirror.displayStyle == .collection {
            var parts: [String] = []
            parts.reserveCapacity(richMirror.children.count)

            for item in richMirror.children {
                let itemMirror = Mirror(reflecting: item.value)
                for c in itemMirror.children {
                    if c.label == "text", let s = c.value as? String {
                        parts.append(s)
                        break
                    }
                }
            }
            return parts.joined()
        }
        return ""
    }

    private static func cellText(_ cell: Cell, sharedStrings: SharedStrings?) -> String {

        if let sst = sharedStrings, let v = cell.stringValue(sst) {
            return v
        }

        if let sst = sharedStrings,
           let raw = cell.value,
           let idx = Int(raw),
           idx >= 0,
           idx < sst.items.count {

            let anyItem = sst.items[idx]
            let resolved = extractSharedStringText(from: anyItem)
            if !resolved.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
                return resolved
            }
        }

        if let inline = cell.inlineString?.text {
            return inline
        }

        if let v = cell.value {
            return v
        }

        return ""
    }

    private static func normalizeHeader(_ s: String) -> String {
        let trimmed = s.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).lowercased()

        let folded = trimmed.folding(
            options: [.diacriticInsensitive, .widthInsensitive, .caseInsensitive],
            locale: .current
        )

        let cleaned = folded
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "/", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "—", with: " ")
            .replacingOccurrences(of: "(", with: " ")
            .replacingOccurrences(of: ")", with: " ")
            .replacingOccurrences(of: ":", with: " ")
            .replacingOccurrences(of: "  ", with: " ")

        let compact = cleaned.replacingOccurrences(of: " ", with: "")

        if compact == "titulo" { return "titulo" }
        if compact == "descricao" { return "descricao" }
        if compact == "aquecimento" { return "aquecimento" }
        if compact == "tecnica" { return "tecnica" }
        if compact == "wod" { return "wod" }

        if compact.contains("titulo") { return "titulo" }
        if compact.contains("descricao") { return "descricao" }
        if compact.contains("aquecimento") { return "aquecimento" }
        if compact.contains("tecnica") { return "tecnica" }
        if compact.contains("wod") { return "wod" }

        let hasCarga = compact.contains("carga") || compact.contains("cargas")
        let hasMov = compact.contains("movimento") || compact.contains("movimentos")
        if hasCarga && hasMov { return "cargasmovimentos" }

        return compact
    }

    private static func normalizeSheetName(_ s: String) -> String {
        s.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .widthInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
    }

    private static func columnLettersToIndex(_ letters: String) -> Int {
        let scalars = letters.uppercased().unicodeScalars
        var result = 0
        for scalar in scalars {
            let value = Int(scalar.value) - Int(UnicodeScalar("A").value) + 1
            result = result * 26 + value
        }
        return max(0, result - 1)
    }
}

private struct TeacherImportedWorkoutDetailsSheet: View {

    let workout: TeacherImportedWorkout
    let onSendToStudent: () -> Void

    @Environment(\.dismiss) private var dismiss

    private let contentMaxWidth: CGFloat = 380

    @State private var isEditing: Bool = false

    @State private var draftDescription: String = ""
    @State private var draftAquecimento: String = ""
    @State private var draftTecnica: String = ""
    @State private var draftWod: String = ""
    @State private var draftCargasMovimentos: String = ""

    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil

    var body: some View {
        NavigationStack {
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

                                header

                                if isEditing {
                                    editableBlocksCard
                                } else {
                                    readOnlyBlocks
                                }

                                if let err = errorMessage {
                                    messageCard(text: err, isError: true)
                                }

                                if let ok = successMessage {
                                    messageCard(text: ok, isError: false)
                                }

                                Color.clear.frame(height: 18)
                            }
                            .frame(maxWidth: contentMaxWidth)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)

                            Spacer(minLength: 0)
                        }
                    }
                }
                .ignoresSafeArea(.container, edges: [.bottom])
            }
            .navigationTitle("Treino")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .topBarLeading) {
                    Button("Fechar") { dismiss() }
                        .disabled(isSaving)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if isEditing {
                        HStack(spacing: 12) {

                            Button("Cancelar") {
                                errorMessage = nil
                                successMessage = nil
                                isEditing = false
                                resetDraftFromWorkout()
                            }
                            .disabled(isSaving)

                            Button {
                                Task { await saveEdits() }
                            } label: {
                                if isSaving {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Salvar")
                                }
                            }
                            .disabled(isSaving)
                        }
                    } else {
                        Button("Editar") {
                            errorMessage = nil
                            successMessage = nil
                            isEditing = true
                            resetDraftFromWorkout()
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    EmptyView()
                }

            }
            .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .background(NavigationBarNoHairline())
            .onAppear {
                resetDraftFromWorkout()
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.20), lineWidth: 1.25)
                    .allowsHitTesting(false)
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text(workout.title.isEmpty ? "Treino" : workout.title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))
                .lineLimit(2)

            let desc = workout.description.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if !desc.isEmpty {
                Text(desc)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.70))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var readOnlyBlocks: some View {
        VStack(spacing: 12) {
            blockCard(title: "Descrição", value: workout.description)
            blockCard(title: "Aquecimento", value: workout.aquecimento)
            blockCard(title: "Técnica", value: workout.tecnica)
            blockCard(title: "WOD", value: workout.wod)
            blockCard(title: "Cargas / Movimentos", value: workout.cargasMovimentos)
        }
    }

    private var editableBlocksCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            blockEditor(title: "Descrição", text: $draftDescription)

            Divider().background(Theme.Colors.divider)

            blockEditor(title: "Aquecimento", text: $draftAquecimento)

            Divider().background(Theme.Colors.divider)

            blockEditor(title: "Técnica", text: $draftTecnica)

            Divider().background(Theme.Colors.divider)

            blockEditor(title: "WOD", text: $draftWod)

            Divider().background(Theme.Colors.divider)

            blockEditor(title: "Cargas / Movimentos", text: $draftCargasMovimentos)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func blockEditor(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))

            TextEditor(text: text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.92))
                .frame(minHeight: 110)
                .scrollContentBackground(.hidden)
                .background(Color.white.opacity(0.06))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func blockCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))

            Text(value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty ? "-" : value)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.70))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func messageCard(text: String, isError: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundColor(isError ? .yellow.opacity(0.85) : .green.opacity(0.85))

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

    private func resetDraftFromWorkout() {
        draftDescription = workout.description
        draftAquecimento = workout.aquecimento
        draftTecnica = workout.tecnica
        draftWod = workout.wod
        draftCargasMovimentos = workout.cargasMovimentos
    }

    private func saveEdits() async {
        errorMessage = nil
        successMessage = nil

        let teacherId = (Auth.auth().currentUser?.uid ?? "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !teacherId.isEmpty else {
            errorMessage = "Não foi possível identificar o professor logado."
            return
        }

        let workoutId = workout.id.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !workoutId.isEmpty else {
            errorMessage = "Não foi possível salvar: id do treino inválido."
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            try await Firestore.firestore()
                .collection("teachers")
                .document(teacherId)
                .collection("importedWorkouts")
                .document(workoutId)
                .updateData([
                    "description": draftDescription,
                    "aquecimento": draftAquecimento,
                    "tecnica": draftTecnica,
                    "wod": draftWod,
                    "cargasMovimentos": draftCargasMovimentos
                ])

            successMessage = "Alterações salvas com sucesso!"
            isEditing = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct TeacherAddWorkoutSheet: View {

    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""

    @State private var sheetMessage: String? = nil
    @State private var sheetMessageIsError: Bool = false

    let onSave: (_ title: String) -> Void

    private let contentMaxWidth: CGFloat = 380

    var body: some View {
        NavigationStack {
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

                                Text("Digite um título para o treino.")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.65))

                                formCard

                                HStack(spacing: 10) {

                                    Button {
                                        let t = title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                                        if t.isEmpty {
                                            sheetMessage = "Informe um título para o treino."
                                            sheetMessageIsError = true
                                            return
                                        }

                                        onSave(t)
                                        dismiss()
                                    } label: {
                                        HStack {
                                            Image(systemName: "checkmark")
                                            Text("Salvar")
                                        }
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.92))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(Capsule().fill(Color.green.opacity(0.16)))
                                    }
                                    .buttonStyle(.plain)

                                    Spacer(minLength: 0)
                                }

                                if let msg = sheetMessage {
                                    sheetMessageCard(text: msg, isError: sheetMessageIsError)
                                }

                                Color.clear.frame(height: 18)
                            }
                            .frame(maxWidth: contentMaxWidth)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)

                            Spacer(minLength: 0)
                        }
                    }
                }
                .ignoresSafeArea(.container, edges: [.bottom])
            }
            .navigationTitle("Adicionar Treino")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fechar") { dismiss() }
                }
            }
            .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            VStack(alignment: .leading, spacing: 6) {
                Text("Título do treino")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.55))

                ZStack(alignment: .leading) {
                    if title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
                        Text("Ex: Treino A - Peito e tríceps")
                            .foregroundColor(.white.opacity(0.45))
                            .padding(.horizontal, 12)
                    }

                    TextField("", text: $title)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(false)
                        .foregroundColor(.white.opacity(0.92))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                }
                .background(Color.white.opacity(0.10))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func sheetMessageCard(text: String, isError: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundColor(isError ? .yellow.opacity(0.85) : .green.opacity(0.85))

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
}

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}

private struct DocumentPicker: UIViewControllerRepresentable {
    let allowedContentTypes: [UTType]
    let onPick: (URL) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedContentTypes, asCopy: true)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, onCancel: onCancel)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        let onCancel: () -> Void

        init(onPick: @escaping (URL) -> Void, onCancel: @escaping () -> Void) {
            self.onPick = onPick
            self.onCancel = onCancel
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onCancel()
        }
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        var result: [[Element]] = []
        result.reserveCapacity((count / size) + 1)

        var idx = 0
        while idx < count {
            let end = Swift.min(idx + size, count)
            result.append(Array(self[idx..<end]))
            idx = end
        }
        return result
    }
}

private struct NavigationBarNoHairline: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> UIViewController {
        NavBarNoHairlineController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }

    private final class NavBarNoHairlineController: UIViewController {

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            apply()
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            apply()
        }

        private func apply() {
            guard let nav = navigationController else { return }
            let bar = nav.navigationBar

            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Theme.Colors.headerBackground)
            appearance.shadowColor = .clear
            appearance.shadowImage = UIImage()
            appearance.backgroundEffect = nil

            bar.standardAppearance = appearance
            bar.scrollEdgeAppearance = appearance
            bar.compactAppearance = appearance

            bar.layer.shadowOpacity = 0
            bar.layer.shadowRadius = 0
            bar.layer.shadowOffset = .zero
            bar.layer.shadowColor = UIColor.clear.cgColor
        }
    }
}

