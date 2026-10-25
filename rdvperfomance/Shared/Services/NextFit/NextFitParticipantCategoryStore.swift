import Foundation

/// Persistência local das categorias visuais dos participantes NextFit.
///
/// Objetivo: impedir que a categoria (ícone/cor) já estabelecida mude quando a NextFit atualiza
/// `Status`, `Tipo` ou `CodigoContratoCliente` do mesmo participante após o início/encerramento da aula.
///
/// Regras:
/// - Não altera a lista de participantes: só é consultada para participantes presentes na resposta
///   atual da API. Participantes cancelados (ausentes da resposta) nunca são reconstruídos.
/// - Inferências (`inferredExternalFromReservation`) ficam vinculadas somente à participação
///   (`CodigoAgenda` + `Participantes[].Id`, conferindo `CodigoCliente`); nunca são promovidas a
///   classificação comercial confirmada nem copiadas para outros contratos.
/// - Classificações confirmadas ficam vinculadas a `CodigoCliente` + `CodigoContratoCliente`. Com contrato
///   informado, exige correspondência exata (um contrato novo não herda a categoria do antigo).
///   Não há lista de contratos de terceiros embutida no app: confirmações só entram por importação
///   explícita em DEBUG (ver `importConfirmedIfPresent`).
/// - Isolada por conta do app + cliente NextFit da sessão + unidade; arquivo privado, sem backup,
///   com retenção limitada. Nenhum dado é enviado a servidores.
/// - Fotografia visual (`VisualRecord`): categoria apresentada antes do encerramento, por participação
///   (`CodigoAgenda` + `Participantes[].Id`, conferindo `CodigoCliente`). Gravada somente para aulas não
///   encerradas e reutilizada após o encerramento; nunca recria participantes ausentes da resposta.
final class NextFitParticipantCategoryStore {
    struct ConfirmedRecord: Codable, Equatable {
        let clientId: Int
        let contractClientId: Int
        let category: NextFitParticipantCategory
        let confirmedAt: Date
    }

    struct InferredRecord: Codable, Equatable {
        let agendaId: Int
        let participantId: Int
        let clientId: Int?
        let category: NextFitParticipantCategory
        let origin: String
        let observedAt: Date
    }

    /// Fotografia da categoria visual efetivamente apresentada para uma participação antes do
    /// encerramento da aula. Vinculada a `CodigoAgenda` + `Participantes[].Id` (conferindo `CodigoCliente`).
    /// `origin` preserva a fonte (confirmada, contrato próprio, inferência ou fallback visual);
    /// um fallback visual nunca é tratado como confirmação comercial.
    struct VisualRecord: Codable, Equatable {
        let agendaId: Int
        let participantId: Int
        let clientId: Int?
        let category: NextFitParticipantCategory
        let origin: String
        let observedAt: Date
    }

    /// Resultado da observação visual (somente diagnóstico DEBUG).
    enum VisualObservationOutcome: String {
        case recorded = "gravado"
        case updated = "atualizado"
        case kept = "mantido"
        case ignored = "ignorado"
    }

    private struct StoreFile: Codable {
        var version: Int = 1
        var unitCode: Int
        var sessionClientId: Int
        var confirmed: [ConfirmedRecord] = []
        var inferred: [InferredRecord] = []
        /// Opcional para manter a leitura dos arquivos já gravados (sem a chave `visual`).
        var visual: [VisualRecord]? = nil
    }

    /// Unidade NextFit Muralha (mesma de `NextFitService`).
    static let unitCode = 30299
    private static let inferredRetentionDays = 180
    private static let maxInferredRecords = 5_000
    /// Mesma retenção das inferências; limite maior pois há um registro por participante observado.
    private static let maxVisualRecords = 20_000

    let sessionClientId: Int
    private var file: StoreFile
    private let fileURL: URL
    private var inferredIndex: [String: InferredRecord] = [:]
    private var visualIndex: [String: VisualRecord] = [:]

    init(account: String, sessionClientId: Int) {
        self.sessionClientId = sessionClientId
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = base.appendingPathComponent("NextFitParticipantCategories", isDirectory: true)
        let safeAccount = account.filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
        fileURL = directory.appendingPathComponent(
            "\(safeAccount)_\(sessionClientId)_\(Self.unitCode).json"
        )
        file = StoreFile(unitCode: Self.unitCode, sessionClientId: sessionClientId)

        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var resourceURL = directory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? resourceURL.setResourceValues(values)

        load()
        #if DEBUG
        importConfirmedIfPresent(directory: directory)
        #endif
        pruneInferred()
        pruneVisual()
        rebuildIndex()
    }

    // MARK: Consulta (sem efeitos colaterais; segura para uso durante a renderização)

