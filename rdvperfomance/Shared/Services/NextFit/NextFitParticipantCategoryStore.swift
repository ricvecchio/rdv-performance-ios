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

    private struct StoreFile: Codable {
        var version: Int = 1
        var unitCode: Int
        var sessionClientId: Int
        var confirmed: [ConfirmedRecord] = []
        var inferred: [InferredRecord] = []
    }

    /// Unidade NextFit Muralha (mesma de `NextFitService`).
    static let unitCode = 30299
    private static let inferredRetentionDays = 180
    private static let maxInferredRecords = 5_000

    let sessionClientId: Int
    private var file: StoreFile
    private let fileURL: URL
    private var inferredIndex: [String: InferredRecord] = [:]

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
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let decoded = try? decoder.decode(StoreFile.self, from: data),
              decoded.unitCode == Self.unitCode,
              decoded.sessionClientId == sessionClientId else {
            return
        }
        file = decoded
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(file) else { return }
        try? data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
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

