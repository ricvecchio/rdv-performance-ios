import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import SafariServices
import UIKit
import AVKit
import WebKit
import UniformTypeIdentifiers

// ✅ CoreXLSX (SPM)
// https://github.com/CoreOffice/CoreXLSX
import CoreXLSX

struct TeacherImportWorkoutsView: View {

    @Binding var path: [AppRoute]
    let category: TreinoTipo

    private let contentMaxWidth: CGFloat = 380

    @State private var workouts: [TeacherImportedWorkout] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    @State private var isAddSheetPresented: Bool = false

    // ✅ Baixar planilha modelo (bundle)
    @State private var isTemplateSharePresented: Bool = false
    @State private var templateFileURL: URL? = nil

    // ✅ Importar planilha preenchida
    @State private var isImportPickerPresented: Bool = false
    @State private var isImporting: Bool = false

    // ✅ Nome do arquivo no bundle (sem extensão)
    private let templateResourceName: String = "rdv_import_treinos_template_pt_crossfit"
    private let templateResourceExtension: String = "xlsx"

    // ✅ Aceitar SOMENTE .xlsx no picker (evita .numbers do Numbers)
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

        // ✅ Share Sheet para baixar planilha modelo (do bundle)
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

        // ✅ Document Picker para importar SOMENTE .xlsx
        .sheet(isPresented: $isImportPickerPresented) {
            DocumentPicker(
                allowedContentTypes: [xlsxUTType],
                onPick: { pickedURL in
                    Task { await handlePickedExcel(url: pickedURL) }
                },
                onCancel: {
                    // nada
                }
            )
            .ignoresSafeArea()
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

                workoutRow(workout: w)
                    .contentShape(Rectangle())

                if idx < workouts.count - 1 {
                    innerDivider(leading: 14)
                }
            }
        }
    }

    private func workoutRow(workout w: TeacherImportedWorkout) -> some View {
        HStack(spacing: 12) {

            ZStack {
                Color.white.opacity(0.06)
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(.green.opacity(0.85))
            }
            .frame(width: 66, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(w.title.isEmpty ? "Treino" : w.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(1)

                Text("Treino")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(1)
            }

            Spacer()

            Menu {
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

    // MARK: - Baixar Planilha (Bundle -> Share)
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

    // MARK: - Importar Planilha (.xlsx -> Firestore)
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
            let teacherId = (Auth.auth().currentUser?.uid ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
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

    // MARK: - Firestore (lista / remover / manual)
    private func loadWorkouts() async {
        errorMessage = nil

        let teacherId = (Auth.auth().currentUser?.uid ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
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
                let title = (data["title"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

                return TeacherImportedWorkout(
                    id: doc.documentID,
                    title: title
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

        let teacherId = (Auth.auth().currentUser?.uid ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !teacherId.isEmpty else {
            errorMessage = "Não foi possível identificar o professor logado."
            return
        }

        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
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

        let teacherId = (Auth.auth().currentUser?.uid ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
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
}

// MARK: - Payload importado
private struct ImportedWorkoutPayload: Equatable {
    let title: String
    let description: String
    let aquecimento: String
    let tecnica: String
    let wod: String
    let cargasMovimentos: String
}

// MARK: - Importador Excel (CoreXLSX)
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

    // ✅ Nome esperado da aba de import (ajusta aqui se mudar no futuro)
    private static let preferredSheetName = "IMPORT_TREINOS"

    static func parseWorkouts(fromXLSX url: URL) throws -> [ImportedWorkoutPayload] {
        guard let file = XLSXFile(filepath: url.path) else {
            throw ImportError.fileUnreadable
        }

        let sharedStringsOptional = try file.parseSharedStrings() // SharedStrings?
        let workbooks = try file.parseWorkbooks()

        guard let wb = workbooks.first else {
            throw ImportError.workbookInvalid
        }

        // ✅ Lista todas as abas: (nome, path)
        let sheets = try file.parseWorksheetPathsAndNames(workbook: wb)
        guard !sheets.isEmpty else {
            throw ImportError.worksheetNotFound
        }

        // ✅ 1) tenta achar pela aba "IMPORT_TREINOS"
        if let preferred = sheets.first(where: { normalizeSheetName($0.name ?? "") == normalizeSheetName(preferredSheetName) }) {
            let worksheet = try file.parseWorksheet(at: preferred.path)
            if let parsed = parseWorksheetRows(worksheet, sharedStrings: sharedStringsOptional), !parsed.isEmpty {
                return parsed
            }
            // se achou a aba, mas não achou header, segue para fallback
        }

        // ✅ 2) fallback: procura a primeira aba que contenha o header "titulo"
        for s in sheets {
            let worksheet = try file.parseWorksheet(at: s.path)
            if let parsed = parseWorksheetRows(worksheet, sharedStrings: sharedStringsOptional), !parsed.isEmpty {
                return parsed
            }
        }

        // ✅ nenhuma aba serviu
        throw ImportError.headerNotFound
    }

    private static func parseWorksheetRows(_ worksheet: Worksheet, sharedStrings: SharedStrings?) -> [ImportedWorkoutPayload]? {
        let rows = worksheet.data?.rows ?? []
        guard !rows.isEmpty else { return nil }

        // 1) encontra header
        guard let headerRow = rows.first(where: { row in
            let values = row.cells.map { cellText($0, sharedStrings: sharedStrings) }
            return values.contains(where: { normalizeHeader($0) == "titulo" })
        }) else {
            return nil
        }

        // 2) mapeia header -> índice da coluna
        let headerIndexByName = buildHeaderIndexMap(cells: headerRow.cells, sharedStrings: sharedStrings)

        // 3) coluna obrigatória
        let colTitulo: Int
        do {
            colTitulo = try requireColumn("titulo", in: headerIndexByName, display: "Título")
        } catch {
            return nil
        }

        // opcionais
        let colDescricao = headerIndexByName["descricao"]
        let colAquecimento = headerIndexByName["aquecimento"]
        let colTecnica = headerIndexByName["tecnica"]
        let colWod = headerIndexByName["wod"]
        let colCargas = headerIndexByName["cargasmovimentos"]

        let headerRowNumber = Int(headerRow.reference)

        // 4) percorre linhas após header
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
                        .trimmingCharacters(in: .whitespacesAndNewlines)
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

    private static func cellText(_ cell: Cell, sharedStrings: SharedStrings?) -> String {
        if let sst = sharedStrings {
            return cell.stringValue(sst) ?? ""
        }
        return cell.value ?? ""
    }

    private static func normalizeHeader(_ s: String) -> String {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let folded = trimmed.folding(
            options: [.diacriticInsensitive, .widthInsensitive, .caseInsensitive],
            locale: .current
        )

        let cleaned = folded
            .replacingOccurrences(of: "/", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "—", with: " ")
            .replacingOccurrences(of: "  ", with: " ")

        let compact = cleaned.replacingOccurrences(of: " ", with: "")

        if compact == "titulo" { return "titulo" }
        if compact == "descricao" { return "descricao" }
        if compact == "aquecimento" { return "aquecimento" }
        if compact == "tecnica" { return "tecnica" }
        if compact == "wod" { return "wod" }

        if compact.contains("cargas") && compact.contains("movimentos") { return "cargasmovimentos" }

        return compact
    }

    private static func normalizeSheetName(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
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

// MARK: - Sheet adicionar treino (mantido)
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
                                        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
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
                    if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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

// MARK: - UIKit wrappers
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

// MARK: - Helpers
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

