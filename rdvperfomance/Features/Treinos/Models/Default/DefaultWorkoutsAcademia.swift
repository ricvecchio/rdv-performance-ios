import Foundation

enum DefaultWorkoutsAcademia {

    static func defaults(sectionKey: String) -> [DefaultWorkoutSeed] {
        let key = normalize(sectionKey)

        if matches(key, anyOf: ["costas", "dorsal", "back", "lat", "lats", "remada", "puxada"]) {
            return costasDefaults()
        }
        if matches(key, anyOf: ["peito", "chest", "supino", "crossover", "crucifixo"]) {
            return peitoDefaults()
        }
        if matches(key, anyOf: ["perna", "pernas", "legs", "inferior", "lower", "quad", "quadriceps", "posterior", "ham", "glute", "glúteo", "gluteo"]) {
            return pernasDefaults()
        }
        if matches(key, anyOf: ["ombro", "ombros", "shoulder", "delto", "delts", "deltoide", "deltoides"]) {
            return ombrosDefaults()
        }
        if matches(key, anyOf: ["braco", "braço", "bracos", "braços", "arms", "biceps", "bíceps", "triceps", "tríceps"]) {
            return bracosDefaults()
        }
        if matches(key, anyOf: ["abd", "abdominal", "abs", "core", "tronco", "estabilidade"]) {
            return coreDefaults()
        }
        if matches(key, anyOf: ["full", "fullbody", "full body", "geral", "corpo todo", "total body", "upper", "superior"]) {
            return fullBodyDefaults()
        }

        // Fallback seguro: entrega um treino geral
        return fullBodyDefaults()
    }

    private static func normalize(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func matches(_ key: String, anyOf terms: [String]) -> Bool {
        for t in terms {
            if key.contains(t) { return true }
        }
        return false
    }

    // MARK: - COSTAS

    private static func costasDefaults() -> [DefaultWorkoutSeed] {
        return [
            DefaultWorkoutSeed(name: "COSTAS_A", category: .academia, sectionKey: "costas", blockOrders: [1, 2, 3, 4]),
            DefaultWorkoutSeed(name: "COSTAS_B", category: .academia, sectionKey: "costas", blockOrders: [1, 2, 3])
        ]
    }

    // MARK: - PEITO

    private static func peitoDefaults() -> [DefaultWorkoutSeed] {
        return [
            DefaultWorkoutSeed(name: "PEITO_A", category: .academia, sectionKey: "peito", blockOrders: [1, 2, 3, 4]),
            DefaultWorkoutSeed(name: "PEITO_B", category: .academia, sectionKey: "peito", blockOrders: [1, 2, 3])
        ]
    }

    // MARK: - PERNAS

    private static func pernasDefaults() -> [DefaultWorkoutSeed] {
        return [
            DefaultWorkoutSeed(name: "PERNAS_A", category: .academia, sectionKey: "pernas", blockOrders: [1, 2, 3]),
            DefaultWorkoutSeed(name: "PERNAS_B", category: .academia, sectionKey: "pernas", blockOrders: [1, 2, 3])
        ]
    }

    // MARK: - OMBROS

    private static func ombrosDefaults() -> [DefaultWorkoutSeed] {
        return [
            DefaultWorkoutSeed(name: "OMBROS_PADRAO", category: .academia, sectionKey: "ombros", blockOrders: [1, 2, 3])
        ]
    }

    // MARK: - BRAÇOS

    private static func bracosDefaults() -> [DefaultWorkoutSeed] {
        return [
            DefaultWorkoutSeed(name: "BRACOS_PADRAO", category: .academia, sectionKey: "bracos", blockOrders: [1, 2, 3])
        ]
    }

    // MARK: - CORE

    private static func coreDefaults() -> [DefaultWorkoutSeed] {
        return [
            DefaultWorkoutSeed(name: "CORE_ESTABILIDADE", category: .academia, sectionKey: "core", blockOrders: [1, 2, 3])
        ]
    }

    // MARK: - FULL BODY

    private static func fullBodyDefaults() -> [DefaultWorkoutSeed] {
        return [
            DefaultWorkoutSeed(name: "FULLBODY_ACADEMIA", category: .academia, sectionKey: "fullBody", blockOrders: [1, 2])
        ]
    }
}
