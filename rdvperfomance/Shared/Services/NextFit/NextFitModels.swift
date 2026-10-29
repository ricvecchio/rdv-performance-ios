import Foundation

struct NextFitWodActivityDisplay: Equatable, Identifiable {
    let title: String
    let description: String
    let order: Int

    var id: String { "\(order)-\(title)" }
}

struct NextFitWodDisplay: Equatable, Identifiable {
    let modalityId: Int
    let modalityName: String
    let activities: [NextFitWodActivityDisplay]

    var id: Int { modalityId }
}

struct NextFitUpcomingWodDisplay: Equatable, Identifiable {
    let id: Int
    let date: Date
    let dataExec: String
    let title: String
    let modalityId: Int
    let modalityName: String
}

struct NextFitAgendaDisplay: Equatable, Identifiable {
    let id: Int
    let statusAgendaParticipante: Int?
    let startDate: Date
    let endDate: Date
    let startTime: String
    let endTime: String
    let enrolledStudents: Int
    let studentLimit: Int
    let modalityName: String
    let instructorName: String
    let locationName: String
    let canSchedule: Bool
    let canCancelCheckIn: Bool
    let hasCheckIn: Bool

    func scheduleText(locale: Locale) -> String {
        let format = AppLocalization.string("common.time_range", locale: locale)
        return String(
            format: format,
            locale: locale,
            arguments: [startTime, endTime]
        )
    }
    var capacityText: String { String(format: "%02d/%02d", enrolledStudents, studentLimit) }
}

struct NextFitAgendaParticipantDisplay: Equatable, Identifiable {
    let id: Int
    let name: String
    let clientId: Int?
    let contractClientId: Int?
    /// `Participantes[].Status` = EnumStatusAgendaParticipante (1 Reservado, 2 Presente, 3 Falta,
    /// 4 FaltaJustificada, 5 Bloqueado, 6 Suspenso, 7 Cancelado, 8 Desistente). Situação na aula:
    /// NÃO representa categoria comercial e não é usado para classificá-la.
    let status: Int?
    /// `Participantes[].Tipo` = EnumTipoAgendaParticipante (1 Cliente, 2 ContratoCliente,
    /// 3 Oportunidade, 4 ClienteServico). Forma de vínculo com a aula, não categoria comercial.
    let type: Int?
}

/// Categoria comercial do participante usada exclusivamente para o ícone da lista de participantes.
/// `rawValue` é persistido localmente (`NextFitParticipantCategoryStore`); não renomear os casos.
enum NextFitParticipantCategory: String, Codable, Equatable {
    case monthly
    case package
    case external
    /// VIP gratuito (somente por classificação confirmada). Usa o ícone neutro existente até que
    /// exista representação visual aprovada.
    case vip
    case unknown

    /// SF Symbol já aprovado para cada categoria.
    var symbolName: String {
        switch self {
        case .monthly: return "person.text.rectangle.fill"
        case .package: return "ticket.fill"
        case .external: return "globe"
        case .vip, .unknown: return "questionmark.circle"
        }
    }
}

struct NextFitParticipantCategoryResolution: Equatable {
    let category: NextFitParticipantCategory
    let reason: String
}

/// Resolve a categoria visual do participante, nesta ordem de prioridade:
/// 1. Classificação comercial confirmada e persistida (`CodigoCliente` + `CodigoContratoCliente`).
/// 2. Contrato do próprio aluno autenticado com tipo de agregador (evidência da API).
/// 3. Inferência de agregador persistida para a MESMA participação (`CodigoAgenda` + `Participantes[].Id`).
/// 4. Heurística visual `inferredExternalFromReservation` (Tipo 1 + Status 5 + sem contrato) na consulta
///    atual. Não é confirmação comercial.
/// 5. `Tipo == 2` com contrato preenchido: fallback VISUAL azul (`.monthly`) para vínculo contratual ainda
///    não classificado. Não afirma mensalidade e nunca é persistido.
/// 6. Desconhecido.
/// `Participantes[].Status`/`Tipo` só são usados nas regras visuais 4 e 5.
///
/// Semântica: Swagger oficial "API Pública Next Fit" (integracao.nextfit.com.br/swagger/v1).
/// EnumTipoContratoBase: 1 = Padrao; 2 = Gympass; 3 = GympassBooking; 4 = TotalPass; 5 = TotalPassBooking.
/// `Contratos[].Tipo = 1` (Padrao) abrange mensalidades E pacotes, portanto não comprova mensalidade.
enum NextFitParticipantCategoryResolver {
    static let externalContractTypes: Set<Int> = [2, 3, 4, 5]