    /// Categoria confirmada do participante. Com contrato informado, exige `CodigoCliente` (quando
    /// presente) + `CodigoContratoCliente` exatos. Sem contrato, usa as confirmações do cliente somente
    /// se todas indicarem a mesma categoria.
    func confirmedCategory(clientId: Int?, contractClientId: Int?) -> NextFitParticipantCategory? {
        if let contractClientId {
            let match = file.confirmed.first { record in
                record.contractClientId == contractClientId
                    && (clientId == nil || record.clientId == clientId)
            }
            return match?.category
        }
        guard let clientId else { return nil }
        let categories = Set(file.confirmed.filter { $0.clientId == clientId }.map(\.category))
        return categories.count == 1 ? categories.first : nil
    }

    /// Inferência persistida para a MESMA participação, conferindo o `CodigoCliente` quando disponível.
    func hasInferredExternal(agendaId: Int, participantId: Int, clientId: Int?) -> Bool {
        guard let record = inferredIndex[Self.key(agendaId: agendaId, participantId: participantId)],
              record.category == .external else {
            return false
        }
        if let clientId, let recordClientId = record.clientId, clientId != recordClientId {
            return false
        }
        return true
    }

    /// Categoria visual persistida para a MESMA participação. Descarta o registro quando o
    /// `CodigoCliente` atual e o registrado diferem (evita reaproveitamento indevido).
    func visualRecord(agendaId: Int, participantId: Int, clientId: Int?) -> VisualRecord? {
        guard let record = visualIndex[Self.key(agendaId: agendaId, participantId: participantId)],
              record.category != .unknown else {
            return nil
        }
        if let clientId, let recordClientId = record.clientId, clientId != recordClientId {
            return nil
        }
        return record
    }

    /// Registra a categoria visual efetivamente apresentada para as participações de uma aula ainda não
    /// encerrada. Não grava categorias desconhecidas; evidência mais fraca (ex.: fallback visual) nunca
    /// substitui uma categoria registrada a partir de evidência mais forte. Grava o arquivo uma única vez
    /// e somente se houver alteração efetiva.
    @discardableResult
    func observeVisual(
        agendaId: Int,
        entries: [(participant: NextFitAgendaParticipantDisplay, resolution: NextFitParticipantCategoryResolution)]
    ) -> [(participantId: Int, outcome: VisualObservationOutcome)] {
        var outcomes: [(participantId: Int, outcome: VisualObservationOutcome)] = []
        var changed = false
        let now = Date()
        var visual = file.visual ?? []

        for (participant, resolution) in entries {
            let newRank = NextFitParticipantCategoryResolver.evidenceRank(reason: resolution.reason)
            guard resolution.category != .unknown, newRank > 0 else {
                outcomes.append((participant.id, .ignored))
                continue
            }

            let key = Self.key(agendaId: agendaId, participantId: participant.id)
            let existing = visualIndex[key]
            if let existing {
                let sameClient = existing.clientId == nil || participant.clientId == nil
                    || existing.clientId == participant.clientId
                if sameClient {
                    let existingRank = NextFitParticipantCategoryResolver.evidenceRank(reason: existing.origin)
                    // Mesma categoria: só atualiza a origem quando a evidência for mais forte.
                    // Categoria diferente: nunca aceita evidência mais fraca.
                    if (existing.category == resolution.category && newRank <= existingRank)
                        || (existing.category != resolution.category && newRank < existingRank) {
                        outcomes.append((participant.id, .kept))
                        continue
                    }
                }
            }

            let record = VisualRecord(
                agendaId: agendaId,
                participantId: participant.id,
                clientId: participant.clientId ?? existing?.clientId,
                category: resolution.category,
                origin: resolution.reason,
                observedAt: now
            )
            visual.removeAll { $0.agendaId == agendaId && $0.participantId == participant.id }
            visual.append(record)
            visualIndex[key] = record
            changed = true
            outcomes.append((participant.id, existing == nil ? .recorded : .updated))
        }

        if changed {
            file.visual = visual
            pruneVisual()
            rebuildIndex()
            persist()
        }
        return outcomes
    }

    // MARK: Observação (chamada somente após cargas reais de `Agenda/{id}`)

    /// Registra as participações que apresentam o padrão de agregador nesta consulta.
    /// Não remove registros de participantes ausentes (cancelamentos não alteram categorias).
    func observe(detail: NextFitAgendaDetailDisplay) {
        var changed = false
        let now = Date()
        for participant in detail.participants
        where NextFitParticipantCategoryResolver.matchesReservationAggregatorPattern(participant) {
            let key = Self.key(agendaId: detail.id, participantId: participant.id)
            if let existing = inferredIndex[key],
               existing.clientId == participant.clientId || participant.clientId == nil {
                continue
            }
            let record = InferredRecord(
                agendaId: detail.id,
                participantId: participant.id,
                clientId: participant.clientId,
                category: .external,
                origin: NextFitParticipantCategoryResolver.inferredExternalReason,
                observedAt: now
            )
            file.inferred.removeAll { $0.agendaId == detail.id && $0.participantId == participant.id }
            file.inferred.append(record)
            inferredIndex[key] = record
            changed = true
        }
        if changed {
            pruneInferred()
            rebuildIndex()
            persist()
        }
    }

