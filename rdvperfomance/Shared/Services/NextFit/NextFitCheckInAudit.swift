#if DEBUG
import Foundation

// MARK: - Diagnóstico NextFit ANTES x APÓS o encerramento da aula (somente DEBUG)
//
// Finalidade exclusiva: reunir evidências reais dos campos retornados pela NextFit para cada
// participante de uma aula, em capturas diferentes da mesma aula, para conferência com a academia.
//
// Garantias:
// - Compilado somente em DEBUG (todo o arquivo está dentro de `#if DEBUG`).
// - Recebe apenas respostas JÁ obtidas pelos fluxos existentes (`Agenda/{id}` e
//   `Cliente/RecuperarDadosPrincipais`). Não faz requisições, polling nem tarefas em segundo plano.
// - Não altera modelos de produção, sessão NextFit, classificação comercial, ícones ou WOD.
// - Persistência local, privada (Application Support), excluída de backup, com retenção limitada.
// - Nunca grava tokens, cabeçalhos, URLs de imagem, e-mails, telefones ou documentos.
// - Nomes de participantes nunca são exibidos em logs; só entram na exportação por ação explícita.
//
// Ações do desenvolvedor (sem alteração de interface):
// - Argumentos de execução (Xcode › Edit Scheme › Run › Arguments Passed On Launch):
//     -NextFitCheckInAuditExport YES        gera/atualiza os CSVs a cada nova captura
//     -NextFitCheckInAuditIncludeNames YES  inclui nomes nos CSVs (arquivo passa a conter dados pessoais)
//     -NextFitCheckInAuditReset YES         limpa todas as capturas ao iniciar o diagnóstico
// - Console LLDB (app pausado):
//     po NextFitCheckInAuditStore.shared.exportCSV()
//     po NextFitCheckInAuditStore.shared.exportCSV(includeNames: true)
//     po NextFitCheckInAuditStore.shared.printComparisons()
//     po NextFitCheckInAuditStore.shared.reset()

// MARK: - Valores registrados

/// Valor original de um campo, preservado como texto, com o tipo JSON observado.
/// `kind`: numero | texto | booleano | nulo | lista | objeto | omitido | desconhecido.
struct NextFitAuditValue: Codable, Equatable {
    let kind: String
    let text: String
}

enum NextFitAuditSanitizer {
    /// Fragmentos de chave cujo VALOR nunca é registrado (somente presença).
    private static let sensitiveKeyFragments = [
        "email", "e-mail", "telefone", "celular", "fone", "whatsapp", "cpf", "documento",
        "token", "senha", "password", "url", "imagem", "foto", "endereco", "nascimento"
    ]
    /// Chaves com "nome" referentes a pessoas (nomes de plano/modalidade/produto continuam registrados).
    private static let personNameFragments = [
        "participante", "cliente", "aluno", "pessoa", "instrutor", "professor",
        "responsavel", "usuario", "social", "completo"
    ]

    static func isSensitive(_ key: String) -> Bool {
        let lower = key.lowercased()
        if sensitiveKeyFragments.contains(where: { lower.contains($0) }) { return true }
        if lower == "nome" { return true }
        if lower.contains("nome") {
            return personNameFragments.contains(where: { lower.contains($0) })
        }
        return false
    }

    static func scalar(_ value: Any) -> NextFitAuditValue? {
        if value is NSNull { return NextFitAuditValue(kind: "nulo", text: "null") }
        if let string = value as? String { return NextFitAuditValue(kind: "texto", text: string) }
        if let number = value as? NSNumber {
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return NextFitAuditValue(kind: "booleano", text: number.boolValue ? "true" : "false")
            }
            return NextFitAuditValue(kind: "numero", text: number.stringValue)
        }
        return nil
    }

    static func omitted(_ value: Any) -> NextFitAuditValue {
        if value is NSNull { return NextFitAuditValue(kind: "omitido", text: "nulo") }
        if let string = value as? String,
           string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return NextFitAuditValue(kind: "omitido", text: "vazio")
        }
        return NextFitAuditValue(kind: "omitido", text: "presente")
    }

    /// Achata o JSON em chaves com caminho (`Modalidades[0].Id`), omitindo valores sensíveis.
    static func flatten(
        _ value: Any,
        path: String,
        depth: Int = 0,
        into result: inout [String: NextFitAuditValue]
    ) {
        if let dictionary = value as? [String: Any] {
            if dictionary.isEmpty {
                if !path.isEmpty { result[path] = NextFitAuditValue(kind: "objeto", text: "{}") }
                return
            }
            guard depth < 4 else {
                result[path] = NextFitAuditValue(kind: "objeto", text: "chaves=\(dictionary.keys.sorted())")
                return
            }
            for (key, child) in dictionary {
                let childPath = path.isEmpty ? key : "\(path).\(key)"
                if isSensitive(key) {
                    result[childPath] = omitted(child)
                } else {
                    flatten(child, path: childPath, depth: depth + 1, into: &result)
                }
            }
        } else if let array = value as? [Any] {
            result[path] = NextFitAuditValue(kind: "lista", text: "n=\(array.count)")
            guard depth < 4 else { return }
            for (index, item) in array.prefix(20).enumerated() {
                flatten(item, path: "\(path)[\(index)]", depth: depth + 1, into: &result)
            }
        } else if let scalar = scalar(value) {
            result[path] = scalar
        } else {
            result[path] = NextFitAuditValue(kind: "desconhecido", text: String(describing: type(of: value)))
        }
    }

    static func int(_ value: Any?) -> Int? {
        guard let value, !(value is NSNull) else { return nil }
        if let string = value as? String { return Int(string.trimmingCharacters(in: .whitespaces)) }
        if let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() {
            return number.intValue
        }
        return nil
    }
}

// MARK: - Modelos persistidos (somente DEBUG)

