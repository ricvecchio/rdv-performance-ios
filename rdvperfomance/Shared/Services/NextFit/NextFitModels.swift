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

struct NextFitAgendaDisplay: Equatable, Identifiable {
    let id: Int
    let startDate: Date
    let startTime: String
    let endTime: String
    let enrolledStudents: Int
    let studentLimit: Int
    let modalityName: String
    let instructorName: String
    let locationName: String
    let canSchedule: Bool
    let canCancelCheckIn: Bool

    var scheduleText: String { "\(startTime) às \(endTime)" }
    var capacityText: String { String(format: "%02d/%02d", enrolledStudents, studentLimit) }
}

struct NextFitAgendaParticipantDisplay: Equatable, Identifiable {
    let id: Int
    let name: String
}

struct NextFitAgendaDetailDisplay: Equatable {
    let id: Int
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

    struct Entry: Decodable {
        let id: Int
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
    }
}

struct NextFitAgendaCheckInResponse: Decodable {
    let content: Content?
    let success: Bool

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
    }
}

struct NextFitAgendaCancelCheckInResponse: Decodable {
    let success: Bool

    enum CodingKeys: String, CodingKey {
        case success = "Success"
    }
}

struct NextFitAgendaDetailResponse: Decodable {
    let content: Content?
    let success: Bool

    struct Content: Decodable {
        let id: Int
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

            enum CodingKeys: String, CodingKey {
                case id = "Id"
                case nomeParticipante = "NomeParticipante"
            }
        }

        enum CodingKeys: String, CodingKey {
            case id = "Id"
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
