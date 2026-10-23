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
    /// `Participantes[].Origem` = EnumOrigemAgendaParticipante (4 Gympass, 8 TotalPass, ...), quando enviado.
    let origin: Int?
}

/// Categoria comercial do participante usada exclusivamente para o ícone da lista de participantes.
enum NextFitParticipantCategory: Equatable {
    case monthly
    case package
    case external
    case unknown

    /// SF Symbol já aprovado para cada categoria.
    var symbolName: String {
        switch self {
        case .monthly: return "person.text.rectangle.fill"
        case .package: return "ticket.fill"
        case .external: return "globe"
        case .unknown: return "questionmark.circle"
        }
    }
}

struct NextFitParticipantCategoryResolution: Equatable {
    let category: NextFitParticipantCategory
    let reason: String
}

/// Dados comerciais do contrato do PRÓPRIO aluno autenticado vinculado ao participante.
struct NextFitOwnContractCommercialInfo: Equatable {
    /// `Contratos[].Tipo` = EnumTipoContratoBase.
    let contractType: Int
    /// `Modalidades[].Tipo` (EnumTipoContratoBaseModalidade) da modalidade da aula, quando disponível.
    let modalityType: Int?
}

/// Resolve a categoria comercial somente a partir de campos com semântica documentada.
/// Nunca usa `Participantes[].Status`, `Participantes[].Tipo`, `Descricao`, presença de contrato,
/// situação/horário da aula, nome ou posição na lista.
///
/// Fonte da semântica: Swagger oficial "API Pública Next Fit" (integracao.nextfit.com.br/swagger/v1),
/// enums numerados a partir de 1 — ordem confirmada pelos dados reais do app
/// (StatusAgendaParticipante 8 = Desistente; Status 1/2 = Reservado/Presente; Tipo 1 sem contrato =
/// Cliente, Tipo 2 com contrato = ContratoCliente; Contratos[].Status 1 = Ativo).
enum NextFitParticipantCategoryResolver {
    /// EnumOrigemAgendaParticipante: 4 = Gympass, 8 = TotalPass.
    static let externalParticipantOrigins: Set<Int> = [4, 8]

    /// EnumTipoContratoBase: 1 = Padrao; 2 = Gympass; 3 = GympassBooking; 4 = TotalPass; 5 = TotalPassBooking.
    static let standardContractType = 1
    static let externalContractTypes: Set<Int> = [2, 3, 4, 5]

    /// EnumTipoContratoBaseModalidade: 1 = Periodo (mensalidade por período);
    /// 2 = Sessao e 3 = PacoteAulas (quantidade de aulas/créditos).
    static let periodModalityType = 1
    static let packageModalityTypes: Set<Int> = [2, 3]

    // `Contratos[].Descricao` é decodificado, mas não participa da classificação (texto livre ambíguo).

    /// - Parameter ownContract: dados do contrato do próprio aluno autenticado vinculado a este
    ///   participante por `CodigoContratoCliente`; `nil` para todos os demais participantes.
    static func resolve(
        participant: NextFitAgendaParticipantDisplay,
        ownContract: NextFitOwnContractCommercialInfo?
    ) -> NextFitParticipantCategoryResolution {
        // 1. Origem documentada da reserva (vale para qualquer participante, quando enviada pela API)
        if let origin = participant.origin, externalParticipantOrigins.contains(origin) {
            return NextFitParticipantCategoryResolution(category: .external, reason: "origem-agregador")
        }

        // 2. Contrato do próprio aluno autenticado
        if let ownContract {
            if externalContractTypes.contains(ownContract.contractType) {
                return NextFitParticipantCategoryResolution(category: .external, reason: "contrato-proprio-agregador")
            }
            if ownContract.contractType == standardContractType {
                if let modalityType = ownContract.modalityType {
                    if modalityType == periodModalityType {
                        return NextFitParticipantCategoryResolution(category: .monthly, reason: "contrato-proprio-modalidade-periodo")
                    }
                    if packageModalityTypes.contains(modalityType) {
                        return NextFitParticipantCategoryResolution(category: .package, reason: "contrato-proprio-modalidade-pacote")
                    }
                    return NextFitParticipantCategoryResolution(category: .unknown, reason: "contrato-proprio-modalidade-desconhecida")
                }
                // Contrato Padrao sem `Modalidades[].Tipo` na resposta: preserva a identificação já
                // validada com dados reais (aluno autenticado mensalista com contrato Padrao, Tipo=1).
                return NextFitParticipantCategoryResolution(category: .monthly, reason: "contrato-proprio-padrao-sem-tipo-modalidade")
            }
            return NextFitParticipantCategoryResolution(category: .unknown, reason: "contrato-proprio-tipo-desconhecido")
        }

        // 3. Demais participantes: a API do aluno não expõe contrato/plano de terceiros
        return NextFitParticipantCategoryResolution(category: .unknown, reason: "sem-dado-comercial")
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
                /// `Modalidades[].Tipo` (EnumTipoContratoBaseModalidade; opcional, leitura tolerante).
                let type: Int?

                enum CodingKeys: String, CodingKey {
                    case id = "Id"
                    case modalityId = "CodigoModalidade"
                    case type = "Tipo"
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    id = try container.decode(Int.self, forKey: .id)
                    modalityId = try container.decode(Int.self, forKey: .modalityId)
                    // Tolerante: ausência ou formato inesperado de `Tipo` nunca invalida o contrato
                    type = try? container.decodeIfPresent(Int.self, forKey: .type)
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

        struct Participant: Decodable {
            let id: Int
            let nomeParticipante: String
            let codigoContratoCliente: Int?
            let codigoCliente: Int?
            let status: Int?
            let tipo: Int?
            /// `Participantes[].Origem` (EnumOrigemAgendaParticipante; opcional, leitura tolerante).
            let origem: Int?

            enum CodingKeys: String, CodingKey {
                case id = "Id"
                case nomeParticipante = "NomeParticipante"
                case codigoContratoCliente = "CodigoContratoCliente"
                case codigoCliente = "CodigoCliente"
                case status = "Status"
                case tipo = "Tipo"
                case origem = "Origem"
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                id = try container.decode(Int.self, forKey: .id)
                nomeParticipante = try container.decode(String.self, forKey: .nomeParticipante)
                codigoContratoCliente = try container.decodeIfPresent(Int.self, forKey: .codigoContratoCliente)
                codigoCliente = try container.decodeIfPresent(Int.self, forKey: .codigoCliente)
                status = try container.decodeIfPresent(Int.self, forKey: .status)
                tipo = try container.decodeIfPresent(Int.self, forKey: .tipo)
                // Tolerante: ausência ou formato inesperado de `Origem` nunca invalida o detalhe da aula
                origem = try? container.decodeIfPresent(Int.self, forKey: .origem)
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
        }
    }

    enum CodingKeys: String, CodingKey {
        case content = "Content"
        case success = "Success"
    }
}