struct NextFitAuditParticipant: Codable, Equatable {
    let participantId: Int?
    let agendaCode: Int?
    let clientId: Int?
    let contractClientId: Int?
    let status: Int?
    let type: Int?
    /// Guardado apenas no contêiner privado; nunca logado; exportado só com ação explícita.
    let name: String?
    /// Todos os campos de `Participantes[]` efetivamente recebidos (valores sensíveis omitidos).
    let fields: [String: NextFitAuditValue]
    let contractData: String
    let ownContractId: Int?
    let appCategory: String
    let appCategoryReason: String
}

struct NextFitAuditAgendaCapture: Codable, Equatable {
    let captureId: String
    let agendaId: Int
    let capturedAt: Date
    let sessionClientId: Int?
    let phase: String
    let phaseConfirmed: Bool
    let closure: String
    let temporalSituation: String
    let agendaStatusApi: String
    let agendaStartText: String?
    let participantsKeyPresent: Bool
    let agendaFields: [String: NextFitAuditValue]
    let participants: [NextFitAuditParticipant]
    let fingerprint: String
}

struct NextFitAuditContract: Codable, Equatable {
    let id: Int?
    let status: Int?
    let type: Int?
    let descriptionText: String?
    let modalities: [String]
    let fields: [String: NextFitAuditValue]
}

struct NextFitAuditContractsCapture: Codable, Equatable {
    let capturedAt: Date
    let clientId: Int
    let contracts: [NextFitAuditContract]
    let fingerprint: String
}

struct NextFitAuditStoreFile: Codable {
    var version: Int = 1
    var agendaCaptures: [NextFitAuditAgendaCapture] = []
    var ownContracts: NextFitAuditContractsCapture?
}

struct NextFitAuditComparisonRow {
    let situation: String
    let correspondence: String
    let before: NextFitAuditParticipant?
    let after: NextFitAuditParticipant?
    let changedFields: [String]
}

struct NextFitAuditComparison {
    let agendaId: Int
    let state: String
    let before: NextFitAuditAgendaCapture?
    let after: NextFitAuditAgendaCapture?
    let agendaChangedFields: [String]
    let rows: [NextFitAuditComparisonRow]
}

// MARK: - Armazenamento, logs, comparação e exportação

final class NextFitCheckInAuditStore {
    static let shared = NextFitCheckInAuditStore()

    static let logPrefix = "[NextFitCheckInAudit]"

    /// Valores de `Agenda.Status` que COMPROVADAMENTE indicam aula encerrada.
    /// Vazio de propósito: não há semântica documentada/validada para o status da aula.
    /// Preencher somente após confirmação pela NextFit/academia.
    static let confirmedClosedAgendaStatusValues: Set<Int> = []

    static let retentionDays = 14
    static let maxAgendaCaptures = 400

    static let phaseBefore = "ANTES"
    static let phaseAfter = "APOS"
    static let phaseUnconfirmed = "NAO_CONFIRMADA"

    static let priorityAgendaKeys = [
        "Id", "DataInicial", "DataFinal", "Status", "StatusAgendaParticipante", "CodigoModalidade",
        "Descricao", "QtdeAlunos", "LimiteAlunos", "FezCheckin", "PermiteCheckin",
        "PermiteCancelarCheckin", "DataHoraInicioCheckin", "DataHoraFimCheckin"
    ]
    static let priorityParticipantKeys = [
        "Id", "CodigoAgenda", "CodigoCliente", "CodigoContratoCliente", "CodigoOportunidade",
        "NomeParticipante", "Tipo", "Status", "Antecipacao", "Motivo", "PerfilPrivado",
        "Reagendamento", "UrlImagemParticipante"
    ]
    /// Colunas próprias no CSV de participantes (demais campos vão para `camposAdicionais`).
    private static let participantCSVCoreKeys: Set<String> = [
        "Id", "CodigoAgenda", "CodigoCliente", "CodigoContratoCliente", "NomeParticipante",
        "Tipo", "Status", "Motivo", "Reagendamento"
    ]
    private static let expectedContractKeys = ["Id", "Status", "Tipo", "Descricao", "Modalidades"]

    /// Descrições documentadas (Swagger "API Pública Next Fit", já citadas em NextFitModels.swift).
    /// Exibidas apenas como apoio; o número original é sempre preservado.
    private static let participantStatusDescriptions: [Int: String] = [
        1: "Reservado", 2: "Presente", 3: "Falta", 4: "FaltaJustificada",
        5: "Bloqueado", 6: "Suspenso", 7: "Cancelado", 8: "Desistente"
    ]
    private static let participantTypeDescriptions: [Int: String] = [
        1: "Cliente", 2: "ContratoCliente", 3: "Oportunidade", 4: "ClienteServico"
    ]
    private static let contractTypeDescriptions: [Int: String] = [
        1: "Padrao", 2: "Gympass", 3: "GympassBooking", 4: "TotalPass", 5: "TotalPassBooking"
    ]
    private static let contractStatusDescriptions: [Int: String] = [1: "Ativo"]

    private var file = NextFitAuditStoreFile()
    private let directoryURL: URL
    private let storeURL: URL
    private var exportsURL: URL { directoryURL.appendingPathComponent("exports", isDirectory: true) }

    private init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        directoryURL = base.appendingPathComponent("NextFitCheckInAudit", isDirectory: true)
        storeURL = directoryURL.appendingPathComponent("audit-store.json")
        prepareDirectory(directoryURL)

