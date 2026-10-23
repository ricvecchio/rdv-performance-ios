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
// - Nomes de participantes nunca são exibidos em logs; entram SEMPRE na exportação (planilha/CSV),
//   gerada somente por ação explícita, para conferência dos contratos com a academia.
//
// Ações do desenvolvedor (sem alteração de interface):
// - Argumentos de execução (Xcode › Edit Scheme › Run › Arguments Passed On Launch):
//     -NextFitCheckInAuditExport YES        gera/atualiza planilha e CSVs a cada nova captura
//     -NextFitCheckInAuditReset YES         limpa todas as capturas ao iniciar o diagnóstico
// - Console LLDB (app pausado):
//     po NextFitCheckInAuditStore.shared.exportCSV()
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
    private static let sensitiveKeyFragments: [String] = [
        "email", "e-mail", "telefone", "celular", "fone", "whatsapp", "cpf", "documento",
        "token", "senha", "password", "url", "imagem", "foto", "endereco", "nascimento"
    ]
    /// Chaves com "nome" referentes a pessoas (nomes de plano/modalidade/produto continuam registrados).
    private static let personNameFragments: [String] = [
        "participante", "cliente", "aluno", "pessoa", "instrutor", "professor",
        "responsavel", "usuario", "social", "completo"
    ]

    static func isSensitive(_ key: String) -> Bool {
        let lower: String = key.lowercased()
        for fragment in sensitiveKeyFragments where lower.contains(fragment) {
            return true
        }
        if lower == "nome" { return true }
        guard lower.contains("nome") else { return false }
        for fragment in personNameFragments where lower.contains(fragment) {
            return true
        }
        return false
    }

    static func scalar(_ value: Any) -> NextFitAuditValue? {
        if value is NSNull {
            return NextFitAuditValue(kind: "nulo", text: "null")
        }
        if let string = value as? String {
            return NextFitAuditValue(kind: "texto", text: string)
        }
        if let number = value as? NSNumber {
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                let boolText: String = number.boolValue ? "true" : "false"
                return NextFitAuditValue(kind: "booleano", text: boolText)
            }
            return NextFitAuditValue(kind: "numero", text: number.stringValue)
        }
        return nil
    }

    static func omitted(_ value: Any) -> NextFitAuditValue {
        if value is NSNull {
            return NextFitAuditValue(kind: "omitido", text: "nulo")
        }
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
                if !path.isEmpty {
                    result[path] = NextFitAuditValue(kind: "objeto", text: "{}")
                }
                return
            }
            guard depth < 4 else {
                let keysText: String = dictionary.keys.sorted().joined(separator: ",")
                result[path] = NextFitAuditValue(kind: "objeto", text: "chaves=[\(keysText)]")
                return
            }
            for (key, child) in dictionary {
                let childPath: String = path.isEmpty ? key : path + "." + key
                if isSensitive(key) {
                    result[childPath] = omitted(child)
                } else {
                    flatten(child, path: childPath, depth: depth + 1, into: &result)
                }
            }
            return
        }
        if let array = value as? [Any] {
            result[path] = NextFitAuditValue(kind: "lista", text: "n=\(array.count)")
            guard depth < 4 else { return }
            for (index, item) in array.prefix(20).enumerated() {
                let itemPath: String = path + "[" + String(index) + "]"
                flatten(item, path: itemPath, depth: depth + 1, into: &result)
            }
            return
        }
        if let scalarValue = scalar(value) {
            result[path] = scalarValue
            return
        }
        result[path] = NextFitAuditValue(kind: "desconhecido", text: String(describing: type(of: value)))
    }

    static func int(_ value: Any?) -> Int? {
        guard let value, !(value is NSNull) else { return nil }
        if let string = value as? String {
            return Int(string.trimmingCharacters(in: .whitespaces))
        }
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

struct NextFitAuditContractLinkage {
    let description: String
    let contract: NextFitAuditContract?
}

struct NextFitAuditParticipantIndex {
    let unique: [Int: NextFitAuditParticipant]
    let duplicatedIds: Set<Int>
    let unreliable: [NextFitAuditParticipant]
}

// MARK: - Armazenamento, logs, comparação e exportação

final class NextFitCheckInAuditStore {
    static let shared = NextFitCheckInAuditStore()

    static let logPrefix: String = "[NextFitCheckInAudit]"

    /// Valores de `Agenda.Status` que COMPROVADAMENTE indicam aula encerrada.
    /// Vazio de propósito: não há semântica documentada/validada para o status da aula.
    /// Preencher somente após confirmação pela NextFit/academia.
    static let confirmedClosedAgendaStatusValues: Set<Int> = []

    static let retentionDays: Int = 14
    static let maxAgendaCaptures: Int = 400

    static let phaseBefore: String = "ANTES"
    static let phaseAfter: String = "APOS"
    static let phaseUnconfirmed: String = "NAO_CONFIRMADA"

    static let priorityAgendaKeys: [String] = [
        "Id", "DataInicial", "DataFinal", "Status", "StatusAgendaParticipante", "CodigoModalidade",
        "Descricao", "QtdeAlunos", "LimiteAlunos", "FezCheckin", "PermiteCheckin",
        "PermiteCancelarCheckin", "DataHoraInicioCheckin", "DataHoraFimCheckin"
    ]
    static let priorityParticipantKeys: [String] = [
        "Id", "CodigoAgenda", "CodigoCliente", "CodigoContratoCliente", "CodigoOportunidade",
        "NomeParticipante", "Tipo", "Status", "Antecipacao", "Motivo", "PerfilPrivado",
        "Reagendamento", "UrlImagemParticipante"
    ]
    /// Colunas próprias no CSV de participantes (demais campos vão para `camposAdicionais`).
    private static let participantCSVCoreKeys: Set<String> = [
        "Id", "CodigoAgenda", "CodigoCliente", "CodigoContratoCliente", "NomeParticipante",
        "Tipo", "Status", "Motivo", "Reagendamento"
    ]
    private static let expectedContractKeys: [String] = ["Id", "Status", "Tipo", "Descricao", "Modalidades"]

    private static let periodFragments: [String] = [
        "data", "inicio", "fim", "vigencia", "validade", "periodo", "vencimento", "duracao"
    ]
    private static let sessionFragments: [String] = [
        "sessao", "sessoes", "credito", "saldo", "qtde", "quantidade", "aulas"
    ]
    private static let agreementFragments: [String] = [
        "convenio", "gympass", "wellhub", "totalpass", "parceiro", "agregador", "integracao"
    ]
    private static let productFragments: [String] = ["plano", "produto", "servico", "pacote", "mensal"]

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
    private var exportsURL: URL {
        directoryURL.appendingPathComponent("exports", isDirectory: true)
    }

    private init() {
        let fileManager = FileManager.default
        let base: URL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
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

        let contractsText: String = file.ownContracts == nil ? "nao-carregados" : "carregados"
        let autoExport: Bool = UserDefaults.standard.bool(forKey: "NextFitCheckInAuditExport")
        var lines: [String] = [Self.logPrefix + " ARMAZENAMENTO"]
        lines.append("diretorio=" + directoryURL.path)
        lines.append("capturasAgenda=\(file.agendaCaptures.count)")
        lines.append("contratosProprios=" + contractsText)
        lines.append("retencaoDias=\(Self.retentionDays)")
        lines.append("exportacaoAutomaticaPorArgumento=\(autoExport)")
        print(lines.joined(separator: "\n"))
        exportIfRequestedByLaunchArgument()
    }

    // MARK: Captura do detalhe da aula (`Agenda/{id}`)

    func recordAgendaDetail(data: Data, sessionClientId: Int?) {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = root["Content"] as? [String: Any],
              let agendaId = NextFitAuditSanitizer.int(content["Id"]) else {
            print(Self.logPrefix + " CAPTURA\nresultado=ignorada-formato-inesperado")
            return
        }
        let now = Date()

        var agendaFields: [String: NextFitAuditValue] = [:]
        for (key, value) in content where key != "Participantes" {
            if NextFitAuditSanitizer.isSensitive(key) {
                agendaFields[key] = NextFitAuditSanitizer.omitted(value)
            } else {
                NextFitAuditSanitizer.flatten(value, path: key, into: &agendaFields)
            }
        }

        var agendaStatusApi: String = "ausente"
        if let rawStatus = content["Status"], let statusValue = NextFitAuditSanitizer.scalar(rawStatus) {
            agendaStatusApi = statusValue.text
        }
        let startText: String? = content["DataInicial"] as? String
        let endText: String? = content["DataFinal"] as? String
        let temporal: String = Self.temporalSituation(start: startText, end: endText, now: now)
        let statusInt: Int? = NextFitAuditSanitizer.int(content["Status"])

        var phase: String = Self.phaseUnconfirmed
        var phaseConfirmed: Bool = false
        if let statusInt, Self.confirmedClosedAgendaStatusValues.contains(statusInt) {
            phase = Self.phaseAfter
            phaseConfirmed = true
        } else if temporal == "ANTES_DO_INICIO" || temporal == "EM_ANDAMENTO" {
            phase = Self.phaseBefore
        }
        let closure: String = phaseConfirmed ? "confirmado" : "nao-confirmado"

        let rawParticipants: [[String: Any]]? = content["Participantes"] as? [[String: Any]]
        var participants: [NextFitAuditParticipant] = []
        for raw in rawParticipants ?? [] {
            participants.append(makeParticipant(raw, sessionClientId: sessionClientId))
        }

        let fingerprint: String = Self.fingerprint(
            phase: phase,
            agendaFields: agendaFields,
            participants: participants
        )
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

    private func makeParticipant(_ raw: [String: Any], sessionClientId: Int?) -> NextFitAuditParticipant {
        var fields: [String: NextFitAuditValue] = [:]
        NextFitAuditSanitizer.flatten(raw, path: "", into: &fields)
        let participantId: Int? = NextFitAuditSanitizer.int(raw["Id"])
        let clientId: Int? = NextFitAuditSanitizer.int(raw["CodigoCliente"])
        let contractClientId: Int? = NextFitAuditSanitizer.int(raw["CodigoContratoCliente"])
        let status: Int? = NextFitAuditSanitizer.int(raw["Status"])
        let type: Int? = NextFitAuditSanitizer.int(raw["Tipo"])
        let linkage: NextFitAuditContractLinkage = contractLinkage(
            clientId: clientId,
            contractClientId: contractClientId,
            sessionClientId: sessionClientId
        )
        // Mesma regra do app (somente leitura): registra a categoria exibida no momento da captura
        let display = NextFitAgendaParticipantDisplay(
            id: participantId ?? 0,
            name: "",
            clientId: clientId,
            contractClientId: contractClientId,
            status: status,
            type: type
        )
        let resolution: NextFitParticipantCategoryResolution = NextFitParticipantCategoryResolver.resolve(
            participant: display,
            ownContractType: linkage.contract?.type
        )
        var name: String? = nil
        if let rawName = raw["NomeParticipante"] as? String {
            let trimmed: String = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
            name = trimmed.isEmpty ? nil : trimmed
        }
        return NextFitAuditParticipant(
            participantId: participantId,
            agendaCode: NextFitAuditSanitizer.int(raw["CodigoAgenda"]),
            clientId: clientId,
            contractClientId: contractClientId,
            status: status,
            type: type,
            name: name,
            fields: fields,
            contractData: linkage.description,
            ownContractId: linkage.contract?.id,
            appCategory: String(describing: resolution.category),
            appCategoryReason: resolution.reason
        )
    }

    // MARK: Captura dos contratos do próprio aluno (`Cliente/RecuperarDadosPrincipais`)

    func recordClientMainData(data: Data, sessionClientId: Int?) {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = root["Content"] as? [String: Any] else {
            print(Self.logPrefix + " CONTRATO_PROPRIO\nresultado=ignorado-formato-inesperado")
            return
        }
        guard let clientId = NextFitAuditSanitizer.int(content["CodigoCliente"]),
              let sessionClientId,
              clientId == sessionClientId else {
            print(Self.logPrefix + " CONTRATO_PROPRIO\nresultado=descartado-cliente-nao-confere-com-sessao")
            return
        }

        let rawContracts: [[String: Any]] = content["Contratos"] as? [[String: Any]] ?? []
        var contracts: [NextFitAuditContract] = []
        for raw in rawContracts {
            contracts.append(makeContract(raw))
        }

        var contractParts: [String] = []
        for contract in contracts {
            contractParts.append(Self.canonical(contract.fields))
        }
        contractParts.sort()
        let fingerprint: String = String(clientId) + "|" + contractParts.joined(separator: "#")
        if let current = file.ownContracts, current.fingerprint == fingerprint {
            return
        }

        let capture = NextFitAuditContractsCapture(
            capturedAt: Date(),
            clientId: clientId,
            contracts: contracts,
            fingerprint: fingerprint
        )
        file.ownContracts = capture
        persist()
        logContracts(capture, contractsKeyPresent: content["Contratos"] != nil)
        exportIfRequestedByLaunchArgument()
    }

    private func makeContract(_ raw: [String: Any]) -> NextFitAuditContract {
        var fields: [String: NextFitAuditValue] = [:]
        NextFitAuditSanitizer.flatten(raw, path: "", into: &fields)
        var modalities: [String] = []
        let rawModalities: [[String: Any]] = raw["Modalidades"] as? [[String: Any]] ?? []
        for modality in rawModalities {
            let idText: String = Self.rawText(modality["Id"])
            let modalityText: String = Self.rawText(modality["CodigoModalidade"])
            modalities.append("Id=\(idText);CodigoModalidade=\(modalityText)")
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

    // MARK: Comparação ANTES x APÓS

    func comparison(for agendaId: Int) -> NextFitAuditComparison {
        var captures: [NextFitAuditAgendaCapture] = file.agendaCaptures.filter { $0.agendaId == agendaId }
        captures.sort { $0.capturedAt < $1.capturedAt }

        let before: NextFitAuditAgendaCapture? = captures.first { $0.phase == Self.phaseBefore }
        let beforeDate: Date = before?.capturedAt ?? .distantPast
        var later: [NextFitAuditAgendaCapture] = []
        for capture in captures where capture.phase != Self.phaseBefore && capture.capturedAt > beforeDate {
            later.append(capture)
        }
        let lastConfirmed: NextFitAuditAgendaCapture? = later.last { $0.phase == Self.phaseAfter }
        let after: NextFitAuditAgendaCapture? = lastConfirmed ?? later.last

        guard let after else {
            let state: String = before == nil ? "sem-capturas" : "aguardando-captura-posterior"
            return NextFitAuditComparison(
                agendaId: agendaId, state: state, before: before, after: nil,
                agendaChangedFields: [], rows: []
            )
        }
        guard let before else {
            // Não inventa o estado anterior a partir do posterior
            var rows: [NextFitAuditComparisonRow] = []
            for participant in after.participants {
                rows.append(NextFitAuditComparisonRow(
                    situation: "sem-captura-anterior", correspondence: "n/a",
                    before: nil, after: participant, changedFields: []
                ))
            }
            return NextFitAuditComparison(
                agendaId: agendaId, state: "sem-captura-anterior", before: nil, after: after,
                agendaChangedFields: [], rows: rows
            )
        }

        let beforeIndex: NextFitAuditParticipantIndex = Self.index(before.participants)
        let afterIndex: NextFitAuditParticipantIndex = Self.index(after.participants)
        let ambiguousIds: Set<Int> = beforeIndex.duplicatedIds.union(afterIndex.duplicatedIds)
        var allIdSet: Set<Int> = Set(beforeIndex.unique.keys)
        allIdSet.formUnion(afterIndex.unique.keys)
        allIdSet.subtract(ambiguousIds)
        let allIds: [Int] = allIdSet.sorted()

        var rows: [NextFitAuditComparisonRow] = []
        for id in allIds {
            let old: NextFitAuditParticipant? = beforeIndex.unique[id]
            let new: NextFitAuditParticipant? = afterIndex.unique[id]
            if let old, let new {
                rows.append(Self.matchedRow(old: old, new: new, agendaId: agendaId))
            } else if let old {
                rows.append(NextFitAuditComparisonRow(
                    situation: "ausente-na-segunda", correspondence: "n/a",
                    before: old, after: nil, changedFields: []
                ))
            } else if let new {
                rows.append(NextFitAuditComparisonRow(
                    situation: "incluido-depois", correspondence: "n/a",
                    before: nil, after: new, changedFields: []
                ))
            }
        }
        for participant in beforeIndex.unreliable {
            rows.append(Self.unreliableRow(participant, isBefore: true))
        }
        for participant in afterIndex.unreliable {
            rows.append(Self.unreliableRow(participant, isBefore: false))
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

    private static func matchedRow(
        old: NextFitAuditParticipant,
        new: NextFitAuditParticipant,
        agendaId: Int
    ) -> NextFitAuditComparisonRow {
        var reasons: [String] = []
        let oldAgendaDiverges: Bool = old.agendaCode != nil && old.agendaCode != agendaId
        let newAgendaDiverges: Bool = new.agendaCode != nil && new.agendaCode != agendaId
        if oldAgendaDiverges || newAgendaDiverges {
            reasons.append("CodigoAgenda-divergente")
        }
        if old.clientId != new.clientId {
            let missingClient: Bool = old.clientId == nil || new.clientId == nil
            reasons.append(missingClient ? "CodigoCliente-ausente-em-uma-captura" : "CodigoCliente-divergente")
        }
        if let oldContract = old.contractClientId,
           let newContract = new.contractClientId,
           oldContract != newContract {
            reasons.append("CodigoContratoCliente-divergente")
        }
        let confirmed: Bool = reasons.isEmpty
        let situation: String = confirmed ? "presente-nas-duas" : "sem-correspondencia-confiavel"
        let correspondence: String = confirmed
            ? "confirmada"
            : "nao-confirmada(" + reasons.joined(separator: ",") + ")"
        return NextFitAuditComparisonRow(
            situation: situation,
            correspondence: correspondence,
            before: old,
            after: new,
            changedFields: changedKeys(old.fields, new.fields)
        )
    }

    private static func unreliableRow(
        _ participant: NextFitAuditParticipant,
        isBefore: Bool
    ) -> NextFitAuditComparisonRow {
        let correspondence: String = participant.participantId == nil
            ? "nao-confirmada(Id-ausente)"
            : "nao-confirmada(Id-duplicado)"
        return NextFitAuditComparisonRow(
            situation: "sem-correspondencia-confiavel",
            correspondence: correspondence,
            before: isBefore ? participant : nil,
            after: isBefore ? nil : participant,
            changedFields: []
        )
    }

    func printComparisons() {
        let agendaIds: [Int] = Set(file.agendaCaptures.map { $0.agendaId }).sorted()
        if agendaIds.isEmpty {
            print(Self.logPrefix + " COMPARACAO\nresultado=sem-capturas")
        }
        for agendaId in agendaIds {
            logComparison(comparison(for: agendaId))
        }
    }

    // MARK: Exportação Excel/CSV (ação explícita do desenvolvedor)

    /// Gera a planilha Excel (abas PARTICIPANTES e COMPARATIVO ANTES-APOS) e os CSVs equivalentes.
    /// Sempre inclui o nome completo original (`Participantes[].NomeParticipante`) para conferência
    /// com a academia. Arquivos ficam somente no contêiner privado do app DEBUG; nada é enviado.
    @discardableResult
    func exportCSV() -> [URL] {
        prepareDirectory(exportsURL)
        print(Self.logPrefix + " EXPORTACAO\nATENCAO=arquivos-contem-dados-pessoais(nomes-completos-dos-participantes)-uso-restrito-a-conferencia-com-a-academia")

        let participantRows: [[String]] = participantsTable()
        let comparisonRows: [[String]] = comparisonTable()

        let workbookURL: URL = exportsURL.appendingPathComponent("nextfit_auditoria.xml")
        let participantsURL: URL = exportsURL.appendingPathComponent("nextfit_participantes.csv")
        let comparisonURL: URL = exportsURL.appendingPathComponent("nextfit_comparativo.csv")

        let sheets: [(name: String, rows: [[String]])] = [
            (name: "PARTICIPANTES", rows: participantRows),
            (name: "COMPARATIVO ANTES-APOS", rows: comparisonRows)
        ]

        var written: [URL] = []
        if write(Self.workbook(sheets), to: workbookURL, withBOM: false) {
            written.append(workbookURL)
        }
        if write(Self.csv(participantRows), to: participantsURL, withBOM: true) {
            written.append(participantsURL)
        }
        if write(Self.csv(comparisonRows), to: comparisonURL, withBOM: true) {
            written.append(comparisonURL)
        }
        let paths: [String] = written.map { $0.path }
        var lines: [String] = [Self.logPrefix + " EXPORTACAO"]
        lines.append("nomesIncluidos=true")
        lines.append("linhasParticipantes=\(max(participantRows.count - 1, 0))")
        lines.append("linhasComparativo=\(max(comparisonRows.count - 1, 0))")
        lines.append("arquivos=\(paths)")
        print(lines.joined(separator: "\n"))
        return written
    }

    func reset() {
        file = NextFitAuditStoreFile()
        try? FileManager.default.removeItem(at: exportsURL)
        persist()
        print(Self.logPrefix + " LIMPEZA\nresultado=capturas-e-exportacoes-removidas")
    }

    // MARK: - Privados: vínculo com contrato próprio

    private func ownContract(
        clientId: Int?,
        contractClientId: Int?,
        sessionClientId: Int?
    ) -> NextFitAuditContract? {
        guard let own = file.ownContracts,
              let sessionClientId,
              own.clientId == sessionClientId,
              let contractClientId else {
            return nil
        }
        if let clientId, clientId != own.clientId {
            return nil
        }
        return own.contracts.first { $0.id == contractClientId }
    }

    private func contractLinkage(
        clientId: Int?,
        contractClientId: Int?,
        sessionClientId: Int?
    ) -> NextFitAuditContractLinkage {
        if let contract = ownContract(
            clientId: clientId,
            contractClientId: contractClientId,
            sessionClientId: sessionClientId
        ) {
            return NextFitAuditContractLinkage(description: "contrato-proprio", contract: contract)
        }
        guard let sessionClientId else {
            return NextFitAuditContractLinkage(description: "indeterminado-sem-cliente-da-sessao", contract: nil)
        }
        if let clientId, clientId == sessionClientId {
            let loaded: Bool = file.ownContracts?.clientId == sessionClientId
            let text: String = loaded ? "proprio-contrato-nao-localizado" : "proprio-contratos-ainda-nao-carregados"
            return NextFitAuditContractLinkage(description: text, contract: nil)
        }
        // Não há acesso autorizado a contratos de terceiros pela API do aluno
        return NextFitAuditContractLinkage(description: "nao-disponiveis-para-terceiros", contract: nil)
    }

    private static func confirmedCategory(for contract: NextFitAuditContract?) -> String {
        guard let type = contract?.type else { return "" }
        switch type {
        case 2, 3: return "WELLHUB"
        case 4, 5: return "TOTALPASS"
        default: return ""
        }
    }

    // MARK: - Privados: logs

    private func logCapture(_ capture: NextFitAuditAgendaCapture) {
        var lines: [String] = [Self.logPrefix + " CAPTURA"]
        lines.append("agendaId=\(capture.agendaId)")
        lines.append("capturadoEm=" + Self.timestamp(capture.capturedAt))
        lines.append("fase=" + capture.phase)
        lines.append("faseConfirmada=\(capture.phaseConfirmed)")
        lines.append("encerramento=" + capture.closure)
        lines.append("situacaoTemporalCalculadaPeloApp=" + capture.temporalSituation)
        lines.append("statusAula(Agenda.Status)=" + capture.agendaStatusApi)

        var missingAgenda: [String] = []
        for key in Self.priorityAgendaKeys {
            if let value = capture.agendaFields[key] {
                let valueText: String = Self.describe(value)
                lines.append("Agenda.\(key)=\(valueText)")
            } else {
                missingAgenda.append(key)
            }
        }
        lines.append("camposAgendaAusentesNaResposta=\(missingAgenda)")

        var extraAgenda: [String] = []
        for key in capture.agendaFields.keys.sorted() where !Self.priorityAgendaKeys.contains(key) {
            if let value = capture.agendaFields[key] {
                extraAgenda.append(key + "=" + value.text)
            }
        }
        lines.append("camposAgendaAdicionais=\(extraAgenda)")

        let participantsText: String = capture.participantsKeyPresent ? "presente" : "ausente"
        lines.append("participantesNaResposta=" + participantsText)
        lines.append("totalParticipantes=\(capture.participants.count)")

        var participantKeySet = Set<String>()
        var distribution: [String: Int] = [:]
        for participant in capture.participants {
            participantKeySet.formUnion(participant.fields.keys)
            let statusKey: String = Self.optionalText(participant.status, absent: "nil")
            distribution[statusKey, default: 0] += 1
        }
        let participantKeys: [String] = participantKeySet.sorted()
        lines.append("camposParticipantesEncontrados=\(participantKeys)")
        var distributionText: [String] = []
        for key in distribution.keys.sorted() {
            distributionText.append(key + ":" + String(distribution[key] ?? 0))
        }
        lines.append("distribuicaoStatusParticipantes=\(distributionText)")
        print(lines.joined(separator: "\n"))

        for participant in capture.participants {
            logParticipant(participant, agendaId: capture.agendaId)
        }
    }

    private func logParticipant(_ participant: NextFitAuditParticipant, agendaId: Int) {
        let fields: [String: NextFitAuditValue] = participant.fields
        let typeDoc: String = Self.documented(
            participant.type, Self.participantTypeDescriptions, "EnumTipoAgendaParticipante"
        )
        let statusDoc: String = Self.documented(
            participant.status, Self.participantStatusDescriptions, "EnumStatusAgendaParticipante"
        )
        let imageText: String = fields["UrlImagemParticipante"]?.text ?? "ausente"
        let nameText: String = fields["NomeParticipante"] == nil ? "ausente" : "<omitido-no-log>"

        var lines: [String] = [Self.logPrefix + " PARTICIPANTE"]
        lines.append("agendaId=\(agendaId)")
        lines.append("participanteId=" + Self.show(fields, "Id"))
        lines.append("codigoAgenda=" + Self.show(fields, "CodigoAgenda"))
        lines.append("codigoCliente=" + Self.show(fields, "CodigoCliente"))
        lines.append("codigoContratoCliente=" + Self.show(fields, "CodigoContratoCliente"))
        lines.append("codigoOportunidade=" + Self.show(fields, "CodigoOportunidade"))
        lines.append("tipoParticipante=" + Self.show(fields, "Tipo") + typeDoc)
        lines.append("statusParticipante=" + Self.show(fields, "Status") + statusDoc)
        lines.append("antecipacao=" + Self.show(fields, "Antecipacao"))
        lines.append("motivo=" + Self.show(fields, "Motivo"))
        lines.append("perfilPrivado=" + Self.show(fields, "PerfilPrivado"))
        lines.append("reagendamento=" + Self.show(fields, "Reagendamento"))
        lines.append("urlImagemParticipante=" + imageText)
        lines.append("nomeParticipante=" + nameText)

        var extra: [String] = []
        for key in fields.keys.sorted() where !Self.priorityParticipantKeys.contains(key) {
            extra.append(key + "=" + Self.show(fields, key))
        }
        lines.append("camposAdicionais=\(extra)")
        lines.append("dadosContrato=" + participant.contractData)
        if let contractId = participant.ownContractId {
            lines.append("contratoProprioId=\(contractId)")
        }
        lines.append("categoriaApp=\(participant.appCategory) motivoCategoriaApp=\(participant.appCategoryReason)")
        print(lines.joined(separator: "\n"))
    }

    private func logContracts(_ capture: NextFitAuditContractsCapture, contractsKeyPresent: Bool) {
        if capture.contracts.isEmpty {
            let listText: String = contractsKeyPresent ? "lista-vazia" : "campo-Contratos-ausente"
            var emptyLines: [String] = [Self.logPrefix + " CONTRATO_PROPRIO"]
            emptyLines.append("codigoCliente=\(capture.clientId)")
            emptyLines.append("contratos=" + listText)
            print(emptyLines.joined(separator: "\n"))
            return
        }
        for contract in capture.contracts {
            logContract(contract, capture: capture)
        }
    }

    private func logContract(_ contract: NextFitAuditContract, capture: NextFitAuditContractsCapture) {
        let fields: [String: NextFitAuditValue] = contract.fields

        var topLevelKeySet = Set<String>()
        for key in fields.keys {
            topLevelKeySet.insert(Self.topLevelKey(key))
        }
        var missingOrNull: [String] = []
        for key in Self.expectedContractKeys where fields[key] == nil || fields[key]?.kind == "nulo" {
            missingOrNull.append(key)
        }
        var additional: [String] = []
        for key in fields.keys.sorted() where !Self.expectedContractKeys.contains(Self.topLevelKey(key)) {
            if let value = fields[key] {
                additional.append(key + "=" + Self.describe(value))
            }
        }
        var nullKeys: [String] = []
        for key in fields.keys.sorted() where fields[key]?.kind == "nulo" {
            nullKeys.append(key)
        }
        var kinds: [String] = []
        for key in topLevelKeySet.sorted() {
            if let value = fields[key] {
                kinds.append(key + ":" + value.kind)
            }
        }

        let typeText: String = fields["Tipo"]?.text ?? "ausente"
        let typeDoc: String = Self.documented(contract.type, Self.contractTypeDescriptions, "EnumTipoContratoBase")
        let statusText: String = fields["Status"]?.text ?? "ausente"
        let statusDoc: String = Self.documented(contract.status, Self.contractStatusDescriptions, "Contratos[].Status")
        let descriptionFallback: String = fields["Descricao"] == nil ? "ausente" : "null"
        let descriptionText: String = contract.descriptionText ?? descriptionFallback
        let periodKeys: [String] = Self.candidateKeys(fields, Self.periodFragments)
        let sessionKeys: [String] = Self.candidateKeys(fields, Self.sessionFragments)
        let agreementKeys: [String] = Self.candidateKeys(fields, Self.agreementFragments)
        let productKeys: [String] = Self.candidateKeys(fields, Self.productFragments)
        let confirmed: String = Self.confirmedCategory(for: contract)
        let confirmedText: String = confirmed.isEmpty ? "sem-evidencia" : confirmed

        var lines: [String] = [Self.logPrefix + " CONTRATO_PROPRIO"]
        lines.append("codigoCliente=\(capture.clientId)")
        lines.append("capturadoEm=" + Self.timestamp(capture.capturedAt))
        lines.append("contratoId=" + Self.optionalText(contract.id, absent: "ausente"))
        lines.append("tipoContrato=" + typeText + typeDoc)
        lines.append("statusContrato=" + statusText + statusDoc)
        lines.append("descricao=" + descriptionText)
        lines.append("modalidades=\(contract.modalities)")
        lines.append("camposAdicionais=\(additional)")
        lines.append("camposEsperadosAusentesOuNulos=\(missingOrNull)")
        lines.append("camposNulos=\(nullKeys)")
        lines.append("tiposDosValores(numero=codigo,texto=descricao)=\(kinds)")
        lines.append("chavesCandidatasPeriodo=\(periodKeys)")
        lines.append("chavesCandidatasSessoesCreditos=\(sessionKeys)")
        lines.append("chavesCandidatasConvenio=\(agreementKeys)")
        lines.append("chavesCandidatasProduto=\(productKeys)")
        lines.append("categoriaConfirmadaApi=" + confirmedText)
        print(lines.joined(separator: "\n"))
    }

    private func logComparison(_ comparison: NextFitAuditComparison) {
        var header: [String] = [Self.logPrefix + " COMPARACAO_RESUMO"]
        header.append("agendaId=\(comparison.agendaId)")
        header.append("comparacao=" + comparison.state)
        if let before = comparison.before {
            let beforeTime: String = Self.timestamp(before.capturedAt)
            header.append("capturaAntes=\(beforeTime) faseAntes=\(before.phase) statusAulaAntes=\(before.agendaStatusApi)")
        }
        if let after = comparison.after {
            let afterTime: String = Self.timestamp(after.capturedAt)
            header.append("capturaApos=\(afterTime) faseApos=\(after.phase) statusAulaDepois=\(after.agendaStatusApi)")
            header.append("encerramento=\(after.closure)")
        }
        guard comparison.state == "ok" else {
            print(header.joined(separator: "\n"))
            return
        }
        var counts: [String: Int] = [:]
        for row in comparison.rows {
            counts[row.situation, default: 0] += 1
        }
        header.append("alteracoesAula=\(comparison.agendaChangedFields)")
        header.append("presentesNasDuas=\(counts["presente-nas-duas"] ?? 0)")
        header.append("incluidosDepois=\(counts["incluido-depois"] ?? 0)")
        header.append("ausentesNaSegunda=\(counts["ausente-na-segunda"] ?? 0)")
        header.append("semCorrespondenciaConfiavel=\(counts["sem-correspondencia-confiavel"] ?? 0)")
        header.append("observacao=ausencia-na-segunda-captura-nao-comprova-cancelamento-falta-ou-exclusao")
        print(header.joined(separator: "\n"))

        for row in comparison.rows {
            logComparisonRow(row, agendaId: comparison.agendaId)
        }
    }

    private func logComparisonRow(_ row: NextFitAuditComparisonRow, agendaId: Int) {
        let reference: NextFitAuditParticipant? = row.after ?? row.before
        let categoryBefore: String = row.before?.appCategory ?? "-"
        let categoryAfter: String = row.after?.appCategory ?? "-"

        var lines: [String] = [Self.logPrefix + " COMPARACAO"]
        lines.append("agendaId=\(agendaId)")
        lines.append("participanteId=" + Self.optionalText(reference?.participantId, absent: "ausente"))
        lines.append("codigoCliente=" + Self.optionalText(reference?.clientId, absent: "ausente"))
        lines.append("codigoContratoCliente=" + Self.optionalText(reference?.contractClientId, absent: "ausente"))
        lines.append("situacao=" + row.situation)
        lines.append("correspondencia=" + row.correspondence)
        lines.append("statusAntes=" + Self.fieldText(row.before, "Status"))
        lines.append("statusDepois=" + Self.fieldText(row.after, "Status"))
        lines.append("tipoAntes=" + Self.fieldText(row.before, "Tipo"))
        lines.append("tipoDepois=" + Self.fieldText(row.after, "Tipo"))
        lines.append("codigoContratoClienteAntes=" + Self.fieldText(row.before, "CodigoContratoCliente"))
        lines.append("codigoContratoClienteDepois=" + Self.fieldText(row.after, "CodigoContratoCliente"))
        let reasonBefore: String = Self.fieldText(row.before, "Motivo")
        let reasonAfter: String = Self.fieldText(row.after, "Motivo")
        let rescheduleBefore: String = Self.fieldText(row.before, "Reagendamento")
        let rescheduleAfter: String = Self.fieldText(row.after, "Reagendamento")
        let categoryChanged: String = Self.categoryChanged(row)
        lines.append("motivoAntes=\(reasonBefore) motivoDepois=\(reasonAfter)")
        lines.append("reagendamentoAntes=\(rescheduleBefore) reagendamentoDepois=\(rescheduleAfter)")
        lines.append("alteracoes=\(row.changedFields)")
        lines.append("categoriaAppAntes=\(categoryBefore) categoriaAppDepois=\(categoryAfter) categoriaAppMudou=\(categoryChanged)")
        print(lines.joined(separator: "\n"))
    }

    // MARK: - Privados: tabelas da planilha

    private func participantsTable() -> [[String]] {
        let header: [String] = [
            "Data da Aula", "Hora Inicial da Aula", "ID da Agenda", "ID do Participante",
            "Nome do Participante", "Código do Cliente", "Código do Contrato",
            "Tipo da Participação", "Status da Participação", "Fase da Captura", "Fase Confirmada",
            "Encerramento", "Situação Temporal (App)", "Capturado Em", "Status da Aula",
            "Motivo", "Reagendamento", "Dados do Contrato", "Categoria App", "Campos Adicionais"
        ]
        var rows: [[String]] = [header]

        var captures: [NextFitAuditAgendaCapture] = file.agendaCaptures
        captures.sort { lhs, rhs in
            if lhs.agendaId != rhs.agendaId { return lhs.agendaId < rhs.agendaId }
            return lhs.capturedAt < rhs.capturedAt
        }
        for capture in captures {
            let start: (date: String, time: String) = Self.splitAgendaStart(capture.agendaStartText)
            for participant in capture.participants {
                rows.append(participantRow(participant, capture: capture, start: start))
            }
        }
        return rows
    }

    private func participantRow(
        _ participant: NextFitAuditParticipant,
        capture: NextFitAuditAgendaCapture,
        start: (date: String, time: String)
    ) -> [String] {
        var extras: [String] = []
        for key in participant.fields.keys.sorted() where !Self.participantCSVCoreKeys.contains(key) {
            if let value = participant.fields[key] {
                extras.append(key + "=" + value.text)
            }
        }
        var row: [String] = [start.date, start.time, String(capture.agendaId)]
        row.append(Self.optionalText(participant.participantId))
        // Nome completo original da API; vazio quando ausente (nunca inventado)
        row.append(participant.name ?? "")
        row.append(Self.optionalText(participant.clientId))
        row.append(Self.optionalText(participant.contractClientId))
        row.append(Self.fieldText(participant, "Tipo", absent: ""))
        row.append(Self.fieldText(participant, "Status", absent: ""))
        row.append(capture.phase)
        row.append(capture.phaseConfirmed ? "true" : "false")
        row.append(capture.closure)
        row.append(capture.temporalSituation)
        row.append(Self.timestamp(capture.capturedAt))
        row.append(capture.agendaStatusApi)
        row.append(Self.fieldText(participant, "Motivo", absent: ""))
        row.append(Self.fieldText(participant, "Reagendamento", absent: ""))
        row.append(participant.contractData)
        row.append(participant.appCategory)
        row.append(extras.joined(separator: " | "))
        return row
    }

    private func comparisonTable() -> [[String]] {
        let header: [String] = [
            "ID da Agenda", "Data da Aula", "Hora Inicial da Aula", "ID do Participante",
            "Nome do Participante", "Código do Cliente", "Código do Contrato", "Comparação",
            "Situação", "Correspondência", "Fase ANTES", "Capturado ANTES", "Fase APÓS",
            "Capturado APÓS", "Encerramento", "Status da Aula ANTES", "Status da Aula APÓS",
            "Status ANTES", "Status APÓS", "Tipo ANTES", "Tipo APÓS", "Campos Alterados",
            "Alterações da Aula", "Categoria App ANTES", "Categoria App APÓS", "Categoria App Mudou",
            "Contrato Próprio Recuperável", "Categoria Confirmada pela API",
            "Categoria para Validação pela Academia (MENSALISTA|PACOTE|WELLHUB|TOTALPASS|OUTRO)"
        ]
        var rows: [[String]] = [header]

        let agendaIds: [Int] = Set(file.agendaCaptures.map { $0.agendaId }).sorted()
        for agendaId in agendaIds {
            let result: NextFitAuditComparison = comparison(for: agendaId)
            let reference: NextFitAuditAgendaCapture? = result.after ?? result.before
            let start: (date: String, time: String) = Self.splitAgendaStart(reference?.agendaStartText)

            var comparisonRows: [NextFitAuditComparisonRow] = result.rows
            if result.state == "aguardando-captura-posterior" {
                comparisonRows = []
                for participant in result.before?.participants ?? [] {
                    comparisonRows.append(NextFitAuditComparisonRow(
                        situation: "aguardando-captura-posterior", correspondence: "n/a",
                        before: participant, after: nil, changedFields: []
                    ))
                }
            }
            for row in comparisonRows {
                rows.append(comparisonLine(row, result: result, start: start))
            }
        }
        return rows
    }

    private func comparisonLine(
        _ row: NextFitAuditComparisonRow,
        result: NextFitAuditComparison,
        start: (date: String, time: String)
    ) -> [String] {
        let participant: NextFitAuditParticipant? = row.after ?? row.before
        // Nome apenas para identificação visual; a correlação já foi feita por identificadores estáveis
        let name: String = row.after?.name ?? row.before?.name ?? ""
        let beforeCapture: NextFitAuditAgendaCapture? = row.before == nil ? nil : result.before
        let afterCapture: NextFitAuditAgendaCapture? = row.after == nil ? nil : result.after
        let sessionCapture: NextFitAuditAgendaCapture? = afterCapture ?? beforeCapture
        let linkage: NextFitAuditContractLinkage = contractLinkage(
            clientId: participant?.clientId,
            contractClientId: participant?.contractClientId,
            sessionClientId: sessionCapture?.sessionClientId
        )
        var beforeTime: String = ""
        if let beforeCapture {
            beforeTime = Self.timestamp(beforeCapture.capturedAt)
        }
        var afterTime: String = ""
        if let afterCapture {
            afterTime = Self.timestamp(afterCapture.capturedAt)
        }
        let recoverable: String = linkage.contract == nil ? linkage.description : "sim"

        var line: [String] = [String(result.agendaId), start.date, start.time]
        line.append(Self.optionalText(participant?.participantId))
        line.append(name)
        line.append(Self.optionalText(participant?.clientId))
        line.append(Self.optionalText(participant?.contractClientId))
        line.append(result.state)
        line.append(row.situation)
        line.append(row.correspondence)
        line.append(beforeCapture?.phase ?? "")
        line.append(beforeTime)
        line.append(afterCapture?.phase ?? "")
        line.append(afterTime)
        line.append(result.after?.closure ?? "nao-confirmado")
        line.append(beforeCapture?.agendaStatusApi ?? "")
        line.append(afterCapture?.agendaStatusApi ?? "")
        line.append(Self.fieldText(row.before, "Status", absent: ""))
        line.append(Self.fieldText(row.after, "Status", absent: ""))
        line.append(Self.fieldText(row.before, "Tipo", absent: ""))
        line.append(Self.fieldText(row.after, "Tipo", absent: ""))
        line.append(row.changedFields.joined(separator: " | "))
        line.append(result.agendaChangedFields.joined(separator: " | "))
        line.append(row.before?.appCategory ?? "")
        line.append(row.after?.appCategory ?? "")
        line.append(Self.categoryChanged(row))
        line.append(recoverable)
        line.append(Self.confirmedCategory(for: linkage.contract))
        line.append("") // preenchimento manual pela academia; nunca inferido
        return line
    }

    private func write(_ text: String, to url: URL, withBOM: Bool) -> Bool {
        do {
            // BOM UTF-8 nos CSVs para acentuação correta no Excel
            let content: String = withBOM ? "\u{FEFF}" + text : text
            try Data(content.utf8).write(
                to: url,
                options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
            )
            return true
        } catch {
            print(Self.logPrefix + " EXPORTACAO\nerro=" + error.localizedDescription)
            return false
        }
    }

    private func exportIfRequestedByLaunchArgument() {
        guard UserDefaults.standard.bool(forKey: "NextFitCheckInAuditExport") else { return }
        exportCSV()
    }

    // MARK: - Privados: persistência

    private func prepareDirectory(_ url: URL) {
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        var resourceURL: URL = url
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
            print(Self.logPrefix + " ARMAZENAMENTO\nresultado=arquivo-invalido-reiniciado")
        }
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(file) else { return }
        do {
            try data.write(to: storeURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        } catch {
            print(Self.logPrefix + " ARMAZENAMENTO\nerro=" + error.localizedDescription)
        }
    }

    private func prune() {
        let retentionSeconds: TimeInterval = TimeInterval(Self.retentionDays) * 86_400
        let cutoff: Date = Date().addingTimeInterval(-retentionSeconds)
        var kept: [NextFitAuditAgendaCapture] = file.agendaCaptures.filter { $0.capturedAt >= cutoff }
        kept.sort { $0.capturedAt < $1.capturedAt }
        if kept.count > Self.maxAgendaCaptures {
            kept = Array(kept.suffix(Self.maxAgendaCaptures))
        }
        file.agendaCaptures = kept
        if let own = file.ownContracts, own.capturedAt < cutoff {
            file.ownContracts = nil
        }
    }

    // MARK: - Privados: utilitários

    private static func index(_ participants: [NextFitAuditParticipant]) -> NextFitAuditParticipantIndex {
        var groups: [Int: [NextFitAuditParticipant]] = [:]
        var unreliable: [NextFitAuditParticipant] = []
        for participant in participants {
            if let id = participant.participantId {
                groups[id, default: []].append(participant)
            } else {
                unreliable.append(participant)
            }
        }
        var unique: [Int: NextFitAuditParticipant] = [:]
        var duplicatedIds = Set<Int>()
        for (id, group) in groups {
            if group.count == 1, let single = group.first {
                unique[id] = single
            } else {
                duplicatedIds.insert(id)
                unreliable.append(contentsOf: group)
            }
        }
        return NextFitAuditParticipantIndex(unique: unique, duplicatedIds: duplicatedIds, unreliable: unreliable)
    }

    private static func changedKeys(
        _ lhs: [String: NextFitAuditValue],
        _ rhs: [String: NextFitAuditValue]
    ) -> [String] {
        var keys = Set<String>(lhs.keys)
        keys.formUnion(rhs.keys)
        var changed: [String] = []
        for key in keys where lhs[key] != rhs[key] {
            changed.append(key)
        }
        return changed.sorted()
    }

    private static func optionalText(_ value: Int?, absent: String = "") -> String {
        guard let value else { return absent }
        return String(value)
    }

    private static func describe(_ value: NextFitAuditValue) -> String {
        value.text + " (" + value.kind + ")"
    }

    private static func show(_ fields: [String: NextFitAuditValue], _ key: String) -> String {
        guard let value = fields[key] else { return "ausente" }
        return describe(value)
    }

    /// Primeiro segmento do caminho achatado (`Modalidades[0].Id` -> `Modalidades`).
    private static func topLevelKey(_ path: String) -> String {
        let firstSegment: String = path.split(separator: ".").first.map { String($0) } ?? path
        return firstSegment.components(separatedBy: "[").first ?? firstSegment
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
        guard let participant else {
            return absent.isEmpty ? "" : "-"
        }
        return participant.fields[key]?.text ?? absent
    }

    private static func documented(_ value: Int?, _ table: [Int: String], _ enumName: String) -> String {
        guard let value, let description = table[value] else { return "" }
        return " [documentado \(enumName): \(description)]"
    }

    private static func candidateKeys(_ fields: [String: NextFitAuditValue], _ fragments: [String]) -> [String] {
        var result: [String] = []
        for key in fields.keys.sorted() {
            let lastSegment: String = key.split(separator: ".").last.map { String($0) } ?? key
            let lower: String = lastSegment.lowercased()
            for fragment in fragments where lower.contains(fragment) {
                result.append(key)
                break
            }
        }
        return result
    }

    private static func rawText(_ value: Any?) -> String {
        guard let value else { return "ausente" }
        return NextFitAuditSanitizer.scalar(value)?.text ?? "ausente"
    }

    private static func canonical(_ fields: [String: NextFitAuditValue]) -> String {
        var parts: [String] = []
        for key in fields.keys.sorted() {
            if let value = fields[key] {
                parts.append("\(key)=\(value.kind):\(value.text)")
            }
        }
        return parts.joined(separator: "&")
    }

    /// Exclui horário da coleta, vínculo contratual e categoria do app (derivados localmente).
    private static func fingerprint(
        phase: String,
        agendaFields: [String: NextFitAuditValue],
        participants: [NextFitAuditParticipant]
    ) -> String {
        var participantParts: [String] = []
        for participant in participants {
            participantParts.append(canonical(participant.fields))
        }
        participantParts.sort()
        let agendaPart: String = canonical(agendaFields)
        let participantPart: String = participantParts.joined(separator: "#")
        return "\(phase)|\(agendaPart)|\(participantPart)"
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

    private static func splitAgendaStart(_ value: String?) -> (date: String, time: String) {
        guard let value else { return (date: "", time: "") }
        let parts: [String] = value.split(separator: " ", maxSplits: 1).map { String($0) }
        let datePart: String = parts.first ?? ""
        let timePart: String = parts.count > 1 ? parts[1] : ""
        return (date: datePart, time: timePart)
    }

    private static func timestamp(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = .current
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    private static func csvCell(_ cell: String) -> String {
        let specialCharacters: Set<Character> = [";", "\"", "\n", "\r"]
        guard cell.contains(where: { specialCharacters.contains($0) }) else { return cell }
        let escaped: String = cell.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    /// Escapa texto para XML preservando acentos e caracteres especiais (arquivo em UTF-8).
    private static func xmlEscape(_ text: String) -> String {
        var escaped: String = text.replacingOccurrences(of: "&", with: "&amp;")
        escaped = escaped.replacingOccurrences(of: "<", with: "&lt;")
        escaped = escaped.replacingOccurrences(of: ">", with: "&gt;")
        escaped = escaped.replacingOccurrences(of: "\"", with: "&quot;")
        escaped = escaped.replacingOccurrences(of: "\r\n", with: "&#10;")
        escaped = escaped.replacingOccurrences(of: "\n", with: "&#10;")
        return escaped
    }

    /// Planilha Excel (XML Spreadsheet 2003, UTF-8) com uma aba por tabela. Todas as células são
    /// texto, preservando identificadores e nomes exatamente como recebidos.
    private static func workbook(_ sheets: [(name: String, rows: [[String]])]) -> String {
        var xml: [String] = []
        xml.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
        xml.append("<?mso-application progid=\"Excel.Sheet\"?>")
        xml.append("<Workbook xmlns=\"urn:schemas-microsoft-com:office:spreadsheet\" xmlns:ss=\"urn:schemas-microsoft-com:office:spreadsheet\">")
        xml.append("<Styles><Style ss:ID=\"header\"><Font ss:Bold=\"1\"/></Style></Styles>")
        for sheet in sheets {
            let sheetName: String = xmlEscape(sheet.name)
            xml.append("<Worksheet ss:Name=\"\(sheetName)\"><Table>")
            for (index, row) in sheet.rows.enumerated() {
                let style: String = index == 0 ? " ss:StyleID=\"header\"" : ""
                var cells: [String] = []
                for cell in row {
                    let value: String = xmlEscape(cell)
                    cells.append("<Cell\(style)><Data ss:Type=\"String\">\(value)</Data></Cell>")
                }
                xml.append("<Row>" + cells.joined() + "</Row>")
            }
            xml.append("</Table></Worksheet>")
        }
        xml.append("</Workbook>")
        return xml.joined(separator: "\n")
    }

    private static func csv(_ rows: [[String]]) -> String {
        var lines: [String] = []
        for row in rows {
            var cells: [String] = []
            for cell in row {
                cells.append(csvCell(cell))
            }
            lines.append(cells.joined(separator: ";"))
        }
        return lines.joined(separator: "\r\n") + "\r\n"
    }
}
#endif