    static let inferredExternalReason = "inferredExternalFromReservation"
    static let persistedInferredExternalReason = "inferredExternalFromReservation-persistida"
    static let confirmedReason = "classificacao-confirmada"
    static let ownAggregatorContractReason = "contrato-proprio-agregador"
    static let visualFallbackReason = "contrato-sem-classificacao-fallback-visual"
    /// Prefixo do motivo quando a categoria vem da fotografia visual persistida da participação.
    static let persistedVisualReasonPrefix = "categoria-visual-persistida"

    /// Força da evidência que originou a categoria (usada somente para decidir se a fotografia visual
    /// persistida pode ser atualizada). 0 = não persistível (desconhecido / derivado da própria fotografia).
    static func evidenceRank(reason: String) -> Int {
        switch reason {
        case confirmedReason: return 4
        case ownAggregatorContractReason: return 3
        case inferredExternalReason, persistedInferredExternalReason: return 2
        case visualFallbackReason: return 1
        default: return 0
        }
    }

    /// Combinação observada para participantes de agregador antes da consolidação da aula:
    /// `Tipo == 1 && Status == 5 && CodigoContratoCliente == nil`. Heurística visual, não comercial.
    static func matchesReservationAggregatorPattern(_ participant: NextFitAgendaParticipantDisplay) -> Bool {
        participant.type == 1 && participant.status == 5 && participant.contractClientId == nil
    }

    /// - Parameters:
    ///   - confirmedCategory: categoria confirmada e persistida para o cliente/contrato do participante.
    ///   - ownContractType: `Contratos[].Tipo` do contrato do próprio aluno autenticado vinculado
    ///     a este participante por `CodigoContratoCliente`; `nil` para todos os demais participantes.
    ///   - hasPersistedInference: a mesma participação (`CodigoAgenda` + `Participantes[].Id`) já foi
    ///     observada com o padrão de agregador.
    ///   - persistedVisualCategory: categoria visual persistida para a MESMA participação, informada
    ///     somente quando a aula já começou/encerrou (dados operacionais podem ter sido atualizados).
    ///     `nil` para aulas futuras, preservando integralmente as regras atuais.
    ///   - persistedVisualOrigin: motivo/origem com que a categoria persistida foi registrada.
    static func resolve(
        participant: NextFitAgendaParticipantDisplay,
        confirmedCategory: NextFitParticipantCategory?,
        ownContractType: Int?,
        hasPersistedInference: Bool,
        persistedVisualCategory: NextFitParticipantCategory? = nil,
        persistedVisualOrigin: String? = nil
    ) -> NextFitParticipantCategoryResolution {
        if let confirmedCategory, confirmedCategory != .unknown {
            return NextFitParticipantCategoryResolution(category: confirmedCategory, reason: confirmedReason)
        }
        // Fotografia visual persistida (evidência forte): não é substituída por `Tipo`/`Status` atualizados
        let persistedVisual: NextFitParticipantCategoryResolution?
        if let persistedVisualCategory, persistedVisualCategory != .unknown {
            persistedVisual = NextFitParticipantCategoryResolution(
                category: persistedVisualCategory,
                reason: "\(persistedVisualReasonPrefix):\(persistedVisualOrigin ?? "")"
            )
        } else {
            persistedVisual = nil
        }
        let persistedVisualIsFallback = persistedVisualOrigin.map { evidenceRank(reason: $0) <= 1 } ?? true
        if let persistedVisual, !persistedVisualIsFallback {
            return persistedVisual
        }
        if let ownContractType, externalContractTypes.contains(ownContractType) {
            return NextFitParticipantCategoryResolution(category: .external, reason: ownAggregatorContractReason)
        }
        if hasPersistedInference {
            return NextFitParticipantCategoryResolution(category: .external, reason: persistedInferredExternalReason)
        }
        // Fotografia originada de fallback visual: preserva o ícone já apresentado, abaixo das evidências reais
        if let persistedVisual {
            return persistedVisual
        }
        if matchesReservationAggregatorPattern(participant) {
            return NextFitParticipantCategoryResolution(category: .external, reason: inferredExternalReason)
        }
        if participant.type == 2, participant.contractClientId != nil {
            // Fallback VISUAL padrão para vínculo contratual ainda não classificado (ícone azul).
            // Não afirma mensalidade e nunca é persistido como classificação confirmada.
            return NextFitParticipantCategoryResolution(category: .monthly, reason: visualFallbackReason)
        }
        if ownContractType != nil {
            // Padrao (1) ou valor não documentado: mensalidade x pacote não é distinguível pela API do aluno
            return NextFitParticipantCategoryResolution(category: .unknown, reason: "contrato-proprio-padrao-sem-plano")
        }
        return NextFitParticipantCategoryResolution(category: .unknown, reason: "sem-dado-comercial")
    }

