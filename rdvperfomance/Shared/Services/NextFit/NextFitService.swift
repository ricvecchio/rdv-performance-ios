import Foundation
import UIKit

enum NextFitServiceError: LocalizedError {
    case missingSession
    case invalidSession
    case registrationNotFound
    case muralhaRegistrationNotFound
    case invalidCredentials
    case unavailable

    var errorDescription: String? {
        switch self {
        case .missingSession, .invalidSession:
            return "Conecte sua conta NextFit para consultar o treino de hoje."
        case .registrationNotFound:
            return "Não encontramos este cadastro no NextFit."
        case .muralhaRegistrationNotFound:
            return "Não encontramos um cadastro da Muralha nesta conta NextFit."
        case .invalidCredentials:
            return "Não foi possível entrar no NextFit. Verifique seus dados."
        case .unavailable:
            return "Não foi possível carregar o WOD. Tente novamente."
        }
    }
}

struct NextFitService {
    private static let baseURL = URL(string: "https://apiappaluno.nextfit.com.br/api")!
    private static let muralhaUnitCode = 30299
    private static let crossFitModalityCode = 262777
    private static let dailyModalityCodes = [262777, 265538]
    private static let dailyModalities = "[262777,265538]"

    func authenticate(email: String, password: String, sessionAccount: String) async throws {
        let registration = try await recoverRegistration(email: email)

        guard registration.success,
              let content = registration.content,
              content.cadastroLocalizado else {
            throw NextFitServiceError.registrationNotFound
        }

        let units = (content.unidades?.atuais ?? []) + (content.unidades?.outros ?? [])
        guard let muralha = units.first(where: { $0.codigoUnidade == Self.muralhaUnitCode }) else {
            throw NextFitServiceError.muralhaRegistrationNotFound
        }

        var request = URLRequest(url: Self.baseURL.appending(path: "Token"))
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        applyBaseHeaders(to: &request)
        request.httpBody = formData([
            "grant_type": "password",
            "username": email,
            "password": password,
            "codigoTenant": String(muralha.codigoTenant),
            "codigoUnidade": String(muralha.codigoUnidade),
            "codigoCliente": String(muralha.codigoCliente),
            "app_id": "nextfit-app-aluno"
        ])

        let data = try await responseData(for: request)
        let tokenResponse: NextFitTokenResponse
        do {
            tokenResponse = try JSONDecoder().decode(NextFitTokenResponse.self, from: data)
        } catch {
            throw NextFitServiceError.invalidCredentials
        }

        let token = tokenResponse.accessToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty else {
            throw NextFitServiceError.invalidCredentials
        }
        try NextFitKeychainStore.save(token: token, for: sessionAccount)
    }

