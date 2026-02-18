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

            DefaultWorkoutSeed(
                name: "COSTAS_A",
                title: "Costas A – Largura e Controle",
                description: "Treino clássico para construir dorsais (latíssimos) e melhorar estabilidade escapular.",
                blocks: [
                    .init(title: "Aquecimento", text: """
• 5 min de cardio leve (bike/esteira)
• Mobilidade torácica: 8 rotações por lado
• Ativação: 2x12 Face Pull (leve)
• 1–2 séries leves de puxada na polia
""", order: 1),
                    .init(title: "Detalhes", text: "Priorize amplitude completa e controle na fase excêntrica (descida). Pausas curtas nos acessórios.", order: 2),
                    .init(title: "Técnica", text: """
• Ombros “para baixo e para trás” antes de puxar
• Não “roubar” com lombar
• Excêntrica controlada (2–3s)
""", order: 3),
                    .init(title: "Repetições", text: """
1) Puxada na Barra (ou Pull-down) — 4x8–12
2) Remada Curvada (barra/halter) — 4x6–10
3) Remada Baixa (cabo) — 3x10–12
4) Pullover no cabo — 3x12–15
5) Face Pull — 3x12–20
Descanso: 60–90s (exercícios 1–3), 45–60s (4–5)
""", order: 4)
                ]
            ),

            DefaultWorkoutSeed(
                name: "COSTAS_B",
                title: "Costas B – Espessura e Força",
                description: "Foco em remadas pesadas e recrutamento de trapézio médio/inferior para densidade.",
                blocks: [
                    .init(title: "Aquecimento", text: """
• 5 min de cardio leve
• 2x10 Scapular Pull-ups (ou na polia)
• 2x12 Remada unilateral leve
""", order: 1),
                    .init(title: "Técnica", text: """
• Tronco firme e abdômen ativo
• Cotovelos próximos ao corpo nas remadas
• Evite encolher ombros no topo
""", order: 2),
                    .init(title: "Repetições", text: """
1) Remada Cavalinho (T-Bar) — 5x5–8
2) Barra Fixa (ou Pull-down) — 4x6–10
3) Remada Unilateral (halter) — 3x8–12 cada lado
4) Encolhimento (halter/barra) — 3x10–15
5) Extensão Lombar (máquina/banco) — 3x12–15 (controle)
Descanso: 90s (1), 60–90s (2–3), 45–60s (4–5)
""", order: 3)
                ]
            )
        ]
    }

    // MARK: - PEITO

    private static func peitoDefaults() -> [DefaultWorkoutSeed] {
        return [

            DefaultWorkoutSeed(
                name: "PEITO_A",
                title: "Peito A – Base de Força",
                description: "Treino padrão para evolução do supino e construção de peitoral com volume controlado.",
                blocks: [
                    .init(title: "Aquecimento", text: """
• 5 min cardio leve
• Mobilidade de ombros/peitoral (porta): 30s por lado
• 2x12 Rotação externa (elástico) leve
• 2 séries progressivas de supino (leve)
""", order: 1),
                    .init(title: "Detalhes", text: "Mantenha escápulas estabilizadas e evite perder postura no supino. Aumente carga só com técnica perfeita.", order: 2),
                    .init(title: "Técnica", text: """
• Escápulas “encaixadas” no banco
• Pés firmes no chão
• Barra desce controlada até a linha do peito
""", order: 3),
                    .init(title: "Repetições", text: """
1) Supino Reto (barra) — 5x5–8
2) Supino Inclinado (halter) — 4x8–12
3) Crucifixo (máquina/halter) — 3x10–15
4) Paralelas (ou mergulho assistido) — 3x6–12
5) Tríceps na polia — 3x10–15
Descanso: 90s (1), 60–90s (2), 45–60s (3–5)
""", order: 4)
                ]
            ),

            DefaultWorkoutSeed(
                name: "PEITO_B",
                title: "Peito B – Hipertrofia e Pump",
                description: "Sessão clássica de academia com mais volume e repetições para estímulo metabólico.",
                blocks: [
                    .init(title: "Aquecimento", text: """
• 5 min de cardio leve
• 2x15 Push-ups (adaptar se necessário)
• 1–2 séries leves de máquina peck-deck
""", order: 1),
                    .init(title: "Técnica", text: """
• Controle a excêntrica (2–3s)
• Cotovelos sem “abrir demais”
• Não hiperestender lombar no inclinado
""", order: 2),
                    .init(title: "Repetições", text: """
1) Supino Inclinado (barra/halter) — 4x8–12
2) Supino Reto (halter) — 4x10–12
3) Peck-deck — 3x12–15
4) Crossover no cabo — 3x12–20
5) Flexão até perto da falha — 2 séries
Descanso: 45–75s
""", order: 3)
                ]
            )
        ]
    }

    // MARK: - PERNAS

    private static func pernasDefaults() -> [DefaultWorkoutSeed] {
        return [

            DefaultWorkoutSeed(
                name: "PERNAS_A",
                title: "Pernas A – Quadríceps e Base",
                description: "Treino padrão com agachamento e acessórios clássicos para pernas fortes e estáveis.",
                blocks: [
                    .init(title: "Aquecimento", text: """
• 5–8 min bike
• Mobilidade: tornozelo (8–10 rep), quadril (8 rep)
• 2x12 Agachamento com peso corporal
• 2 séries progressivas do exercício principal
""", order: 1),
                    .init(title: "Técnica", text: """
• Joelho acompanha a linha do pé
• Tronco firme e abdômen ativo
• Descida controlada, suba com potência
""", order: 2),
                    .init(title: "Repetições", text: """
1) Agachamento Livre — 5x5–8
2) Leg Press — 4x10–12
3) Cadeira Extensora — 3x12–15
4) Passada (halter) — 3x10 cada perna
5) Panturrilha em pé — 4x12–20
Descanso: 90s (1), 60–90s (2), 45–60s (3–5)
""", order: 3)
                ]
            ),

            DefaultWorkoutSeed(
                name: "PERNAS_B",
                title: "Pernas B – Posterior e Glúteos",
                description: "Treino padrão para fortalecer posterior de coxa e glúteos com padrões de hinge.",
                blocks: [
                    .init(title: "Aquecimento", text: """
• 5–8 min bike leve
• 2x12 Ponte de glúteos
• 2x10 Good morning (leve)
• 1–2 séries leves do exercício principal
""", order: 1),
                    .init(title: "Técnica", text: """
• Coluna neutra no hinge (RDL/terra)
• Sinta alongar posterior, sem “roubar”
• Contraia glúteo no topo
""", order: 2),
                    .init(title: "Repetições", text: """
1) Levantamento Terra Romeno — 4x6–10
2) Mesa Flexora — 4x10–12
3) Hip Thrust — 4x8–12
4) Afundo (búlgaro) — 3x8–10 cada perna
5) Panturrilha sentado — 4x12–20
Descanso: 60–90s
""", order: 3)
                ]
            )
        ]
    }

    // MARK: - OMBROS

    private static func ombrosDefaults() -> [DefaultWorkoutSeed] {
        return [

            DefaultWorkoutSeed(
                name: "OMBROS_PADRAO",
                title: "Ombros – Deltoides Completos",
                description: "Treino padrão para deltoide anterior/lateral/posterior com estabilidade e saúde do ombro.",
                blocks: [
                    .init(title: "Aquecimento", text: """
• Mobilidade de ombro (círculos): 10 para cada lado
• 2x12 Rotação externa (elástico) leve
• 2x12 Elevação lateral leve
""", order: 1),
                    .init(title: "Técnica", text: """
• Evite elevar ombros (trapézio) nas laterais
• Controle e amplitude sem dor
• Priorize deltoide posterior para equilíbrio
""", order: 2),
                    .init(title: "Repetições", text: """
1) Desenvolvimento (halter/barra) — 4x6–10
2) Elevação Lateral — 4x12–15
3) Elevação Frontal (halter) — 3x10–12
4) Crucifixo Inverso (máquina/cabo) — 4x12–20
5) Face Pull — 3x12–20
Descanso: 45–75s
""", order: 3)
                ]
            )
        ]
    }

    // MARK: - BRAÇOS

    private static func bracosDefaults() -> [DefaultWorkoutSeed] {
        return [

            DefaultWorkoutSeed(
                name: "BRACOS_PADRAO",
                title: "Braços – Bíceps e Tríceps",
                description: "Treino clássico para hipertrofia com superséries (padrão de academia).",
                blocks: [
                    .init(title: "Aquecimento", text: """
• 3–5 min de cardio leve
• 2x15 Rosca direta (muito leve)
• 2x15 Tríceps polia (muito leve)
""", order: 1),
                    .init(title: "Detalhes", text: "Faça superséries (A1 + A2) para aumentar densidade do treino. Foque em execução perfeita.", order: 2),
                    .init(title: "Repetições", text: """
A1) Rosca Direta (barra) — 4x8–12
A2) Tríceps na Polia (barra reta) — 4x10–15

B1) Rosca Alternada (halter) — 3x10–12
B2) Tríceps Francês (halter) — 3x10–12

C1) Rosca Martelo — 3x10–12
C2) Mergulho no banco — 3xAMRAP (técnica boa)
Descanso: 45–60s entre superséries
""", order: 3)
                ]
            )
        ]
    }

    // MARK: - CORE

    private static func coreDefaults() -> [DefaultWorkoutSeed] {
        return [

            DefaultWorkoutSeed(
                name: "CORE_ESTABILIDADE",
                title: "Core – Estabilidade e Proteção Lombar",
                description: "Rotina padrão para fortalecer core sem excesso de flexão de coluna, focando estabilidade.",
                blocks: [
                    .init(title: "Aquecimento", text: """
• Respiração diafragmática: 6–8 ciclos
• Cat-camel: 8 rep
• Prancha leve: 20–30s
""", order: 1),
                    .init(title: "Técnica", text: """
• Costelas “para baixo”, abdômen ativo
• Coluna neutra (evite hiperextensão)
• Controle total, sem pressa
""", order: 2),
                    .init(title: "Repetições", text: """
1) Prancha — 3x30–60s
2) Dead Bug — 3x10 cada lado
3) Pallof Press (cabo/elástico) — 3x12 cada lado
4) Prancha lateral — 3x30–45s cada lado
5) Farmer Carry (se houver halter) — 4x20–40m
Descanso: 30–45s
""", order: 3)
                ]
            )
        ]
    }

    // MARK: - FULL BODY

    private static func fullBodyDefaults() -> [DefaultWorkoutSeed] {
        return [

            DefaultWorkoutSeed(
                name: "FULLBODY_ACADEMIA",
                title: "Full Body – Padrão de Academia",
                description: "Treino completo com básicos para quem precisa de um treino geral bem equilibrado.",
                blocks: [
                    .init(title: "Aquecimento", text: """
• 5–8 min cardio leve
• Mobilidade: quadril/tornozelo/ombro (3–5 min)
• 1 série leve de cada exercício principal
""", order: 1),
                    .init(title: "Repetições", text: """
1) Agachamento (livre ou smith) — 4x6–10
2) Supino (barra/halter) — 4x6–10
3) Remada (cabo/halter) — 4x8–12
4) Desenvolvimento (halter) — 3x8–12
5) Panturrilha — 3x12–20
6) Core (prancha) — 3x30–60s
Descanso: 60–90s
""", order: 2)
                ]
            )
        ]
    }
}

