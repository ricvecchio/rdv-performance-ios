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
    private static let dailyModalities = "[262777,265536]"

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

    func loadTodayWod(sessionAccount: String) async throws -> NextFitWodDisplay? {
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

            let calendar = Calendar.current
            guard let wod = dailyResponse.content.first(where: {
                $0.codigoModalidade == Self.crossFitModalityCode &&
                    isToday($0.dataExec, calendar: calendar)
            }) else {
                return nil
            }

            var detailsRequest = URLRequest(
                url: Self.baseURL.appending(path: "WodCross/\(wod.id)")
            )
            detailsRequest.timeoutInterval = 20
            applyAuthenticatedHeaders(to: &detailsRequest, token: token)

            let detailsData = try await responseData(for: detailsRequest)
            let detailsResponse = try JSONDecoder().decode(NextFitWodDetailsResponse.self, from: detailsData)
            guard detailsResponse.success,
                  let activities = detailsResponse.content?.wodAtividadeCross else {
                throw NextFitServiceError.unavailable
            }

            guard let activity = activities
                .filter({ $0.titulo.trimmingCharacters(in: .whitespacesAndNewlines).caseInsensitiveCompare("WOD") == .orderedSame })
                .sorted(by: { $0.ordem < $1.ordem })
                .first else {
                return nil
            }

            let description = try plainText(fromHTML: activity.descricao)
            guard !description.isEmpty else {
                return nil
            }
            return NextFitWodDisplay(activityTitle: activity.titulo, description: description)
        } catch NextFitHTTPError.unauthorized {
            try? NextFitKeychainStore.deleteToken(for: sessionAccount)
            throw NextFitServiceError.invalidSession
        } catch let error as NextFitServiceError {
            throw error
        } catch {
            throw NextFitServiceError.unavailable
        }
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
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        guard let date = formatter.date(from: value) else {
            return false
        }
        return calendar.isDateInToday(date)
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
