import Foundation

extension DefaultWorkoutsCrossfit {

    static func girlsWodsDefaults() -> [DefaultWorkoutSeed] {
        return [

            // MARK: - CHELSEA
            DefaultWorkoutSeed(
                name: "CHELSEA",
                title: "Chelsea – Consistência Sob Pressão",
                description: "Benchmark em formato EMOM que exige disciplina, eficiência e resistência progressiva.",
                blocks: [
                    .init(title: "Aquecimento", text: """
EMOM leve de 5 min:
• 3 Pull-ups
• 6 Push-ups
• 9 Squats
Mobilidade de ombros
""", order: 1),
                    .init(title: "Detalhes", text: "O atleta deve completar as reps dentro do minuto. Quando não consegue, o treino termina.", order: 2),
                    .init(title: "Técnica", text: """
• Movimentos rápidos e econômicos
• Transições imediatas
""", order: 3),
                    .init(title: "WOD", text: """
EMOM 30 min:
• 5 Pull-ups
• 10 Push-ups
• 15 Air Squats
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: EMOM 15–20 min
• Scale: Pull-ups com elástico
• RX: Prescrito
""", order: 5)
                ]
            ),

            // MARK: - DIANE
            DefaultWorkoutSeed(
                name: "DIANE",
                title: "Diane – Força e Ginástica",
                description: "Benchmark intenso que combina levantamento pesado e ginástica invertida sob fadiga.",
                blocks: [
                    .init(title: "Aquecimento", text: """
• Deadlift leve progressivo
• Progressões de handstand push-up
""", order: 1),
                    .init(title: "Detalhes", text: "Treino curto e agressivo. Técnica é essencial para segurança.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift com coluna neutra
• HSPU com linha corporal estável
""", order: 3),
                    .init(title: "WOD", text: """
21–15–9:
• Deadlift (102 kg / 70 kg)
• Handstand Push-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: Deadlift leve / pike push-ups
• Scale: Deadlift moderado / HSPU com abmat
• RX: Prescrito
""", order: 5)
                ]
            ),

            // MARK: - ELIZABETH
            DefaultWorkoutSeed(
                name: "ELIZABETH",
                title: "Elizabeth – Potência e Controle",
                description: "Benchmark clássico de força explosiva e controle corporal em argolas.",
                blocks: [
                    .init(title: "Aquecimento", text: """
• Técnica de clean
• Dips em argola assistidos
""", order: 1),
                    .init(title: "Detalhes", text: "Transições rápidas e domínio técnico fazem a diferença.", order: 2),
                    .init(title: "Técnica", text: """
• Clean eficiente e próximo ao corpo
• Ring dips com ombros estáveis
""", order: 3),
                    .init(title: "WOD", text: """
21–15–9:
• Clean (61 kg / 43 kg)
• Ring Dips
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: Power clean leve / dips em banco
• Scale: Clean moderado / ring dips com elástico
• RX: Prescrito
""", order: 5)
                ]
            ),

            // MARK: - FRAN
            DefaultWorkoutSeed(
                name: "FRAN",
                title: "Fran – Velocidade Máxima",
                description: "Um dos benchmarks mais icônicos do CrossFit, medindo potência, velocidade e resistência mental.",
                blocks: [
                    .init(title: "Aquecimento", text: """
• Técnica de thruster
• Pull-ups em séries curtas
""", order: 1),
                    .init(title: "Detalhes", text: "Treino curto e extremamente intenso. Pacing é decisivo.", order: 2),
                    .init(title: "Técnica", text: """
• Thruster fluido e explosivo
• Pull-ups eficientes (kipping ou butterfly)
""", order: 3),
                    .init(title: "WOD", text: """
21–15–9:
• Thrusters (43 kg / 30 kg)
• Pull-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: Thruster leve / ring rows
• Scale: Thruster moderado / pull-ups com elástico
• RX: Prescrito
""", order: 5)
                ]
            ),

            // MARK: - GRACE
            DefaultWorkoutSeed(
                name: "GRACE",
                title: "Grace – Potência Pura",
                description: "Benchmark simples e brutal, focado em força explosiva e resistência anaeróbica.",
                blocks: [
                    .init(title: "Aquecimento", text: "• Progressão técnica de clean & jerk", order: 1),
                    .init(title: "Detalhes", text: "Treino contínuo, com foco em execução segura e eficiente.", order: 2),
                    .init(title: "Técnica", text: """
• Barra próxima ao corpo
• Jerk estável e rápido
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 30 Clean & Jerks (61 kg / 43 kg)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: Clean & press leve
• Scale: Clean & jerk moderado
• RX: Prescrito
""", order: 5)
                ]
            ),

            // MARK: - HELEN
            DefaultWorkoutSeed(
                name: "HELEN",
                title: "Helen – Clássico Metabólico",
                description: "Benchmark equilibrado entre corrida, kettlebell e ginástica.",
                blocks: [
                    .init(title: "Aquecimento", text: """
• Corrida leve
• Kettlebell swings técnicos
""", order: 1),
                    .init(title: "Detalhes", text: "Ritmo consistente é mais importante que explosões isoladas.", order: 2),
                    .init(title: "Técnica", text: """
• Swing russo ou americano conforme prescrito
• Pull-ups eficientes
""", order: 3),
                    .init(title: "WOD", text: """
3 rounds:
• 400 m run
• 21 Kettlebell Swings (24 kg / 16 kg)
• 12 Pull-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: KB leve / ring rows
• Scale: KB moderado / pull-ups com elástico
• RX: Prescrito
""", order: 5)
                ]
            ),

            // MARK: - ISABEL
            DefaultWorkoutSeed(
                name: "ISABEL",
                title: "Isabel – Velocidade Olímpica",
                description: "Benchmark focado em levantamento olímpico sob alta intensidade.",
                blocks: [
                    .init(title: "Aquecimento", text: """
• Técnica de snatch
• Mobilidade de ombros
""", order: 1),
                    .init(title: "Detalhes", text: "Velocidade com controle técnico.", order: 2),
                    .init(title: "Técnica", text: "• Snatch eficiente e fluido", order: 3),
                    .init(title: "WOD", text: """
For time:
• 30 Snatches (61 kg / 43 kg)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: Power snatch leve
• Scale: Snatch moderado
• RX: Prescrito
""", order: 5)
                ]
            ),

            // MARK: - JACKIE
            DefaultWorkoutSeed(
                name: "JACKIE",
                title: "Jackie – Capacidade Aeróbica",
                description: "Benchmark que testa endurance e resistência sob fadiga acumulada.",
                blocks: [
                    .init(title: "Aquecimento", text: """
• Remo leve
• Thrusters com PVC
""", order: 1),
                    .init(title: "Detalhes", text: "Sequência contínua, sem pausas obrigatórias.", order: 2),
                    .init(title: "Técnica", text: """
• Remada eficiente
• Thruster econômico
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 1.000 m row
• 50 Thrusters (20 kg / 15 kg)
• 30 Pull-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: 500 m row / thruster leve
• Scale: Thruster moderado / pull-ups com elástico
• RX: Prescrito
""", order: 5)
                ]
            ),

            // MARK: - KAREN
            DefaultWorkoutSeed(
                name: "KAREN",
                title: "Karen – Resistência Mental",
                description: "Benchmark simples e desgastante, focado em volume extremo.",
                blocks: [
                    .init(title: "Aquecimento", text: "• Wall balls progressivos", order: 1),
                    .init(title: "Detalhes", text: "Treino contínuo, exigindo foco e controle de respiração.", order: 2),
                    .init(title: "Técnica", text: """
• Profundidade correta do agachamento
• Alvo consistente
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 150 Wall Balls (9 kg / 6 kg)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: Bola leve / menos reps
• Scale: Bola moderada
• RX: Prescrito
""", order: 5)
                ]
            ),

            // MARK: - LINDA
            DefaultWorkoutSeed(
                name: "LINDA",
                title: "Linda – Three Bars of Death",
                description: "Benchmark clássico de força absoluta e resistência progressiva.",
                blocks: [
                    .init(title: "Aquecimento", text: "• Progressão de carga nos três movimentos", order: 1),
                    .init(title: "Detalhes", text: "Carga relativa ao peso corporal. Descanso conforme necessidade.", order: 2),
                    .init(title: "Técnica", text: "• Execução perfeita em todos os levantamentos", order: 3),
                    .init(title: "WOD", text: """
10–9–8–7–6–5–4–3–2–1:
• Deadlift (1.5× bodyweight)
• Bench Press (bodyweight)
• Clean (0.75× bodyweight)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: Cargas reduzidas
• Scale: Percentuais menores
• RX: Prescrito
""", order: 5)
                ]
            ),

            // MARK: - LYNNE
            DefaultWorkoutSeed(
                name: "LYNNE",
                title: "Lynne – Força Máxima",
                description: "Benchmark de força pura, sem limite de tempo.",
                blocks: [
                    .init(title: "Aquecimento", text: "• Aquecimento específico de bench press", order: 1),
                    .init(title: "Detalhes", text: "Foco em máxima repetição por round.", order: 2),
                    .init(title: "Técnica", text: """
• Bench press controlado
• Pull-ups estritas ou kipping
""", order: 3),
                    .init(title: "WOD", text: """
5 rounds:
• Max reps Bench Press (bodyweight)
• Max reps Pull-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: Bench leve
• Scale: Pull-ups com elástico
• RX: Prescrito
""", order: 5)
                ]
            ),

            // MARK: - MARY
            DefaultWorkoutSeed(
                name: "MARY",
                title: "Mary – Ginástica Avançada",
                description: "Benchmark avançado de controle corporal e resistência.",
                blocks: [
                    .init(title: "Aquecimento", text: "• Progressões de HSPU e pistols", order: 1),
                    .init(title: "Detalhes", text: "Alto nível técnico exigido.", order: 2),
                    .init(title: "Técnica", text: "• Controle total do core", order: 3),
                    .init(title: "WOD", text: """
AMRAP 20 min:
• 5 Handstand Push-ups
• 10 Pistols
• 15 Pull-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: Pike push-ups / air squats
• Scale: Pistols assistidos
• RX: Prescrito
""", order: 5)
                ]
            ),

            // MARK: - NANCY
            DefaultWorkoutSeed(
                name: "NANCY",
                title: "Nancy – Resistência com Técnica",
                description: "Benchmark que combina corrida e agachamento olímpico.",
                blocks: [
                    .init(title: "Aquecimento", text: """
• Corrida leve
• OHS com PVC
""", order: 1),
                    .init(title: "Detalhes", text: "Ritmo consistente do início ao fim.", order: 2),
                    .init(title: "Técnica", text: "• Overhead squat estável", order: 3),
                    .init(title: "WOD", text: """
5 rounds:
• 400 m run
• 15 Overhead Squats (43 kg / 30 kg)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: OHS leve
• Scale: OHS moderado
• RX: Prescrito
""", order: 5)
                ]
            ),

            // MARK: - ANNIE
            DefaultWorkoutSeed(
                name: "ANNIE",
                title: "Annie – Coordenação e Core",
                description: "Benchmark rápido focado em core e coordenação.",
                blocks: [
                    .init(title: "Aquecimento", text: """
• Double unders leves
• Sit-ups controlados
""", order: 1),
                    .init(title: "Detalhes", text: "Treino rápido, ideal para alta intensidade.", order: 2),
                    .init(title: "Técnica", text: "• Double unders relaxados", order: 3),
                    .init(title: "WOD", text: """
50–40–30–20–10:
• Double Unders
• Sit-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: Single unders
• Scale: Double unders reduzidos
• RX: Prescrito
""", order: 5)
                ]
            ),

            // MARK: - CINDY
            DefaultWorkoutSeed(
                name: "CINDY",
                title: "Cindy – AMRAP icônico para capacidade aeróbica",
                description: "AMRAP icônico para capacidade aeróbica.",
                blocks: [
                    .init(title: "Aquecimento", text: "EMOM leve de movimentos do WOD.", order: 1),
                    .init(title: "Técnica", text: "Boa postura e transições rápidas.", order: 2),
                    .init(title: "WOD", text: """
AMRAP 20 min:
5 Pull-ups
10 Push-ups
15 Squats
""", order: 3),
                    .init(title: "Cargas / Movimentos", text: """
Iniciante: Ring rows / joelhos no chão
Scale: Pull-ups assistidos
RX: Prescrito
""", order: 4)
                ]
            ),

            // MARK: - ANGIE
            DefaultWorkoutSeed(
                name: "ANGIE",
                title: "Angie – Clássico de Volume Corporal",
                description: "Um benchmark puro de resistência muscular e capacidade mental.",
                blocks: [
                    .init(title: "Aquecimento", text: """
3 rounds leves:
- 10 air squats
- 10 sit-ups
- 5 pull-ups
Mobilidade de ombros e quadril
""", order: 1),
                    .init(title: "Detalhes", text: "Treino contínuo, sem divisão obrigatória de séries.", order: 2),
                    .init(title: "Técnica", text: """
Pull-ups com escápulas ativas
Push-ups com core firme
Squats completos
""", order: 3),
                    .init(title: "WOD", text: """
For time:
100 Pull-ups
100 Push-ups
100 Sit-ups
100 Squats
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
Iniciante: 50 reps de cada / ring rows
Scale: 75 reps / pull-ups com elástico
RX: Conforme prescrito
""", order: 5)
                ]
            ),

            // MARK: - BARBARA
            DefaultWorkoutSeed(
                name: "BARBARA",
                title: "Barbara – Resistência Intervalada",
                description: "Benchmark de volume e recuperação ativa.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Corrida leve + mobilidade
1 round reduzido do WOD
""", order: 1),
                    .init(title: "Detalhes", text: "Descanso obrigatório de 3 minutos entre rounds.", order: 2),
                    .init(title: "Técnica", text: "Controle respiratório e pacing.", order: 3),
                    .init(title: "WOD", text: """
5 rounds, each for time of:
20 Pull-ups
30 Push-ups
40 Sit-ups
50 Squats

Rest 3 min entre rounds
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
Iniciante: Metade das reps
Scale: Pull-ups com elástico
RX: Prescrito
""", order: 5)
                ]
            )
        ]
    }
}