    /// Compatibilidade (diagnóstico DEBUG): sem classificação confirmada nem inferência persistida.
    static func resolve(
        participant: NextFitAgendaParticipantDisplay,
        ownContractType: Int?
    ) -> NextFitParticipantCategoryResolution {
        resolve(
            participant: participant,
            confirmedCategory: nil,
            ownContractType: ownContractType,
            hasPersistedInference: false
        )
    }
}

struct NextFitAgendaDetailDisplay: Equatable {
    let id: Int
    let statusAgendaParticipante: Int?
    let modalityId: Int?
    let hasCheckIn: Bool?
    let canSchedule: Bool?
    let canCancelCheckIn: Bool?
    let dateText: String
    let scheduleText: String
    let capacityText: String
    let modalityName: String
    let instructorName: String
    let locationName: String
    let participants: [NextFitAgendaParticipantDisplay]
    /// `Content.Status` da agenda (1 = aberta; 2 = encerrada, conforme respostas observadas).
    /// Usado somente para preservar a categoria visual dos participantes.
    var agendaStatus: Int? = nil
    var startDate: Date? = nil
    var endDate: Date? = nil

    /// Aula encerrada: dados operacionais dos participantes podem ter sido atualizados pela NextFit.
    var isClosed: Bool {
        if agendaStatus == 2 { return true }
        if let endDate, endDate <= Date() { return true }
        return false
    }

    /// Aula já iniciada ou encerrada (não é aula futura).
    var hasStarted: Bool {
        if isClosed { return true }
        if let startDate, startDate <= Date() { return true }
        return false
    }
}

struct NextFitIdentificationResponse: Decodable {
    let content: Content?
    let success: Bool

    struct Content: Decodable {
        let cadastroLocalizado: Bool
        let unidades: Units?

        struct Units: Decodable {
            let atuais: [Unit]
            let outros: [Unit]

            enum CodingKeys: String, CodingKey {
                case atuais = "Atuais"
                case outros = "Outros"
            }
        }

        struct Unit: Decodable {
            let codigoCliente: Int
            let codigoTenant: Int
            let codigoUnidade: Int
            let nomeFantasia: String?
            let temSenhaCadastrada: Bool?

            enum CodingKeys: String, CodingKey {
                case codigoCliente = "CodigoCliente"
                case codigoTenant = "CodigoTenant"
                case codigoUnidade = "CodigoUnidade"
                case nomeFantasia = "NomeFantasia"
                case temSenhaCadastrada = "TemSenhaCadastrada"
            }
        }

        enum CodingKeys: String, CodingKey {
            case cadastroLocalizado = "CadastroLocalizado"
            case unidades = "Unidades"
        }
    }

    enum CodingKeys: String, CodingKey {
        case content = "Content"
        case success = "Success"
    }
}

struct NextFitTokenResponse: Decodable {
    let accessToken: String
    let expiresIn: Int?
    let tokenType: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "AccessToken"
        case expiresIn = "ExpiresIn"
        case tokenType = "TokenType"
    }
}

