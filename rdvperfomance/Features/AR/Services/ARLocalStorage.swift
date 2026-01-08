// Serviço para armazenar e recuperar dados AR localmente usando UserDefaults
import Foundation

final class ARLocalStorage {
    private let userDefaults: UserDefaults
    static let shared = ARLocalStorage(userDefaults: .standard)

    // Inicializa com instância customizada de UserDefaults
    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    // Gera chave única para pontos de correção baseada em semana e dia
    private func keyForCorrectionPoints(weekId: String, dayId: String) -> String {
        return "ar.correctionPoints.\(weekId).\(dayId)"
    }

    // Salva array de pontos de correção no UserDefaults
    func saveCorrectionPoints(_ points: [ARCorrectionPoint], weekId: String, dayId: String) throws {
        let key = keyForCorrectionPoints(weekId: weekId, dayId: dayId)
        let data = try JSONEncoder().encode(points)
        userDefaults.set(data, forKey: key)
    }

    // Carrega pontos de correção salvos, retorna array vazio se houver erro
    func loadCorrectionPoints(weekId: String, dayId: String) -> [ARCorrectionPoint] {
        let key = keyForCorrectionPoints(weekId: weekId, dayId: dayId)
        guard let data = userDefaults.data(forKey: key) else { return [] }
        do {
            return try JSONDecoder().decode([ARCorrectionPoint].self, from: data)
        } catch {
            print("ARLocalStorage: failed to decode correction points for key=\(key), clearing corrupt data: \(error)")
            userDefaults.removeObject(forKey: key)
            return []
        }
    }

    // Salva qualquer valor codificável com chave customizada
    func save<T: Codable>(_ value: T, forKey key: String) throws {
        let data = try JSONEncoder().encode(value)
        userDefaults.set(data, forKey: key)
    }

    // Carrega valor codificável com chave customizada
    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