        if UserDefaults.standard.bool(forKey: "NextFitCheckInAuditReset") {
            reset()
        } else {
            load()
            prune()
            persist()
        }
        print([
            "\(Self.logPrefix) ARMAZENAMENTO",
            "diretorio=\(directoryURL.path)",
            "capturasAgenda=\(file.agendaCaptures.count)",
            "contratosProprios=\(file.ownContracts == nil ? "nao-carregados" : "carregados")",
            "retencaoDias=\(Self.retentionDays)",
            "exportacaoAutomaticaPorArgumento=\(UserDefaults.standard.bool(forKey: "NextFitCheckInAuditExport"))"
        ].joined(separator: "\n"))
        exportIfRequestedByLaunchArgument()
    }

    // MARK: Captura do detalhe da aula (`Agenda/{id}`)

    func recordAgendaDetail(data: Data, sessionClientId: Int?) {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = root["Content"] as? [String: Any],
              let agendaId = NextFitAuditSanitizer.int(content["Id"]) else {
            print("\(Self.logPrefix) CAPTURA\nresultado=ignorada-formato-inesperado")
            return
        }
        let now = Date()

        var agendaFields = [String: NextFitAuditValue]()
        for (key, value) in content where key != "Participantes" {
            if NextFitAuditSanitizer.isSensitive(key) {
                agendaFields[key] = NextFitAuditSanitizer.omitted(value)
            } else {
                NextFitAuditSanitizer.flatten(value, path: key, into: &agendaFields)
            }
        }

        let agendaStatusApi = content["Status"].flatMap { NextFitAuditSanitizer.scalar($0)?.text } ?? "ausente"
        let startText = content["DataInicial"] as? String
        let temporal = Self.temporalSituation(
            start: startText,
            end: content["DataFinal"] as? String,
            now: now
        )
        let statusInt = NextFitAuditSanitizer.int(content["Status"])
        let phase: String
        let phaseConfirmed: Bool
        if let statusInt, Self.confirmedClosedAgendaStatusValues.contains(statusInt) {
            phase = Self.phaseAfter
            phaseConfirmed = true
        } else if temporal == "ANTES_DO_INICIO" || temporal == "EM_ANDAMENTO" {
            phase = Self.phaseBefore
            phaseConfirmed = false
        } else {
            phase = Self.phaseUnconfirmed
            phaseConfirmed = false
        }
        let closure = phaseConfirmed && phase == Self.phaseAfter ? "confirmado" : "nao-confirmado"

        let rawParticipants = content["Participantes"] as? [[String: Any]]
        let participants = (rawParticipants ?? []).map { raw -> NextFitAuditParticipant in
            var fields = [String: NextFitAuditValue]()
            NextFitAuditSanitizer.flatten(raw, path: "", into: &fields)
            let participantId = NextFitAuditSanitizer.int(raw["Id"])
            let clientId = NextFitAuditSanitizer.int(raw["CodigoCliente"])
            let contractClientId = NextFitAuditSanitizer.int(raw["CodigoContratoCliente"])
            let status = NextFitAuditSanitizer.int(raw["Status"])
            let type = NextFitAuditSanitizer.int(raw["Tipo"])
            let linkage = contractLinkage(
                clientId: clientId,
                contractClientId: contractClientId,
                sessionClientId: sessionClientId
            )
            // Mesma regra do app (somente leitura): registra a categoria exibida no momento da captura
            let resolution = NextFitParticipantCategoryResolver.resolve(
                participant: NextFitAgendaParticipantDisplay(
                    id: participantId ?? 0,
                    name: "",
                    clientId: clientId,
                    contractClientId: contractClientId,
                    status: status,
                    type: type
                ),
                ownContractType: linkage.contract?.type
            )
            let name = (raw["NomeParticipante"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return NextFitAuditParticipant(
                participantId: participantId,
                agendaCode: NextFitAuditSanitizer.int(raw["CodigoAgenda"]),
                clientId: clientId,
                contractClientId: contractClientId,
                status: status,
                type: type,
                name: (name?.isEmpty ?? true) ? nil : name,
                fields: fields,
                contractData: linkage.description,
                ownContractId: linkage.contract?.id,
                appCategory: "\(resolution.category)",
                appCategoryReason: resolution.reason
            )
        }

        let fingerprint = Self.fingerprint(phase: phase, agendaFields: agendaFields, participants: participants)
        // Evita registros idênticos a cada atualização da tela
        if let last = file.agendaCaptures.last(where: { $0.agendaId == agendaId }),
           last.fingerprint == fingerprint {
            return
        }

        let capture = NextFitAuditAgendaCapture(
            captureId: UUID().uuidString,
            agendaId: agendaId,
            capturedAt: now,
            sessionClientId: sessionClientId,
            phase: phase,
            phaseConfirmed: phaseConfirmed,
            closure: closure,
            temporalSituation: temporal,
            agendaStatusApi: agendaStatusApi,
            agendaStartText: startText,
            participantsKeyPresent: rawParticipants != nil,
            agendaFields: agendaFields,
            participants: participants,
            fingerprint: fingerprint
        )
        file.agendaCaptures.append(capture)
        prune()
        persist()

        logCapture(capture)
        if phase != Self.phaseBefore {
            logComparison(comparison(for: agendaId))
        }
        exportIfRequestedByLaunchArgument()
    }

    // MARK: Captura dos contratos do próprio aluno (`Cliente/RecuperarDadosPrincipais`)

    func recordClientMainData(data: Data, sessionClientId: Int?) {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = root["Content"] as? [String: Any] else {
            print("\(Self.logPrefix) CONTRATO_PROPRIO\nresultado=ignorado-formato-inesperado")
            return
        }
        guard let clientId = NextFitAuditSanitizer.int(content["CodigoCliente"]),
              let sessionClientId,
              clientId == sessionClientId else {
            print("\(Self.logPrefix) CONTRATO_PROPRIO\nresultado=descartado-cliente-nao-confere-com-sessao")
            return
        }

        let rawContracts = content["Contratos"] as? [[String: Any]] ?? []
        let contracts = rawContracts.map { raw -> NextFitAuditContract in
            var fields = [String: NextFitAuditValue]()
            NextFitAuditSanitizer.flatten(raw, path: "", into: &fields)
            let modalities = (raw["Modalidades"] as? [[String: Any]] ?? []).map { modality in
                "Id=\(Self.rawText(modality["Id"]));CodigoModalidade=\(Self.rawText(modality["CodigoModalidade"]))"
            }
            return NextFitAuditContract(
                id: NextFitAuditSanitizer.int(raw["Id"]),
                status: NextFitAuditSanitizer.int(raw["Status"]),
                type: NextFitAuditSanitizer.int(raw["Tipo"]),
                descriptionText: raw["Descricao"] as? String,
                modalities: modalities,
                fields: fields
            )
        }
        let fingerprint = "\(clientId)|" + contracts
            .map { Self.canonical($0.fields) }
            .sorted()
            .joined(separator: "#")
        if let current = file.ownContracts, current.fingerprint == fingerprint {
            return
        }

        file.ownContracts = NextFitAuditContractsCapture(
            capturedAt: Date(),
            clientId: clientId,
            contracts: contracts,
            fingerprint: fingerprint
        )
        persist()
        logContracts(file.ownContracts!, contentKeysPresent: content["Contratos"] != nil)
        exportIfRequestedByLaunchArgument()
    }

    // MARK: Comparação ANTES x APÓS

    func comparison(for agendaId: Int) -> NextFitAuditComparison {
        let captures = file.agendaCaptures
            .filter { $0.agendaId == agendaId }
            .sorted { $0.capturedAt < $1.capturedAt }
        let before = captures.first { $0.phase == Self.phaseBefore }
        let later = captures.filter {
            $0.phase != Self.phaseBefore && (before == nil || $0.capturedAt > before!.capturedAt)
        }
        let after = later.last(where: { $0.phase == Self.phaseAfter }) ?? later.last

        guard let after else {
            return NextFitAuditComparison(
                agendaId: agendaId,
                state: before == nil ? "sem-capturas" : "aguardando-captura-posterior",
                before: before, after: nil, agendaChangedFields: [], rows: []
            )
        }
        guard let before else {
            // Não inventa o estado anterior a partir do posterior
            return NextFitAuditComparison(
                agendaId: agendaId,
                state: "sem-captura-anterior",
                before: nil, after: after, agendaChangedFields: [],
                rows: after.participants.map {
                    NextFitAuditComparisonRow(
                        situation: "sem-captura-anterior", correspondence: "n/a",
                        before: nil, after: $0, changedFields: []
                    )
                }
            )
        }

        let beforeIndex = Self.index(before.participants)
        let afterIndex = Self.index(after.participants)
        let ambiguousIds = beforeIndex.duplicatedIds.union(afterIndex.duplicatedIds)
        var rows = [NextFitAuditComparisonRow]()

        let allIds = Set(beforeIndex.unique.keys).union(afterIndex.unique.keys).subtracting(ambiguousIds).sorted()
        for id in allIds {
            let old = beforeIndex.unique[id]
            let new = afterIndex.unique[id]
            switch (old, new) {
            case let (old?, new?):
                var reasons = [String]()
                if [old.agendaCode, new.agendaCode].contains(where: { $0 != nil && $0 != agendaId }) {
                    reasons.append("CodigoAgenda-divergente")
                }
                if old.clientId != new.clientId {
                    reasons.append(old.clientId == nil || new.clientId == nil
                        ? "CodigoCliente-ausente-em-uma-captura" : "CodigoCliente-divergente")
                }
                if let a = old.contractClientId, let b = new.contractClientId, a != b {
                    reasons.append("CodigoContratoCliente-divergente")
                }
                rows.append(NextFitAuditComparisonRow(
                    situation: reasons.isEmpty ? "presente-nas-duas" : "sem-correspondencia-confiavel",
                    correspondence: reasons.isEmpty ? "confirmada" : "nao-confirmada(\(reasons.joined(separator: ",")))",
                    before: old, after: new,
                    changedFields: Self.changedKeys(old.fields, new.fields)
                ))
            case let (old?, nil):
                rows.append(NextFitAuditComparisonRow(
                    situation: "ausente-na-segunda", correspondence: "n/a",
                    before: old, after: nil, changedFields: []
                ))
            case let (nil, new?):
                rows.append(NextFitAuditComparisonRow(
                    situation: "incluido-depois", correspondence: "n/a",
                    before: nil, after: new, changedFields: []
                ))
            default:
                break
            }
        }
        for participant in beforeIndex.unreliable + afterIndex.unreliable {
            let isBefore = beforeIndex.unreliable.contains(participant)
            rows.append(NextFitAuditComparisonRow(
                situation: "sem-correspondencia-confiavel",
                correspondence: participant.participantId == nil
                    ? "nao-confirmada(Id-ausente)" : "nao-confirmada(Id-duplicado)",
                before: isBefore ? participant : nil,
                after: isBefore ? nil : participant,
                changedFields: []
            ))
        }

        return NextFitAuditComparison(
            agendaId: agendaId,
            state: "ok",
            before: before,
            after: after,
            agendaChangedFields: Self.changedKeys(before.agendaFields, after.agendaFields),
            rows: rows
        )
    }

    func printComparisons() {
        let agendaIds = Set(file.agendaCaptures.map(\.agendaId)).sorted()
        if agendaIds.isEmpty {
            print("\(Self.logPrefix) COMPARACAO\nresultado=sem-capturas")
        }
        agendaIds.forEach { logComparison(comparison(for: $0)) }
    }

    // MARK: Exportação CSV (ação explícita do desenvolvedor)

    @discardableResult
    func exportCSV(includeNames: Bool = false) -> [URL] {
        prepareDirectory(exportsURL)
        if includeNames {
            print("\(Self.logPrefix) EXPORTACAO\nATENCAO=arquivo-contem-dados-pessoais(nomes-dos-participantes)-nao-compartilhar-sem-autorizacao")
        }
        let suffix = includeNames ? "_COM_NOMES_DADOS_PESSOAIS" : ""
        let participantsURL = exportsURL.appendingPathComponent("nextfit_participantes\(suffix).csv")
        let comparisonURL = exportsURL.appendingPathComponent("nextfit_comparativo\(suffix).csv")

        var written = [URL]()
        if write(participantsCSV(includeNames: includeNames), to: participantsURL) { written.append(participantsURL) }
        if write(comparisonCSV(includeNames: includeNames), to: comparisonURL) { written.append(comparisonURL) }
        print([
            "\(Self.logPrefix) EXPORTACAO",
            "nomesIncluidos=\(includeNames)",
            "arquivos=\(written.map(\.path))"
        ].joined(separator: "\n"))
        return written
    }

    func reset() {
        file = NextFitAuditStoreFile()
        try? FileManager.default.removeItem(at: exportsURL)
        persist()
        print("\(Self.logPrefix) LIMPEZA\nresultado=capturas-e-exportacoes-removidas")
    }

    // MARK: - Privados: vínculo com contrato próprio

    private func ownContract(
        clientId: Int?,
        contractClientId: Int?,
        sessionClientId: Int?
    ) -> NextFitAuditContract? {
        guard let own = file.ownContracts,
              let sessionClientId, own.clientId == sessionClientId,
              let contractClientId else {
            return nil
        }
        if let clientId, clientId != own.clientId { return nil }
        return own.contracts.first { $0.id == contractClientId }
    }

    private func contractLinkage(
        clientId: Int?,
        contractClientId: Int?,
        sessionClientId: Int?
    ) -> (description: String, contract: NextFitAuditContract?) {
        if let contract = ownContract(
            clientId: clientId, contractClientId: contractClientId, sessionClientId: sessionClientId
        ) {
            return ("contrato-proprio", contract)
        }
        guard let sessionClientId else { return ("indeterminado-sem-cliente-da-sessao", nil) }
        if let clientId, clientId == sessionClientId {
            let loaded = file.ownContracts?.clientId == sessionClientId
            return (loaded ? "proprio-contrato-nao-localizado" : "proprio-contratos-ainda-nao-carregados", nil)
        }
        // Não há acesso autorizado a contratos de terceiros pela API do aluno
        return ("nao-disponiveis-para-terceiros", nil)
    }

    private static func confirmedCategory(for contract: NextFitAuditContract?) -> String {
        switch contract?.type {
        case 2?, 3?: return "WELLHUB"
        case 4?, 5?: return "TOTALPASS"
        default: return ""
        }
    }

    // MARK: - Privados: logs

    private func logCapture(_ capture: NextFitAuditAgendaCapture) {
        var lines = [
            "\(Self.logPrefix) CAPTURA",
            "agendaId=\(capture.agendaId)",
            "capturadoEm=\(Self.timestamp(capture.capturedAt))",
            "fase=\(capture.phase)",
            "faseConfirmada=\(capture.phaseConfirmed)",
            "encerramento=\(capture.closure)",
            "situacaoTemporalCalculadaPeloApp=\(capture.temporalSituation)",
            "statusAula(Agenda.Status)=\(capture.agendaStatusApi)"
        ]
        for key in Self.priorityAgendaKeys {
            if let value = capture.agendaFields[key] {
                lines.append("Agenda.\(key)=\(value.text) (\(value.kind))")
            }
        }
        let missingAgenda = Self.priorityAgendaKeys.filter { capture.agendaFields[$0] == nil }
        lines.append("camposAgendaAusentesNaResposta=\(missingAgenda)")
        let extraAgenda = capture.agendaFields.keys
            .filter { !Self.priorityAgendaKeys.contains($0) }
            .sorted()
            .map { "\($0)=\(capture.agendaFields[$0]!.text)" }
        lines.append("camposAgendaAdicionais=\(extraAgenda)")
        lines.append("participantesNaResposta=\(capture.participantsKeyPresent ? "presente" : "ausente")")
        lines.append("totalParticipantes=\(capture.participants.count)")
        let participantKeys = Set(capture.participants.flatMap { $0.fields.keys }).sorted()
        lines.append("camposParticipantesEncontrados=\(participantKeys)")
        var distribution = [String: Int]()
        capture.participants.forEach { distribution[$0.status.map(String.init) ?? "nil", default: 0] += 1 }
        lines.append("distribuicaoStatusParticipantes=\(distribution.sorted { $0.key < $1.key }.map { "\($0.key):\($0.value)" })")
        print(lines.joined(separator: "\n"))

        for participant in capture.participants {
            logParticipant(participant, agendaId: capture.agendaId)
        }
    }

    private func logParticipant(_ participant: NextFitAuditParticipant, agendaId: Int) {
        let f = participant.fields
        func show(_ key: String) -> String { f[key].map { "\($0.text) (\($0.kind))" } ?? "ausente" }
        var lines = [
            "\(Self.logPrefix) PARTICIPANTE",
            "agendaId=\(agendaId)",
            "participanteId=\(show("Id"))",
            "codigoAgenda=\(show("CodigoAgenda"))",
            "codigoCliente=\(show("CodigoCliente"))",
            "codigoContratoCliente=\(show("CodigoContratoCliente"))",
            "codigoOportunidade=\(show("CodigoOportunidade"))",
            "tipoParticipante=\(show("Tipo"))\(Self.documented(participant.type, Self.participantTypeDescriptions, "EnumTipoAgendaParticipante"))",
            "statusParticipante=\(show("Status"))\(Self.documented(participant.status, Self.participantStatusDescriptions, "EnumStatusAgendaParticipante"))",
            "antecipacao=\(show("Antecipacao"))",
            "motivo=\(show("Motivo"))",
            "perfilPrivado=\(show("PerfilPrivado"))",
            "reagendamento=\(show("Reagendamento"))",
            "urlImagemParticipante=\(f["UrlImagemParticipante"]?.text ?? "ausente")",
            "nomeParticipante=\(f["NomeParticipante"] == nil ? "ausente" : "<omitido-no-log>")"
        ]
        let extra = f.keys
            .filter { !Self.priorityParticipantKeys.contains($0) }
            .sorted()
            .map { "\($0)=\(f[$0]!.text) (\(f[$0]!.kind))" }
        lines.append("camposAdicionais=\(extra)")
        lines.append("dadosContrato=\(participant.contractData)")
        if let contractId = participant.ownContractId { lines.append("contratoProprioId=\(contractId)") }
        lines.append("categoriaApp=\(participant.appCategory) motivoCategoriaApp=\(participant.appCategoryReason)")
        print(lines.joined(separator: "\n"))
    }

    private func logContracts(_ capture: NextFitAuditContractsCapture, contentKeysPresent: Bool) {
        if capture.contracts.isEmpty {
            print([
                "\(Self.logPrefix) CONTRATO_PROPRIO",
                "codigoCliente=\(capture.clientId)",
                "contratos=\(contentKeysPresent ? "lista-vazia" : "campo-Contratos-ausente")"
            ].joined(separator: "\n"))
            return
        }
        for contract in capture.contracts {
            let f = contract.fields
            let topLevelKeys = Set(f.keys.map { String($0.split(separator: ".").first ?? "")
                .components(separatedBy: "[").first ?? "" })
            let missingOrNull = Self.expectedContractKeys.filter { f[$0] == nil || f[$0]?.kind == "nulo" }
            let additional = f.keys
                .filter { key in !Self.expectedContractKeys.contains(where: { key == $0 || key.hasPrefix("\($0)[") || key.hasPrefix("\($0).") }) }
                .sorted()
                .map { "\($0)=\(f[$0]!.text) (\(f[$0]!.kind))" }
            let nullKeys = f.filter { $0.value.kind == "nulo" }.keys.sorted()
            let kinds = topLevelKeys.sorted().compactMap { key in f[key].map { "\(key):\($0.kind)" } }
            print([
                "\(Self.logPrefix) CONTRATO_PROPRIO",
                "codigoCliente=\(capture.clientId)",
                "capturadoEm=\(Self.timestamp(capture.capturedAt))",
                "contratoId=\(contract.id.map(String.init) ?? "ausente")",
                "tipoContrato=\(f["Tipo"]?.text ?? "ausente")\(Self.documented(contract.type, Self.contractTypeDescriptions, "EnumTipoContratoBase"))",
                "statusContrato=\(f["Status"]?.text ?? "ausente")\(Self.documented(contract.status, Self.contractStatusDescriptions, "Contratos[].Status"))",
                "descricao=\(contract.descriptionText ?? (f["Descricao"] == nil ? "ausente" : "null"))",
                "modalidades=\(contract.modalities)",
                "camposAdicionais=\(additional)",
                "camposEsperadosAusentesOuNulos=\(missingOrNull)",
                "camposNulos=\(nullKeys)",
                "tiposDosValores(numero=codigo,texto=descricao)=\(kinds)",
                "chavesCandidatasPeriodo=\(Self.candidateKeys(f, ["data", "inicio", "fim", "vigencia", "validade", "periodo", "vencimento", "duracao"]))",
                "chavesCandidatasSessoesCreditos=\(Self.candidateKeys(f, ["sessao", "sessoes", "credito", "saldo", "qtde", "quantidade", "aulas"]))",
                "chavesCandidatasConvenio=\(Self.candidateKeys(f, ["convenio", "gympass", "wellhub", "totalpass", "parceiro", "agregador", "integracao"]))",
                "chavesCandidatasProduto=\(Self.candidateKeys(f, ["plano", "produto", "servico", "pacote", "mensal"]))",
                "categoriaConfirmadaApi=\(Self.confirmedCategory(for: contract).isEmpty ? "sem-evidencia" : Self.confirmedCategory(for: contract))"
            ].joined(separator: "\n"))
        }
    }

    private func logComparison(_ comparison: NextFitAuditComparison) {
        var header = [
            "\(Self.logPrefix) COMPARACAO_RESUMO",
            "agendaId=\(comparison.agendaId)"
        ]
        switch comparison.state {
        case "sem-captura-anterior":
            header.append("comparacao=sem-captura-anterior")
        case "aguardando-captura-posterior":
            header.append("comparacao=aguardando-captura-posterior")
        case "sem-capturas":
            header.append("comparacao=sem-capturas")
        default:
            header.append("comparacao=ok")
        }
        if let before = comparison.before {
            header.append("capturaAntes=\(Self.timestamp(before.capturedAt)) faseAntes=\(before.phase) statusAulaAntes=\(before.agendaStatusApi)")
        }
        if let after = comparison.after {
            header.append("capturaApos=\(Self.timestamp(after.capturedAt)) faseApos=\(after.phase) statusAulaDepois=\(after.agendaStatusApi)")
            header.append("encerramento=\(after.closure)")
        }
        guard comparison.state == "ok" else {
            print(header.joined(separator: "\n"))
            return
        }
        let count: (String) -> Int = { situation in comparison.rows.filter { $0.situation == situation }.count }
        header.append("alteracoesAula=\(comparison.agendaChangedFields)")
        header.append("presentesNasDuas=\(count("presente-nas-duas"))")
        header.append("incluidosDepois=\(count("incluido-depois"))")
        header.append("ausentesNaSegunda=\(count("ausente-na-segunda"))")
        header.append("semCorrespondenciaConfiavel=\(count("sem-correspondencia-confiavel"))")
        header.append("observacao=ausencia-na-segunda-captura-nao-comprova-cancelamento-falta-ou-exclusao")
        print(header.joined(separator: "\n"))

        for row in comparison.rows {
            let reference = row.after ?? row.before
            print([
                "\(Self.logPrefix) COMPARACAO",
                "agendaId=\(comparison.agendaId)",
                "participanteId=\(reference?.participantId.map(String.init) ?? "ausente")",
                "codigoCliente=\(reference?.clientId.map(String.init) ?? "ausente")",
                "codigoContratoCliente=\(reference?.contractClientId.map(String.init) ?? "ausente")",
                "situacao=\(row.situation)",
                "correspondencia=\(row.correspondence)",
                "statusAntes=\(Self.fieldText(row.before, "Status"))",
                "statusDepois=\(Self.fieldText(row.after, "Status"))",
                "tipoAntes=\(Self.fieldText(row.before, "Tipo"))",
                "tipoDepois=\(Self.fieldText(row.after, "Tipo"))",
                "codigoContratoClienteAntes=\(Self.fieldText(row.before, "CodigoContratoCliente"))",
                "codigoContratoClienteDepois=\(Self.fieldText(row.after, "CodigoContratoCliente"))",
                "motivoAntes=\(Self.fieldText(row.before, "Motivo")) motivoDepois=\(Self.fieldText(row.after, "Motivo"))",
                "reagendamentoAntes=\(Self.fieldText(row.before, "Reagendamento")) reagendamentoDepois=\(Self.fieldText(row.after, "Reagendamento"))",
                "alteracoes=\(row.changedFields)",
                "categoriaAppAntes=\(row.before?.appCategory ?? "-") categoriaAppDepois=\(row.after?.appCategory ?? "-") categoriaAppMudou=\(Self.categoryChanged(row))"
            ].joined(separator: "\n"))
        }
    }

    // MARK: - Privados: CSV

    private func participantsCSV(includeNames: Bool) -> String {
        var header = [
            "dataAula", "horaInicialAula", "agendaId", "participanteId", "codigoCliente",
            "codigoContratoCliente", "fase", "faseConfirmada", "encerramento", "situacaoTemporalApp",
            "capturadoEm", "statusAula", "statusParticipante", "tipoParticipante", "motivo",
            "reagendamento", "dadosContrato", "categoriaApp", "camposAdicionais"
        ]
        if includeNames { header.append("nomeParticipante") }
        var rows = [header]
        let captures = file.agendaCaptures.sorted {
            ($0.agendaId, $0.capturedAt) < ($1.agendaId, $1.capturedAt)
        }
        for capture in captures {
            let (date, time) = Self.splitAgendaStart(capture.agendaStartText)
            for participant in capture.participants {
                let extras = participant.fields.keys
                    .filter { !Self.participantCSVCoreKeys.contains($0) }
                    .sorted()
                    .map { "\($0)=\(participant.fields[$0]!.text)" }
                    .joined(separator: " | ")
                var row = [
                    date, time, String(capture.agendaId),
                    participant.participantId.map(String.init) ?? "",
                    participant.clientId.map(String.init) ?? "",
                    participant.contractClientId.map(String.init) ?? "",
                    capture.phase, capture.phaseConfirmed ? "true" : "false", capture.closure,
                    capture.temporalSituation, Self.timestamp(capture.capturedAt), capture.agendaStatusApi,
                    Self.fieldText(participant, "Status", absent: ""),
                    Self.fieldText(participant, "Tipo", absent: ""),
                    Self.fieldText(participant, "Motivo", absent: ""),
                    Self.fieldText(participant, "Reagendamento", absent: ""),
                    participant.contractData, participant.appCategory, extras
                ]
                if includeNames { row.append(participant.name ?? "") }
                rows.append(row)
            }
        }
        return Self.csv(rows)
    }

    private func comparisonCSV(includeNames: Bool) -> String {
        var header = [
            "agendaId", "dataAula", "horaInicialAula", "participanteId", "codigoCliente",
            "codigoContratoCliente", "comparacao", "situacao", "correspondencia", "faseAntes",
            "capturadoAntes", "faseApos", "capturadoApos", "encerramento", "statusAulaAntes",
            "statusAulaApos", "statusAntes", "statusApos", "tipoAntes", "tipoApos",
            "camposModificados", "alteracoesAula", "categoriaAppAntes", "categoriaAppApos",
            "categoriaAppMudou", "contratoProprioRecuperavel", "categoriaConfirmadaApi",
            "categoriaValidacaoAcademia(MENSALISTA|PACOTE|WELLHUB|TOTALPASS|OUTRO)"
        ]
        if includeNames { header.append("nomeParticipante") }
        var rows = [header]

        for agendaId in Set(file.agendaCaptures.map(\.agendaId)).sorted() {
            let comparison = self.comparison(for: agendaId)
            let reference = comparison.after ?? comparison.before
            let (date, time) = Self.splitAgendaStart(reference?.agendaStartText)
            let comparisonRows: [NextFitAuditComparisonRow] = comparison.state == "aguardando-captura-posterior"
                ? (comparison.before?.participants ?? []).map {
                    NextFitAuditComparisonRow(situation: "aguardando-captura-posterior", correspondence: "n/a",
                                              before: $0, after: nil, changedFields: [])
                }
                : comparison.rows
            for row in comparisonRows {
                let participant = row.after ?? row.before
                let sessionClientId = (row.after != nil ? comparison.after : comparison.before)?.sessionClientId
                let linkage = contractLinkage(
                    clientId: participant?.clientId,
                    contractClientId: participant?.contractClientId,
                    sessionClientId: sessionClientId
                )
                var line = [
                    String(agendaId), date, time,
                    participant?.participantId.map(String.init) ?? "",
                    participant?.clientId.map(String.init) ?? "",
                    participant?.contractClientId.map(String.init) ?? "",
                    comparison.state, row.situation, row.correspondence,
                    row.before == nil ? "" : (comparison.before?.phase ?? ""),
                    row.before == nil ? "" : comparison.before.map { Self.timestamp($0.capturedAt) } ?? "",
                    row.after == nil ? "" : (comparison.after?.phase ?? ""),
                    row.after == nil ? "" : comparison.after.map { Self.timestamp($0.capturedAt) } ?? "",
                    comparison.after?.closure ?? "nao-confirmado",
                    row.before == nil ? "" : (comparison.before?.agendaStatusApi ?? ""),
                    row.after == nil ? "" : (comparison.after?.agendaStatusApi ?? ""),
                    Self.fieldText(row.before, "Status", absent: ""),
                    Self.fieldText(row.after, "Status", absent: ""),
                    Self.fieldText(row.before, "Tipo", absent: ""),
                    Self.fieldText(row.after, "Tipo", absent: ""),
                    row.changedFields.joined(separator: " | "),
                    comparison.agendaChangedFields.joined(separator: " | "),
                    row.before?.appCategory ?? "",
                    row.after?.appCategory ?? "",
                    Self.categoryChanged(row),
                    linkage.contract == nil ? linkage.description : "sim",
                    Self.confirmedCategory(for: linkage.contract),
                    "" // preenchimento manual pela academia; nunca inferido
                ]
                if includeNames { line.append(participant?.name ?? "") }
                rows.append(line)
            }
        }
        return Self.csv(rows)
    }

    private func write(_ text: String, to url: URL) -> Bool {
        do {
            // BOM UTF-8 para acentuação correta no Excel
            try Data(("\u{FEFF}" + text).utf8).write(
                to: url,
                options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
            )
            return true
        } catch {
            print("\(Self.logPrefix) EXPORTACAO\nerro=\(error.localizedDescription)")
            return false
        }
    }

    private func exportIfRequestedByLaunchArgument() {
        guard UserDefaults.standard.bool(forKey: "NextFitCheckInAuditExport") else { return }
        exportCSV(includeNames: UserDefaults.standard.bool(forKey: "NextFitCheckInAuditIncludeNames"))
    }

    // MARK: - Privados: persistência

    private func prepareDirectory(_ url: URL) {
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        var resourceURL = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? resourceURL.setResourceValues(values)
    }

    private func load() {
        guard let data = try? Data(contentsOf: storeURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode(NextFitAuditStoreFile.self, from: data) {
            file = decoded
        } else {
            print("\(Self.logPrefix) ARMAZENAMENTO\nresultado=arquivo-invalido-reiniciado")
        }
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(file) else { return }
        do {
            try data.write(to: storeURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        } catch {
            print("\(Self.logPrefix) ARMAZENAMENTO\nerro=\(error.localizedDescription)")
        }
    }

    private func prune() {
        let cutoff = Date().addingTimeInterval(-Double(Self.retentionDays) * 86_400)
        file.agendaCaptures = file.agendaCaptures
            .filter { $0.capturedAt >= cutoff }
            .sorted { $0.capturedAt < $1.capturedAt }
        if file.agendaCaptures.count > Self.maxAgendaCaptures {
            file.agendaCaptures = Array(file.agendaCaptures.suffix(Self.maxAgendaCaptures))
        }
        if let own = file.ownContracts, own.capturedAt < cutoff {
            file.ownContracts = nil
        }
    }

    // MARK: - Privados: utilitários

    private static func index(
        _ participants: [NextFitAuditParticipant]
    ) -> (unique: [Int: NextFitAuditParticipant], duplicatedIds: Set<Int>, unreliable: [NextFitAuditParticipant]) {
        var groups = [Int: [NextFitAuditParticipant]]()
        var unreliable = [NextFitAuditParticipant]()
        for participant in participants {
            if let id = participant.participantId {
                groups[id, default: []].append(participant)
            } else {
                unreliable.append(participant)
            }
        }
        let duplicated = groups.filter { $0.value.count > 1 }
        unreliable += duplicated.values.flatMap { $0 }
        let unique = groups.filter { $0.value.count == 1 }.mapValues { $0[0] }
        return (unique, Set(duplicated.keys), unreliable)
    }

    private static func changedKeys(
        _ lhs: [String: NextFitAuditValue],
        _ rhs: [String: NextFitAuditValue]
    ) -> [String] {
        Set(lhs.keys).union(rhs.keys).filter { lhs[$0] != rhs[$0] }.sorted()
    }

    private static func categoryChanged(_ row: NextFitAuditComparisonRow) -> String {
        guard let before = row.before, let after = row.after else { return "n/a" }
        return before.appCategory == after.appCategory ? "nao" : "sim"
    }

    private static func fieldText(
        _ participant: NextFitAuditParticipant?,
        _ key: String,
        absent: String = "ausente"
    ) -> String {
        guard let participant else { return absent.isEmpty ? "" : "-" }
        return participant.fields[key]?.text ?? absent
    }

    private static func documented(_ value: Int?, _ table: [Int: String], _ enumName: String) -> String {
        guard let value, let description = table[value] else { return "" }
        return " [documentado \(enumName): \(description)]"
    }

    private static func candidateKeys(_ fields: [String: NextFitAuditValue], _ fragments: [String]) -> [String] {
        fields.keys.filter { key in
            let last = (key.split(separator: ".").last.map(String.init) ?? key).lowercased()
            return fragments.contains { last.contains($0) }
        }.sorted()
    }

    private static func rawText(_ value: Any?) -> String {
        guard let value else { return "ausente" }
        return NextFitAuditSanitizer.scalar(value)?.text ?? "ausente"
    }

    private static func canonical(_ fields: [String: NextFitAuditValue]) -> String {
        fields.keys.sorted().map { "\($0)=\(fields[$0]!.kind):\(fields[$0]!.text)" }.joined(separator: "&")
    }

    /// Exclui horário da coleta, vínculo contratual e categoria do app (derivados localmente).
    private static func fingerprint(
        phase: String,
        agendaFields: [String: NextFitAuditValue],
        participants: [NextFitAuditParticipant]
    ) -> String {
        let participantPart = participants
            .map { canonical($0.fields) }
            .sorted()
            .joined(separator: "#")
        return "\(phase)|\(canonical(agendaFields))|\(participantPart)"
    }

    private static func agendaDate(_ value: String?) -> Date? {
        guard let value else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        return formatter.date(from: value)
    }

    /// Situação temporal calculada pelo app (NÃO confirma encerramento).
    private static func temporalSituation(start: String?, end: String?, now: Date) -> String {
        guard let startDate = agendaDate(start), let endDate = agendaDate(end) else {
            return "INDETERMINADA"
        }
        if now < startDate { return "ANTES_DO_INICIO" }
        if now <= endDate { return "EM_ANDAMENTO" }
        return "APOS_HORARIO_FINAL"
    }

    private static func splitAgendaStart(_ value: String?) -> (String, String) {
        guard let value else { return ("", "") }
        let parts = value.split(separator: " ", maxSplits: 1).map(String.init)
        return (parts.first ?? "", parts.count > 1 ? parts[1] : "")
    }

    private static func timestamp(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = .current
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    private static func csv(_ rows: [[String]]) -> String {
        rows.map { row in
            row.map { cell in
                let needsQuotes = cell.contains(";") || cell.contains("\"") || cell.contains("\n") || cell.contains("\r")
                return needsQuotes ? "\"\(cell.replacingOccurrences(of: "\"", with: "\"\""))\"" : cell
            }.joined(separator: ";")
        }.joined(separator: "\r\n") + "\r\n"
    }
}
#endif


