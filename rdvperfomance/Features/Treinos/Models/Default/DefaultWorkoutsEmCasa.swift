import Foundation

enum DefaultWorkoutsEmCasa {

    static func defaults(sectionKey: String) -> [DefaultWorkoutSeed] {
        let key = normalize(sectionKey)

        if matches(key, anyOf: ["costas", "back", "postura", "escap", "escáp", "dorsal"]) {
            return costasDefaults()
        }
        if matches(key, anyOf: ["peito", "chest", "push", "flex", "flexao", "flexão"]) {
            return peitoDefaults()
        }
        if matches(key, anyOf: ["perna", "pernas", "legs", "inferior", "lower", "glute", "glúteo", "gluteo", "posterior", "ham"]) {
            return pernasDefaults()
        }
        if matches(key, anyOf: ["ombro", "ombros", "shoulder", "delto", "estabilidade"]) {
            return ombrosDefaults()
        }
        if matches(key, anyOf: ["braco", "braço", "bracos", "braços", "arms", "biceps", "bíceps", "triceps", "tríceps"]) {
            return bracosDefaults()
        }
        if matches(key, anyOf: ["abd", "abdominal", "abs", "core", "tronco"]) {
            return coreDefaults()
        }
        if matches(key, anyOf: ["full", "fullbody", "full body", "geral", "corpo todo", "total body", "upper", "superior"]) {
            return fullBodyDefaults()
        }

        // Fallback seguro
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

    // MARK: - COSTAS (Em Casa)

    private static func costasDefaults() -> [DefaultWorkoutSeed] {
        return [
            DefaultWorkoutSeed(name: "COSTAS_CASA", category: .emCasa, sectionKey: "costas", blockOrders: [1, 2, 3])
        ]
    }

    // MARK: - PEITO (Em Casa)

    private static func peitoDefaults() -> [DefaultWorkoutSeed] {
        return [
            DefaultWorkoutSeed(name: "PEITO_CASA", category: .emCasa, sectionKey: "peito", blockOrders: [1, 2, 3])
        ]
    }

    // MARK: - PERNAS (Em Casa)

    private static func pernasDefaults() -> [DefaultWorkoutSeed] {
        return [
            DefaultWorkoutSeed(name: "PERNAS_CASA", category: .emCasa, sectionKey: "pernas", blockOrders: [1, 2])
        ]
    }

    // MARK: - OMBROS (Em Casa)

    private static func ombrosDefaults() -> [DefaultWorkoutSeed] {
        return [
            DefaultWorkoutSeed(name: "OMBROS_CASA", category: .emCasa, sectionKey: "ombros", blockOrders: [1, 2, 3])
        ]
    }

    // MARK: - BRAÇOS (Em Casa)

    private static func bracosDefaults() -> [DefaultWorkoutSeed] {
        return [
            DefaultWorkoutSeed(name: "BRACOS_CASA", category: .emCasa, sectionKey: "bracos", blockOrders: [1, 2])
        ]
    }

    // MARK: - CORE (Em Casa)

    private static func coreDefaults() -> [DefaultWorkoutSeed] {
        return [
            DefaultWorkoutSeed(name: "CORE_CASA", category: .emCasa, sectionKey: "core", blockOrders: [1, 2, 3])
        ]
    }

    // MARK: - FULL BODY (Em Casa)

    private static func fullBodyDefaults() -> [DefaultWorkoutSeed] {
        return [
            DefaultWorkoutSeed(name: "FULLBODY_CASA", category: .emCasa, sectionKey: "fullBody", blockOrders: [1, 2, 3])
        ]
    }
}
