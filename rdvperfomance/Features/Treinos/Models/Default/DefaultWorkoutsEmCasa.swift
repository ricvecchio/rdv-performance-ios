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

            DefaultWorkoutSeed(
                name: "COSTAS_CASA",
                title: "Costas (Casa) – Postura e Escápulas",
                description: "Treino funcional sem equipamentos para melhorar postura, estabilidade escapular e dorsais.",
                blocks: [
                    .init(title: "Aquecimento", text: """
• Mobilidade torácica: 8 rotações por lado
• Shoulder CARs: 6 por lado
• 2x10 Scapular push-ups (controle)
""", order: 1),
                    .init(title: "Detalhes", text: "Se tiver elástico, pode adicionar puxadas. Sem elástico, foque em controle e isometria.", order: 2),
                    .init(title: "Repetições", text: """
1) Superman hold — 3x20–40s
2) “Y-T-W” no chão — 3x8–10 cada letra
3) Remada isométrica com toalha (pé na toalha) — 4x20–30s
4) Prancha com toque no ombro — 3x20 reps
Descanso: 30–60s
""", order: 3)
                ]
            )
        ]
    }

    // MARK: - PEITO (Em Casa)

    private static func peitoDefaults() -> [DefaultWorkoutSeed] {
        return [

            DefaultWorkoutSeed(
                name: "PEITO_CASA",
                title: "Peito (Casa) – Flexões Progressivas",
                description: "Treino padrão em casa focado em flexões com progressões por dificuldade.",
                blocks: [
                    .init(title: "Aquecimento", text: """
• Mobilidade de punho: 30–45s
• Rotação externa de ombro: 2x12 (sem carga)
• 2x8 flexões inclinadas (mão no sofá/mesa)
""", order: 1),
                    .init(title: "Técnica", text: """
• Corpo em linha reta (glúteo e abdômen firmes)
• Cotovelos ~45° do tronco
• Controle na descida (2–3s)
""", order: 2),
                    .init(title: "Repetições", text: """
1) Flexão padrão — 4xAMRAP (deixe 1–2 reps na reserva)
2) Flexão diamante (ou fechada) — 3x8–15
3) Flexão inclinada (mais reps) — 3x12–20
4) Prancha — 3x30–60s
Descanso: 45–75s
""", order: 3)
                ]
            )
        ]
    }

    // MARK: - PERNAS (Em Casa)

    private static func pernasDefaults() -> [DefaultWorkoutSeed] {
        return [

            DefaultWorkoutSeed(
                name: "PERNAS_CASA",
                title: "Pernas (Casa) – Força Funcional",
                description: "Treino padrão sem equipamentos com foco em quadríceps, posterior e glúteos.",
                blocks: [
                    .init(title: "Aquecimento", text: """
• 2 min polichinelos ou corrida parada
• Mobilidade de quadril/tornozelo: 2 min
• 2x10 agachamentos lentos
""", order: 1),
                    .init(title: "Repetições", text: """
1) Agachamento (tempo 3-1-1) — 4x12–20
2) Avanço alternado (lunge) — 3x10–16 cada perna
3) Ponte de glúteos — 4x12–20 (pausa 1s no topo)
4) Good morning sem carga — 3x15–20
5) Panturrilha no degrau — 4x15–25
Descanso: 30–60s
""", order: 2)
                ]
            )
        ]
    }

    // MARK: - OMBROS (Em Casa)

    private static func ombrosDefaults() -> [DefaultWorkoutSeed] {
        return [

            DefaultWorkoutSeed(
                name: "OMBROS_CASA",
                title: "Ombros (Casa) – Estabilidade e Resistência",
                description: "Treino funcional focado em deltoides e estabilidade, sem necessidade de halteres.",
                blocks: [
                    .init(title: "Aquecimento", text: """
• Shoulder taps leves: 2x10
• Mobilidade de ombros: 1–2 min
• 2x20s prancha
""", order: 1),
                    .init(title: "Técnica", text: """
• Evite “afundar” na prancha
• Controle a respiração
• Ombros longe das orelhas
""", order: 2),
                    .init(title: "Repetições", text: """
1) Pike push-up (ou progressão) — 4x6–12
2) Prancha com deslocamento (frente/tras) — 3x30–45s
3) Shoulder taps — 3x20–40 reps
4) “Y-T-W” no chão — 3x8–10 cada letra
Descanso: 45–75s
""", order: 3)
                ]
            )
        ]
    }

    // MARK: - BRAÇOS (Em Casa)

    private static func bracosDefaults() -> [DefaultWorkoutSeed] {
        return [

            DefaultWorkoutSeed(
                name: "BRACOS_CASA",
                title: "Braços (Casa) – Tríceps e Bíceps Funcional",
                description: "Treino padrão para braços usando alavancas do corpo e isometrias.",
                blocks: [
                    .init(title: "Aquecimento", text: """
• Mobilidade de punhos: 30–45s
• 2x8 flexões inclinadas
• 2x10 extensão de tríceps no ar (controle)
""", order: 1),
                    .init(title: "Repetições", text: """
1) Flexão fechada — 4x8–15
2) Tríceps no banco/cadeira — 4x10–20
3) Isometria de bíceps com toalha (puxar contra o pé) — 4x20–30s
4) Prancha — 3x30–60s
Descanso: 30–60s
""", order: 2)
                ]
            )
        ]
    }

    // MARK: - CORE (Em Casa)

    private static func coreDefaults() -> [DefaultWorkoutSeed] {
        return [

            DefaultWorkoutSeed(
                name: "CORE_CASA",
                title: "Core (Casa) – Estabilidade Total",
                description: "Rotina padrão de core sem equipamentos, ideal para proteção lombar e performance.",
                blocks: [
                    .init(title: "Aquecimento", text: """
• Respiração diafragmática: 6 ciclos
• Cat-camel: 8 rep
• Dead bug leve: 6 cada lado
""", order: 1),
                    .init(title: "Técnica", text: """
• Costelas para baixo, abdômen firme
• Controle e amplitude sem perder postura
• Pare se houver dor lombar
""", order: 2),
                    .init(title: "Repetições", text: """
1) Dead Bug — 3x10 cada lado
2) Hollow hold (ou tuck) — 4x20–40s
3) Prancha lateral — 3x30–45s cada lado
4) Mountain climbers (controlado) — 3x30–45s
Descanso: 30–45s
""", order: 3)
                ]
            )
        ]
    }

    // MARK: - FULL BODY (Em Casa)

    private static func fullBodyDefaults() -> [DefaultWorkoutSeed] {
        return [

            DefaultWorkoutSeed(
                name: "FULLBODY_CASA",
                title: "Full Body (Casa) – Funcional Completo",
                description: "Treino geral sem equipamentos para o aluno treinar o corpo todo com segurança.",
                blocks: [
                    .init(title: "Aquecimento", text: """
• 2–3 min polichinelos ou corrida parada
• Mobilidade geral: 2 min
• 10 agachamentos + 10 push-ups inclinadas
""", order: 1),
                    .init(title: "Detalhes", text: "Ajuste o ritmo para manter técnica. Se necessário, diminua reps e aumente descanso.", order: 2),
                    .init(title: "Repetições", text: """
4 rounds:
• 12–20 Agachamentos
• 8–15 Flexões (adaptar: joelhos ou inclinada)
• 12–20 Avanços alternados (total)
• 20–40s Prancha
• 30–60s Descanso
""", order: 3)
                ]
            )
        ]
    }
}

