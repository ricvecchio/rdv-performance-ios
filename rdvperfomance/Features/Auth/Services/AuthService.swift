import Foundation

final class AuthService {

    private let baseURL: String = "http://localhost:8080"

    func register(_ dto: RegisterRequestDTO) async throws -> RegisterResponseDTO {
        guard let url = URL(string: "\(baseURL)/api/users/register") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(dto)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(
                domain: "AuthService",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Falha ao cadastrar (\(http.statusCode)). \(body)"]
            )
        }

        return (try? JSONDecoder().decode(RegisterResponseDTO.self, from: data))
            ?? RegisterResponseDTO(idUser: nil, message: "Cadastro realizado com sucesso.")
    }

    // MARK: - LOGIN (MVP)
    func login(_ dto: LoginRequestDTO) async throws -> LoginResponseDTO {

        // ✅ AJUSTE AQUI se a rota for diferente no backend
        guard let url = URL(string: "\(baseURL)/api/users/login") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(dto)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(
                domain: "AuthService",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Falha no login (\(http.statusCode)). \(body)"]
            )
        }

        // Se o backend ainda não devolve token/userType, isso vai virar nil.
        // Aí você ajusta o backend para incluir.
        return (try? JSONDecoder().decode(LoginResponseDTO.self, from: data))
            ?? LoginResponseDTO(token: nil, userType: nil, name: nil, idUser: nil, message: "Login OK")
    }
}