struct NextFitClientMainDataResponse: Decodable {
    let content: Content?
    let success: Bool
    let message: String?
    let errorCode: Int?

    struct Content: Decodable {
        let clientId: Int
        let contracts: [Contract]

        struct Contract: Decodable {
            let id: Int
            let status: Int
            let type: Int
            let modalities: [Modality]
            /// `Contratos[].Descricao` (texto livre do plano/produto, opcional). Lido apenas como
            /// evidência potencial; NÃO é usado na classificação enquanto não houver regras validadas.
            let descriptionText: String?

            struct Modality: Decodable {
                let id: Int
                let modalityId: Int

                enum CodingKeys: String, CodingKey {
                    case id = "Id"
                    case modalityId = "CodigoModalidade"
                }
            }

            enum CodingKeys: String, CodingKey {
                case id = "Id"
                case status = "Status"
                case type = "Tipo"
                case modalities = "Modalidades"
                case descriptionText = "Descricao"
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                id = try container.decode(Int.self, forKey: .id)
                status = try container.decode(Int.self, forKey: .status)
                type = try container.decode(Int.self, forKey: .type)
                modalities = try container.decode([Modality].self, forKey: .modalities)
                // Tolerante: ausência ou formato inesperado de `Descricao` nunca invalida o contrato
                descriptionText = try? container.decodeIfPresent(String.self, forKey: .descriptionText)
            }
        }

        enum CodingKeys: String, CodingKey {
            case clientId = "CodigoCliente"
            case contracts = "Contratos"
        }
    }

    enum CodingKeys: String, CodingKey {
        case content = "Content"
        case success = "Success"
        case message = "Message"
        case errorCode = "ErrorCode"
    }
}

struct NextFitDailyWodsResponse: Decodable {
    let content: [Wod]
    let success: Bool

    struct Wod: Decodable {
        let id: Int
        let dataExec: String
        let descricao: String?
        let codigoModalidade: Int
        let descricaoModalidade: String?

        enum CodingKeys: String, CodingKey {
            case id = "Id"
            case dataExec = "DataExec"
            case descricao = "Descricao"
            case codigoModalidade = "CodigoModalidade"
            case descricaoModalidade = "DescricaoModalidade"
        }
    }

    enum CodingKeys: String, CodingKey {
        case content = "Content"
        case success = "Success"
    }
}

struct NextFitStudentModalitiesResponse: Decodable {
    let content: [Modality]
    let success: Bool

    struct Modality: Decodable {
        let id: Int
        let descricao: String

        enum CodingKeys: String, CodingKey {
            case id = "Id"
            case descricao = "Descricao"
        }
    }

    enum CodingKeys: String, CodingKey {
        case content = "Content"
        case success = "Success"
    }
}

struct NextFitWodDetailsResponse: Decodable {
    let content: Content?
    let success: Bool

    struct Content: Decodable {
        let modalidade: Modality?
        let wodAtividadeCross: [Activity]

        struct Modality: Decodable {
            let id: Int
            let descricao: String

            enum CodingKeys: String, CodingKey {
                case id = "Id"
                case descricao = "Descricao"
            }
        }

        struct Activity: Decodable {
            let titulo: String
            let descricao: String
            let ordem: Int

            enum CodingKeys: String, CodingKey {
                case titulo = "Titulo"
                case descricao = "Descricao"
                case ordem = "Ordem"
            }
        }

        enum CodingKeys: String, CodingKey {
            case modalidade = "Modalidade"
            case wodAtividadeCross = "WodAtividadeCross"
        }
    }

    enum CodingKeys: String, CodingKey {
        case content = "Content"
        case success = "Success"
    }
}

struct NextFitAgendaResponse: Decodable {
    let content: [Entry]
    let success: Bool
    let last: Bool?
    let message: String?
    let errorCode: Int?

    struct Entry: Decodable {
        let id: Int
        let statusAgendaParticipante: Int?
        let dataInicial: String
        let dataFinal: String
        let descricao: String?
        let qtdeAlunos: Int
        let limiteAlunos: Int
        let nomeInstrutor: String?
        let descricaoLocalAgenda: String?
        let fezCheckin: Bool?
        let podeAgendar: Bool?
        let permiteCancelarCheckin: Bool?

