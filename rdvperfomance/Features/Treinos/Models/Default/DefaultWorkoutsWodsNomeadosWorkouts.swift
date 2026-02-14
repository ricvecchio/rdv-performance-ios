import Foundation

extension DefaultWorkoutsCrossfit {

    static func wodsNomeadosDefaults() -> [DefaultWorkoutSeed] {
        return [

            // MARK: - FILTHY FIFTY (2005)
            DefaultWorkoutSeed(
                name: "FILTHY FIFTY (2005)",
                title: "Filthy Fifty – Resistência Total de Corpo Inteiro",
                description: "Benchmark de altíssimo volume que testa resistência muscular, capacidade respiratória e força sob fadiga acumulada.",
                blocks: [
                    .init(title: "Aquecimento", text: """
3 rounds leves:
• 10 Air Squats
• 10 Jumping Pull-ups
• 10 Kettlebell Swings leves
Mobilidade de ombros e quadril
5 Burpees + 5 Box Jumps progressivos
""", order: 1),
                    .init(title: "Detalhes", text: "Treino contínuo. Alto volume exige estratégia de divisão desde o início.", order: 2),
                    .init(title: "Técnica", text: """
• Movimentos eficientes e ritmo constante
• Evitar falha muscular precoce
• Transições rápidas
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 50 Box Jumps (24/20”)
• 50 Jumping Pull-ups
• 50 Kettlebell Swings (16/12 kg)
• 50 Walking Lunges
• 50 Knees-to-Elbows
• 50 Push Press (45/35 lb)
• 50 Back Extensions
• 50 Wall Balls (20/14 lb)
• 50 Burpees
• 50 Double-Unders
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: 30 reps de cada
• Scale: Cargas reduzidas / singles
• RX: Prescrito
""", order: 5)
                ]
            ),

            // MARK: - FIGHT GONE BAD (2006)
            DefaultWorkoutSeed(
                name: "FIGHT GONE BAD (2006)",
                title: "Fight Gone Bad – Potência Sob Intervalo",
                description: "Treino intervalado inspirado em rounds de MMA. Foco em potência e consistência sob fadiga.",
                blocks: [
                    .init(title: "Aquecimento", text: """
500 m remo leve
• 10 Wall Balls leves
• 10 Push Presses leves
• 10 Box Step-ups
""", order: 1),
                    .init(title: "Detalhes", text: "Pontuação é total de repetições.", order: 2),
                    .init(title: "Técnica", text: """
• Movimento contínuo
• Trocas rápidas de estação
• Respiração controlada
""", order: 3),
                    .init(title: "WOD", text: """
3 rounds – 1 min por estação:
• Wall Ball (20/14 lb)
• Sumo Deadlift High Pull (75/55 lb)
• Box Jump (20”)
• Push Press (75/55 lb)
• Row (calorias)
• 1 min descanso
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: 2 rounds
• Scale: Carga leve
• RX: Prescrito
""", order: 5)
                ]
            ),

            // MARK: - NATE (2007)
            DefaultWorkoutSeed(
                name: "NATE (2007)",
                title: "Nate – Ginástica e Potência Unilateral",
                description: "Treino técnico de ginástica e estabilidade de ombro.",
                blocks: [
                    .init(title: "Aquecimento", text: """
3 rounds:
• 5 Strict HSPU progressivos
• 10 Swings leves
• 5 Pull-ups
""", order: 1),
                    .init(title: "Detalhes", text: "Controle corporal é determinante.", order: 2),
                    .init(title: "Técnica", text: """
• Core ativo nas HSPU
• Swings explosivos
• Pull-ups eficientes
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 20 min:
• 2 Ring Muscle-ups
• 4 Handstand Push-ups
• 8 Kettlebell Swings (32/24 kg)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: Jumping MU / Pike push-up
• Scale: KB moderado
• RX: Prescrito
""", order: 5)
                ]
            ),

            // MARK: - LYNNE (2008)
            DefaultWorkoutSeed(
                name: "LYNNE (2008)",
                title: "Lynne – Força Máxima em Volume",
                description: "Benchmark de força combinada com peso corporal.",
                blocks: [
                    .init(title: "Aquecimento", text: """
3 séries progressivas de Bench Press
5 Pull-ups estritos leves
""", order: 1),
                    .init(title: "Detalhes", text: "Sem limite de tempo. Prioriza força.", order: 2),
                    .init(title: "Técnica", text: """
• Bench com escápulas retraídas
• Pull-ups completas
""", order: 3),
                    .init(title: "WOD", text: """
5 rounds for max reps:
• Bodyweight Bench Press
• Pull-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: 70% peso corporal
• Scale: Carga adaptada
• RX: Peso corporal
""", order: 5)
                ]
            ),

            // MARK: - HELEN (2008)
            DefaultWorkoutSeed(
                name: "HELEN (2008)",
                title: "Helen – Sprint Aeróbico Clássico",
                description: "Benchmark rápido que combina corrida e potência.",
                blocks: [
                    .init(title: "Aquecimento", text: """
400 m leve
• 10 Swings leves
• 5 Pull-ups
""", order: 1),
                    .init(title: "Detalhes", text: "Treino rápido e intenso.", order: 2),
                    .init(title: "Técnica", text: """
• Corrida eficiente
• Swings explosivos
• Pull-ups contínuas
""", order: 3),
                    .init(title: "WOD", text: """
3 rounds for time:
• 400 m Run
• 21 KB Swings (24/16 kg)
• 12 Pull-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: 200 m
• Scale: KB leve
• RX: Prescrito
""", order: 5)
                ]
            ),

            // MARK: - JACKIE (2009)
            DefaultWorkoutSeed(
                name: "JACKIE (2009)",
                title: "Jackie – Potência e Resistência",
                description: "Benchmark simples e intenso com três movimentos clássicos.",
                blocks: [
                    .init(title: "Aquecimento", text: """
500 m remo leve
• 10 Thrusters leves
• 5 Pull-ups
""", order: 1),
                    .init(title: "Detalhes", text: "Movimentos devem fluir sem pausas longas.", order: 2),
                    .init(title: "Técnica", text: """
• Thruster contínuo
• Pull-ups eficientes
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 1000 m Row
• 50 Thrusters (45/35 lb)
• 30 Pull-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: 750 m
• Scale: Carga leve
• RX: Prescrito
""", order: 5)
                ]
            ),

            // MARK: - KAREN (2009)
            DefaultWorkoutSeed(
                name: "KAREN (2009)",
                title: "Karen – Volume Mental de Wall Ball",
                description: "Benchmark simples que testa resistência muscular e foco mental.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de quadril
20 Wall Balls leves
""", order: 1),
                    .init(title: "Detalhes", text: "Divisão estratégica é essencial.", order: 2),
                    .init(title: "Técnica", text: """
• Agachamento completo
• Alvo consistente
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 150 Wall Balls (20/14 lb)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: 90 reps
• Scale: Bola leve
• RX: Prescrito
""", order: 5)
                ]
            ),

            // MARK: - EVA (2010)
            DefaultWorkoutSeed(
                name: "EVA (2010)",
                title: "Eva – Endurance Longo",
                description: "Benchmark longo com foco em resistência aeróbica e pegada.",
                blocks: [
                    .init(title: "Aquecimento", text: """
400 m leve
• 10 Swings leves
• 5 Pull-ups
""", order: 1),
                    .init(title: "Detalhes", text: "Treino longo exige ritmo sustentável.", order: 2),
                    .init(title: "Técnica", text: """
• Swings consistentes
• Pull-ups eficientes
""", order: 3),
                    .init(title: "WOD", text: """
5 rounds for time:
• 800 m Run
• 30 KB Swings (32/24 kg)
• 30 Pull-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: 400 m
• Scale: KB leve
• RX: Prescrito
""", order: 5)
                ]
            ),

            // MARK: - DT (2010)
            DefaultWorkoutSeed(
                name: "DT (2010)",
                title: "DT – Complexo de Barra Sob Fadiga",
                description: "Benchmark de levantamento olímpico em rounds curtos e intensos.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Técnica de Deadlift e Clean
2 rounds leves do complexo
""", order: 1),
                    .init(title: "Detalhes", text: "Divisão estratégica do clean & jerk.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift sólido
• Transição rápida para Hang Clean
• Jerk eficiente
""", order: 3),
                    .init(title: "WOD", text: """
5 rounds for time:
• 12 Deadlifts (155/105 lb)
• 9 Hang Power Cleans
• 6 Push Jerks
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: 95/65 lb
• Scale: Carga moderada
• RX: Prescrito
""", order: 5)
                ]
            )

        ]
    }
}

