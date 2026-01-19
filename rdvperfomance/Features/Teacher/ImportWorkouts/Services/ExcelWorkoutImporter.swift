import Foundation
import CoreXLSX

enum ExcelWorkoutImporter {

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
