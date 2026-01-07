import Foundation

final class ARLocalStorage {
    private let userDefaults: UserDefaults
    static let shared = ARLocalStorage(userDefaults: .standard)

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    private func keyForCorrectionPoints(weekId: String, dayId: String) -> String {
        return "ar.correctionPoints.\(weekId).\(dayId)"
    }

    func saveCorrectionPoints(_ points: [ARCorrectionPoint], weekId: String, dayId: String) throws {
        let key = keyForCorrectionPoints(weekId: weekId, dayId: dayId)
        let data = try JSONEncoder().encode(points)
        userDefaults.set(data, forKey: key)
    }

    // Agora retorna lista e é resiliente a dados corrompidos
    func loadCorrectionPoints(weekId: String, dayId: String) -> [ARCorrectionPoint] {
        let key = keyForCorrectionPoints(weekId: weekId, dayId: dayId)
        guard let data = userDefaults.data(forKey: key) else { return [] }
        do {
            return try JSONDecoder().decode([ARCorrectionPoint].self, from: data)
        } catch {
            // Dados corrompidos: limpar key e retornar vazio (não propagar erro para a UI)
            print("ARLocalStorage: failed to decode correction points for key=\(key), clearing corrupt data: \(error)")
            userDefaults.removeObject(forKey: key)
            return []
        }
    }

    func save<T: Codable>(_ value: T, forKey key: String) throws {
        let data = try JSONEncoder().encode(value)
        userDefaults.set(data, forKey: key)
    }

    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