    // MARK: Privados

    private static func key(agendaId: Int, participantId: Int) -> String {
        "\(agendaId)#\(participantId)"
    }

    private func rebuildIndex() {
        var index: [String: InferredRecord] = [:]
        for record in file.inferred {
            index[Self.key(agendaId: record.agendaId, participantId: record.participantId)] = record
        }
        inferredIndex = index
        var visualIndex: [String: VisualRecord] = [:]
        for record in file.visual ?? [] {
            visualIndex[Self.key(agendaId: record.agendaId, participantId: record.participantId)] = record
        }
        self.visualIndex = visualIndex
    }

    private func pruneVisual() {
        guard let visual = file.visual else { return }
        let retention = TimeInterval(Self.inferredRetentionDays) * 86_400
        let cutoff = Date().addingTimeInterval(-retention)
        var kept = visual.filter { $0.observedAt >= cutoff }
        if kept.count > Self.maxVisualRecords {
            kept.sort { $0.observedAt < $1.observedAt }
            kept = Array(kept.suffix(Self.maxVisualRecords))
        }
        file.visual = kept
    }

    private func pruneInferred() {
        let retention = TimeInterval(Self.inferredRetentionDays) * 86_400
        let cutoff = Date().addingTimeInterval(-retention)
        var kept = file.inferred.filter { $0.observedAt >= cutoff }
        if kept.count > Self.maxInferredRecords {
            kept.sort { $0.observedAt < $1.observedAt }
            kept = Array(kept.suffix(Self.maxInferredRecords))
        }
        file.inferred = kept
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else {
            #if DEBUG
            print("[NextFitParticipantCategoryStore] CARGA\nresultado=arquivo-ausente (sem historico)")
            #endif
            return
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let decoded = try? decoder.decode(StoreFile.self, from: data),
              decoded.unitCode == Self.unitCode,
              decoded.sessionClientId == sessionClientId else {
            #if DEBUG
            print("[NextFitParticipantCategoryStore] CARGA\nresultado=falha-leitura-ou-sessao-diferente bytes=\(data.count)")
            #endif
            return
        }
        file = decoded
        #if DEBUG
        print("[NextFitParticipantCategoryStore] CARGA\nresultado=sucesso confirmadas=\(decoded.confirmed.count) inferidas=\(decoded.inferred.count) visuais=\(decoded.visual?.count ?? 0)")
        #endif
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(file) else { return }
        #if DEBUG
        do {
            try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            print("[NextFitParticipantCategoryStore] GRAVACAO\nresultado=sucesso visuais=\(file.visual?.count ?? 0) inferidas=\(file.inferred.count)")
        } catch {
            let nsError = error as NSError
            print("[NextFitParticipantCategoryStore] GRAVACAO\nresultado=falha erro=\(nsError.domain)(\(nsError.code))")
        }
        #else
        try? data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        #endif
    }

    #if DEBUG
    /// Importação explícita (somente DEBUG) de classificações comerciais confirmadas com a academia/alunos.
    /// Arquivo `confirmed-import.json` copiado para `Library/Application Support/NextFitParticipantCategories/`
    /// do contêiner do app (ex.: `xcrun devicectl device copy to ...`), no formato:
    /// `[{"codigoCliente": 1, "codigoContratoCliente": 2, "categoria": "monthly|package|external|vip"}]`.
    /// Após a importação o arquivo é removido. Nenhuma lista de terceiros é embutida no aplicativo.
    private func importConfirmedIfPresent(directory: URL) {
        struct ImportEntry: Decodable {
            let codigoCliente: Int
            let codigoContratoCliente: Int
            let categoria: NextFitParticipantCategory
        }
        let importURL = directory.appendingPathComponent("confirmed-import.json")
        guard let data = try? Data(contentsOf: importURL) else { return }
        do {
            let entries = try JSONDecoder().decode([ImportEntry].self, from: data)
            let now = Date()
            var imported = 0
            for entry in entries where entry.categoria != .unknown {
                file.confirmed.removeAll {
                    $0.clientId == entry.codigoCliente && $0.contractClientId == entry.codigoContratoCliente
                }
                file.confirmed.append(ConfirmedRecord(
                    clientId: entry.codigoCliente,
                    contractClientId: entry.codigoContratoCliente,
                    category: entry.categoria,
                    confirmedAt: now
                ))
                imported += 1
            }
            persist()
            try? FileManager.default.removeItem(at: importURL)
            print("[NextFitParticipantCategoryStore] IMPORTACAO\nresultado=sucesso\nconfirmadasImportadas=\(imported)\ntotalConfirmadas=\(file.confirmed.count)")
        } catch {
            let nsError = error as NSError
            print("[NextFitParticipantCategoryStore] IMPORTACAO\nresultado=falha\nerro=\(nsError.domain)(\(nsError.code)) \(nsError.localizedDescription)")
        }
    }
    #endif
}

