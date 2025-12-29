import Foundation

// MARK: - AuthService (MVP)
final class AuthService {

    // ✅ Ajuste para sua URL real (Render / VPS / localhost)
    // Exemplo: "https://seu-backend.onrender.com"
    private let baseURL: String = "http://localhost:8080"

    func register(_ dto: RegisterRequestDTO) async throws -> RegisterResponseDTO {
        guard let url = URL(string: "\(baseURL)/api/auth/register") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(dto)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(http.statusCode) else {
            // Se quiser, aqui dá pra tentar decodificar erro do backend
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "AuthService",
                          code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "Falha ao cadastrar (\(http.statusCode)). \(body)"])
        }

        let decoder = JSONDecoder()
        return (try? decoder.decode(RegisterResponseDTO.self, from: data))
            ?? RegisterResponseDTO(idUser: nil, message: "Cadastro realizado com sucesso.")
    }
}