        enum CodingKeys: String, CodingKey {
            case id = "Id"
            case statusAgendaParticipante = "StatusAgendaParticipante"
            case dataInicial = "DataInicial"
            case dataFinal = "DataFinal"
            case descricao = "Descricao"
            case qtdeAlunos = "QtdeAlunos"
            case limiteAlunos = "LimiteAlunos"
            case nomeInstrutor = "NomeInstrutor"
            case descricaoLocalAgenda = "DescricaoLocalAgenda"
            case fezCheckin = "FezCheckin"
            case podeAgendar = "PodeAgendar"
            case permiteCancelarCheckin = "PermiteCancelarCheckin"
        }
    }

    enum CodingKeys: String, CodingKey {
        case content = "Content"
        case success = "Success"
        case last = "Last"
        case message = "Message"
        case errorCode = "ErrorCode"
    }
}

struct NextFitAgendaCheckInResponse: Decodable {
    let content: Content?
    let success: Bool
    let message: String?
    let errorCode: Int?

    struct Content: Decodable {
        let entrouNaFilaDeEspera: Bool
        let waitResult: Bool

        enum CodingKeys: String, CodingKey {
            case entrouNaFilaDeEspera = "EntrouNaFilaDeEspera"
            case waitResult = "WaitResult"
        }
    }

    enum CodingKeys: String, CodingKey {
        case content = "Content"
        case success = "Success"
        case message = "Message"
        case errorCode = "ErrorCode"
    }
}

struct NextFitAgendaCancelCheckInResponse: Decodable {
    let content: Content?
    let success: Bool
    let message: String?
    let errorCode: Int?

    struct Content: Decodable {
        let agendaId: Int?
        let question: String?

        enum CodingKeys: String, CodingKey {
            case agendaId = "CodigoAgenda"
            case question = "Pergunta"
        }
    }

    enum CodingKeys: String, CodingKey {
        case content = "Content"
        case success = "Success"
        case message = "Message"
        case errorCode = "ErrorCode"
    }
}

struct NextFitAgendaDetailResponse: Decodable {
    let content: Content?
    let success: Bool

    struct Content: Decodable {
        let id: Int
        let statusAgendaParticipante: Int?
        let codigoModalidade: Int?
        let fezCheckin: Bool?
        let podeAgendar: Bool?
        let permiteCancelarCheckin: Bool?
        let dataInicial: String
        let dataFinal: String
        let descricao: String?
        let nomeInstrutor: String?
        let descricaoLocalAgenda: String?
        let limiteAlunos: Int
        let qtdeAlunos: Int
        let participantes: [Participant]
        /// `Content.Status` da agenda (opcional; ausência não invalida a resposta).
        let status: Int?

        struct Participant: Decodable {
            let id: Int
            let nomeParticipante: String
            let codigoContratoCliente: Int?
            let codigoCliente: Int?
            let status: Int?
            let tipo: Int?

            enum CodingKeys: String, CodingKey {
                case id = "Id"
                case nomeParticipante = "NomeParticipante"
                case codigoContratoCliente = "CodigoContratoCliente"
                case codigoCliente = "CodigoCliente"
                case status = "Status"
                case tipo = "Tipo"
            }
        }

        enum CodingKeys: String, CodingKey {
            case id = "Id"
            case statusAgendaParticipante = "StatusAgendaParticipante"
            case codigoModalidade = "CodigoModalidade"
            case fezCheckin = "FezCheckin"
            case podeAgendar = "PodeAgendar"
            case permiteCancelarCheckin = "PermiteCancelarCheckin"
            case dataInicial = "DataInicial"
            case dataFinal = "DataFinal"
            case descricao = "Descricao"
            case nomeInstrutor = "NomeInstrutor"
            case descricaoLocalAgenda = "DescricaoLocalAgenda"
            case limiteAlunos = "LimiteAlunos"
            case qtdeAlunos = "QtdeAlunos"
            case participantes = "Participantes"
            case status = "Status"
        }
    }

    enum CodingKeys: String, CodingKey {
        case content = "Content"
        case success = "Success"
    }
}