    func loadTodayWods(sessionAccount: String) async throws -> [NextFitWodDisplay] {
        guard let token = try NextFitKeychainStore.token(for: sessionAccount) else {
            throw NextFitServiceError.missingSession
        }

        do {
            var components = URLComponents(
                url: Self.baseURL.appending(path: "WodCross/RecuperarWodsDiaPorModalidade"),
                resolvingAgainstBaseURL: false
            )!
            components.queryItems = [
                URLQueryItem(name: "ModalidadesStr", value: Self.dailyModalities)
            ]

            var dailyRequest = URLRequest(url: components.url!)
            dailyRequest.timeoutInterval = 20
            applyAuthenticatedHeaders(to: &dailyRequest, token: token)

            let dailyData = try await responseData(for: dailyRequest)
            let dailyResponse = try JSONDecoder().decode(NextFitDailyWodsResponse.self, from: dailyData)
            guard dailyResponse.success else {
                throw NextFitServiceError.unavailable
            }

            debugLog("Endpoint diário retornou \(dailyResponse.content.count) registro(s).")
            for wod in dailyResponse.content {
                debugLog(
                    "Diário - Id: \(wod.id), CodigoModalidade: \(wod.codigoModalidade), DataExec: \(wod.dataExec)"
                )
            }

            let calendar = Calendar.current
            let availableTodayWods = dailyResponse.content
                .filter {
                    Self.dailyModalityCodes.contains($0.codigoModalidade) &&
                        isToday($0.dataExec, calendar: calendar)
                }
            debugLog("WOD(s) das modalidades solicitadas para hoje: \(availableTodayWods.count).")

            let todayWods = availableTodayWods.filter {
                $0.codigoModalidade == Self.crossFitModalityCode
            } + availableTodayWods.filter {
                $0.codigoModalidade != Self.crossFitModalityCode
            }

            var displays = [NextFitWodDisplay]()
            var displayedDailyModalityCodes = Set<Int>()

            for wod in todayWods {
                guard displayedDailyModalityCodes.insert(wod.codigoModalidade).inserted else {
                    debugLog("Modalidade diária \(wod.codigoModalidade) já adicionada; WOD \(wod.id) ignorado.")
                    continue
                }

                var detailsRequest = URLRequest(
                    url: Self.baseURL.appending(path: "WodCross/\(wod.id)")
                )
                detailsRequest.timeoutInterval = 20
                applyAuthenticatedHeaders(to: &detailsRequest, token: token)

                let detailsData = try await responseData(for: detailsRequest)
                let detailsResponse = try JSONDecoder().decode(NextFitWodDetailsResponse.self, from: detailsData)
                guard detailsResponse.success,
                      let content = detailsResponse.content else {
                    throw NextFitServiceError.unavailable
                }

                let modalityId = content.modalidade?.id ?? wod.codigoModalidade
                let apiModalityName = content.modalidade?.descricao
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let dailyModalityName = wod.descricaoModalidade?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let modalityName = !apiModalityName.isEmpty
                    ? apiModalityName
                    : (!dailyModalityName.isEmpty ? dailyModalityName : "Modalidade \(modalityId)")
                debugLog(
                    "Detalhe - Wod Id: \(wod.id), CodigoModalidade: \(wod.codigoModalidade), "
                        + "Modalidade.Id: \(content.modalidade?.id.description ?? "ausente"), "
                        + "Modalidade.Descricao: \(apiModalityName.isEmpty ? "ausente" : apiModalityName), "
                        + "Atividades: \(content.wodAtividadeCross.count)."
                )

                let wodActivities = content.wodAtividadeCross
                    .sorted { $0.ordem < $1.ordem }

                var displayActivities = [NextFitWodActivityDisplay]()
                for activity in wodActivities {
                    let description = try plainText(fromHTML: activity.descricao)
                    displayActivities.append(
                        NextFitWodActivityDisplay(
                            title: activity.titulo,
                            description: description,
                            order: activity.ordem
                        )
                    )
                }

                displays.append(
                    NextFitWodDisplay(
                        modalityId: modalityId,
                        modalityName: modalityName,
                        activities: displayActivities
                    )
                )
                debugLog(
                    "Modalidade adicionada - Id: \(modalityId), Nome: \(modalityName), "
                        + "Atividades exibíveis: \(displayActivities.count), Total: \(displays.count)."
                )
            }

            debugLog("Total final de modalidades entregues à ViewModel: \(displays.count).")
            return displays
        } catch NextFitHTTPError.unauthorized {
            try? NextFitKeychainStore.deleteToken(for: sessionAccount)
            throw NextFitServiceError.invalidSession
        } catch let error as NextFitServiceError {
            throw error
        } catch {
            throw NextFitServiceError.unavailable
        }
    }

    func loadTodayAgenda(sessionAccount: String) async throws -> [NextFitAgendaDisplay] {
        guard let token = try NextFitKeychainStore.token(for: sessionAccount) else {
            throw NextFitServiceError.missingSession
        }

        do {
            var components = URLComponents(
                url: Self.baseURL.appending(path: "AgendaV2"),
                resolvingAgainstBaseURL: false
            )!
            let today = formattedCurrentDate()
            components.queryItems = [
                URLQueryItem(name: "DataInicialStr", value: today),
                URLQueryItem(name: "DataFinalStr", value: today),
                URLQueryItem(name: "FiltrarMeusAgendamentos", value: "false"),
                URLQueryItem(name: "FiltrarHistorico", value: "false"),
                URLQueryItem(name: "PeriodosStr", value: "[]"),
                URLQueryItem(name: "CodigosModalidadesStr", value: "[]"),
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "limit", value: "10"),
                URLQueryItem(name: "sort", value: "[]"),
                URLQueryItem(name: "filter", value: "[]"),
                URLQueryItem(name: "includes", value: "[]"),
                URLQueryItem(name: "fields", value: "[]")
            ]

            guard let url = components.url else {
                throw NextFitServiceError.unavailable
            }
            var request = URLRequest(url: url)
            request.timeoutInterval = 20
            applyAuthenticatedHeaders(to: &request, token: token)

            let data = try await responseData(for: request)
            let response = try JSONDecoder().decode(NextFitAgendaResponse.self, from: data)
            guard response.success else {
                throw NextFitServiceError.unavailable
            }

            let calendar = Calendar.current
            let agenda = try response.content.compactMap { entry -> NextFitAgendaDisplay? in
                guard let startDate = agendaDate(from: entry.dataInicial),
                      let endDate = agendaDate(from: entry.dataFinal) else {
                    throw NextFitServiceError.unavailable
                }
                guard calendar.isDateInToday(startDate) else {
                    return nil
                }

                return NextFitAgendaDisplay(
                    id: entry.id,
                    startDate: startDate,
                    startTime: formattedTime(from: startDate),
                    endTime: formattedTime(from: endDate),
                    enrolledStudents: entry.qtdeAlunos,
                    studentLimit: entry.limiteAlunos,
                    modalityName: entry.descricao?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                    instructorName: entry.nomeInstrutor?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                    locationName: entry.descricaoLocalAgenda?
                        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                )
            }
            return agenda.sorted { $0.startDate < $1.startDate }
        } catch NextFitHTTPError.unauthorized {
            try? NextFitKeychainStore.deleteToken(for: sessionAccount)
            throw NextFitServiceError.invalidSession
        } catch let error as NextFitServiceError {
            throw error
        } catch {
            throw NextFitServiceError.unavailable
        }
    }

    func loadAgendaDetail(
        agendaId: Int,
        sessionAccount: String
    ) async throws -> NextFitAgendaDetailDisplay {
        guard let token = try NextFitKeychainStore.token(for: sessionAccount) else {
            throw NextFitServiceError.missingSession
        }

        do {
            var request = URLRequest(url: Self.baseURL.appending(path: "Agenda/\(agendaId)"))
            request.timeoutInterval = 20
            applyAuthenticatedHeaders(to: &request, token: token)

            let data = try await responseData(for: request)
            let response = try JSONDecoder().decode(NextFitAgendaDetailResponse.self, from: data)
            guard response.success,
                  let content = response.content,
                  let startDate = agendaDate(from: content.dataInicial),
                  let endDate = agendaDate(from: content.dataFinal) else {
                throw NextFitServiceError.unavailable
            }

            return NextFitAgendaDetailDisplay(
                id: content.id,
                dateText: formattedDate(from: startDate),
                scheduleText: "\(formattedTime(from: startDate)) às \(formattedTime(from: endDate))",
                capacityText: String(format: "%02d/%02d", content.qtdeAlunos, content.limiteAlunos),
                modalityName: content.descricao?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                instructorName: content.nomeInstrutor?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                locationName: content.descricaoLocalAgenda?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                participants: content.participantes.map {
                    NextFitAgendaParticipantDisplay(id: $0.id, name: $0.nomeParticipante)
                }
            )
        } catch NextFitHTTPError.unauthorized {
            try? NextFitKeychainStore.deleteToken(for: sessionAccount)
            throw NextFitServiceError.invalidSession
        } catch let error as NextFitServiceError {
            throw error
        } catch {
            throw NextFitServiceError.unavailable
        }
    }

    func hasSession(sessionAccount: String) -> Bool {
        (try? NextFitKeychainStore.token(for: sessionAccount)) != nil
    }

    func logout(sessionAccount: String) throws {
        try NextFitKeychainStore.deleteToken(for: sessionAccount)
    }

    private func recoverRegistration(email: String) async throws -> NextFitIdentificationResponse {
        var components = URLComponents(
            url: Self.baseURL.appending(path: "Auth/v2/RecuperarPorIdentificacao"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(
                name: "dtc",
                value: String(Int64(Date().timeIntervalSince1970 * 1_000))
            ),
            URLQueryItem(name: "identificacao", value: email)
        ]

        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 20
        applyBaseHeaders(to: &request)

        do {
            let data = try await responseData(for: request)
            return try JSONDecoder().decode(NextFitIdentificationResponse.self, from: data)
        } catch let error as NextFitServiceError {
            throw error
        } catch {
            throw NextFitServiceError.unavailable
        }
    }

    private func applyBaseHeaders(to request: inout URLRequest) {
        request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        request.setValue("pt-BR,pt;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.setValue("AppAluno|2|iPhone|5.2.0", forHTTPHeaderField: "User-Agent")
    }

    private func applyAuthenticatedHeaders(to request: inout URLRequest, token: String) {
        applyBaseHeaders(to: &request)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(String(Self.muralhaUnitCode), forHTTPHeaderField: "codigo-unidade")
    }

    private func responseData(for request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NextFitServiceError.unavailable
        }
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw NextFitHTTPError.unauthorized
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NextFitServiceError.unavailable
        }
        return data
    }

    private func formData(_ values: [String: String]) -> Data {
        var components = URLComponents()
        components.queryItems = values.map { URLQueryItem(name: $0.key, value: $0.value) }
        return Data((components.percentEncodedQuery ?? "").utf8)
    }

    private func isToday(_ value: String, calendar: Calendar) -> Bool {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        guard let date = formatter.date(from: value) else {
            debugLog("Não foi possível interpretar DataExec: \(value).")
            return false
        }
        return calendar.isDateInToday(date)
    }

    private func agendaDate(from value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        return formatter.date(from: value)
    }

    private func formattedCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = Calendar.current.timeZone
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: Date())
    }

    private func formattedDate(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }

    private func formattedTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func debugLog(_ message: String) {
        #if DEBUG
        print("[NextFit Debug] \(message)")
        #endif
    }

    private func plainText(fromHTML html: String) throws -> String {
        let attributed = try NSAttributedString(
            data: Data(html.utf8),
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        )
        return attributed.string
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\r\n", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private enum NextFitHTTPError: Error {
    case unauthorized
}
