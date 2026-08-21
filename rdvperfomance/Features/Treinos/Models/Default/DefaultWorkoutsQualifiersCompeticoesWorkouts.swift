import Foundation

extension DefaultWorkoutsCrossfit {

    static func qualifiersCompeticoesDefaults() -> [DefaultWorkoutSeed] {
        return [

            // MARK: - 2009 - THE RANCH TRAIL RUN
            DefaultWorkoutSeed(
                name: "THE RANCH TRAIL RUN",
                title: "The Ranch Trail Run – Resistência em Terreno Natural",
                description: "Corrida em trilha irregular realizada no Rancho Aromas, exigindo resistência aeróbica e adaptação ao terreno.",
                blocks: [
                    .init(title: "Aquecimento", text: """
800 m corrida leve
Mobilidade de tornozelo e quadril
3 acelerações progressivas
""", order: 1),
                    .init(title: "Detalhes", text: "Percurso em trilha com subidas e descidas. Gestão de ritmo é essencial.", order: 2),
                    .init(title: "Técnica", text: """
• Passadas curtas em subida
• Postura levemente inclinada
• Respiração nasal controlada
""", order: 3),
                    .init(title: "WOD", text: """
• 7 km Trail Run
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: 3–5 km
• Scale: 5 km
• RX: 7 km
• Elite: ritmo competitivo abaixo de 30 min
""", order: 5)
                ]
            ),

            // MARK: - 2010 - THE TRIPLET
            DefaultWorkoutSeed(
                name: "THE TRIPLET",
                title: "The Triplet – Volume Olímpico + Ginástico",
                description: "Evento clássico das finais com combinação de levantamento olímpico e ginástica.",
                blocks: [
                    .init(title: "Aquecimento", text: """
5 min remo leve
Técnica de muscle-up
Progressão de squat clean leve
""", order: 1),
                    .init(title: "Detalhes", text: "Alto volume de muscle-ups sob fadiga metabólica.", order: 2),
                    .init(title: "Técnica", text: """
• Clean com recepção sólida
• Muscle-up eficiente sem swings excessivos
• Transições rápidas
""", order: 3),
                    .init(title: "WOD", text: """
4 rounds for time:
• 800 m Run
• 30 GHD Sit-ups
• 30 Double-Unders
• 15 Squat Cleans (155/105 lb)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: Hanging knee raises / 95 lb
• Scale: 115/75 lb
• RX: 155/105 lb
• Elite: unbroken muscle-ups
""", order: 5)
                ]
            ),

            // MARK: - 2011 - THE CLEAN LADDER
            DefaultWorkoutSeed(
                name: "THE CLEAN LADDER",
                title: "The Clean Ladder – Força Máxima Sob Pressão",
                description: "Ladder crescente de clean até falha.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de tornozelo
5 séries progressivas de clean
""", order: 1),
                    .init(title: "Detalhes", text: "3 tentativas por carga.", order: 2),
                    .init(title: "Técnica", text: """
• Barra próxima ao corpo
• Explosão de quadril
• Recepção estável
""", order: 3),
                    .init(title: "WOD", text: """
Ladder de Clean:
• 225 lb
• 245 lb
• 265 lb
• 285 lb
• 305 lb
(até falha)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: ladder até 60% RM
• Scale: até 80%
• RX: conforme prescrito
""", order: 5)
                ]
            ),

            // MARK: - 2012 – REGIONALS - REGIONAL DIANE
            DefaultWorkoutSeed(
                name: "REGIONAL DIANE",
                title: "Regional Diane – Potência e Ginástica Sob Fadiga",
                description: "Versão pesada e competitiva do clássico Diane, utilizada nos Regionals 2012.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de posterior e ombros
Deadlifts progressivos
Handstand hold 3x20s
""", order: 1),
                    .init(title: "Detalhes", text: "Deadlifts pesados exigem gerenciamento de grip antes dos HSPU.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift com barra próxima ao corpo
• HSPU com controle de core
• Evitar falha muscular precoce
""", order: 3),
                    .init(title: "WOD", text: """
21-15-9:
• Deadlift (315/205 lb)
• Handstand Push-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: 155/105 lb + pike push-up
• Scale: 225/155 lb
• RX: Prescrito
""", order: 5)
                ]
            ),

            // MARK: - 2013 - JACKIE PRO
            DefaultWorkoutSeed(
                name: "JACKIE PRO",
                title: "Jackie Pro – Sprint Metabólico Avançado",
                description: "Versão competitiva do clássico Jackie.",
                blocks: [
                    .init(title: "Aquecimento", text: """
500 m remo leve
Thrusters leves
Pull-ups técnicos
""", order: 1),
                    .init(title: "Detalhes", text: "Transições determinam o resultado.", order: 2),
                    .init(title: "Técnica", text: """
• Thruster contínuo
• Pull-ups butterfly eficientes
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 1000 m Row
• 50 Thrusters (45 kg / 35 kg)
• 30 Bar Muscle-Ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: Pull-ups
• Scale: 35 kg
• RX: conforme prescrito
""", order: 5)
                ]
            ),

            // MARK: - 2013 – REGIONALS - LEGLESS
            DefaultWorkoutSeed(
                name: "LEGLESS",
                title: "Legless – Ginástica Pura de Alto Risco",
                description: "Evento que popularizou o legless rope climb nas competições.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Rope climb técnico
Pull-ups strict
Core activation
""", order: 1),
                    .init(title: "Detalhes", text: "Grip e eficiência no rope climb são decisivos.", order: 2),
                    .init(title: "Técnica", text: """
• Uso mínimo das pernas
• Travamento eficiente do antebraço
• Controle na descida
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 10 Legless Rope Climbs
• 60-ft Handstand Walk
• 20 Legless Rope Climbs
• 120-ft Handstand Walk
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: rope assistido
• Scale: rope com uso de pernas
• RX: Prescrito
""", order: 5)
                ]
            ),

            // MARK: - 2014 – REGIONALS - REGIONAL COMPLEX
            DefaultWorkoutSeed(
                name: "REGIONAL COMPLEX",
                title: "Regional Complex – Força Técnica Regional",
                description: "Complexo olímpico crescente executado sem soltar a barra.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Técnica de clean & jerk
Complexos leves com PVC
""", order: 1),
                    .init(title: "Detalhes", text: "Carga aumenta progressivamente.", order: 2),
                    .init(title: "Técnica", text: """
• Recepção sólida
• Transição fluida entre movimentos
• Core ativo
""", order: 3),
                    .init(title: "WOD", text: """
Complexo:
• 1 Snatch
• 1 Hang Snatch
• 1 Overhead Squat
• 1 Clean
• 1 Hang Clean
• 1 Jerk
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: técnica leve
• Scale: 60–70%
• RX: carga máxima possível
""", order: 5)
                ]
            ),

            // MARK: - 2015 - MURPH SPRINT (GAMES VARIATION)
            DefaultWorkoutSeed(
                name: "MURPH SPRINT",
                title: "Murph Sprint – Volume Fragmentado Competitivo",
                description: "Versão estratégica em heats curtos.",
                blocks: [
                    .init(title: "Aquecimento", text: """
800 m corrida
Pull-ups leves
Squats leves
""", order: 1),
                    .init(title: "Detalhes", text: "Divisão estratégica é fundamental.", order: 2),
                    .init(title: "Técnica", text: """
• Pull-ups em séries curtas
• Ritmo constante
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 1 mile run
• 100 Pull-ups
• 200 Push-ups
• 300 Squats
• 1 mile run
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: meia Murph
• Scale: colete opcional
• RX: com colete 20 lb
""", order: 5)
                ]
            ),

            // MARK: - 2015 – REGIONALS - REGIONAL NATE VARIATION
            DefaultWorkoutSeed(
                name: "NATE REGIONAL",
                title: "Nate Regional – Volume Ginástico Extremo",
                description: "Versão intensa com alto volume de HSPU e muscle-ups.",
                blocks: [
                    .init(title: "Aquecimento", text: """
5 min EMOM leve
Técnica de muscle-up
""", order: 1),
                    .init(title: "Detalhes", text: "Movimentos avançados exigem controle respiratório.", order: 2),
                    .init(title: "Técnica", text: """
• Kipping eficiente
• Dividir HSPU estrategicamente
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 20:
• 4 Handstand Push-ups
• 8 Kettlebell Swings (70/53 lb)
• 12 Ring Muscle-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: Pull-ups
• Scale: 53/35 lb
• RX: Prescrito
""", order: 5)
                ]
            ),

            // MARK: - 2016 - THE SEPARATOR
            DefaultWorkoutSeed(
                name: "THE SEPARATOR",
                title: "The Separator – Sprint Eliminatório",
                description: "Evento de eliminação rápida.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Assault Bike leve
Deadlifts leves
""", order: 1),
                    .init(title: "Detalhes", text: "Tempo limite curto, intensidade máxima.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift rápido com controle
• Transições agressivas
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 1000 m Row
• 50 Deadlifts (225/155 lb)
• 30 Bar Muscle-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: 135/95 lb
• Scale: 185/125 lb
• RX: conforme prescrito
""", order: 5)
                ]
            ),

            // MARK: - 2016 – REGIONALS - THE CLEAN SPEED LADDER
            DefaultWorkoutSeed(
                name: "CLEAN SPEED LADDER",
                title: "The Clean Speed Ladder – Velocidade com Carga",
                description: "Ladder eliminatória em formato head-to-head.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Cleans progressivos
Mobilidade de tornozelo
""", order: 1),
                    .init(title: "Detalhes", text: "Tempo limite curto por estação.", order: 2),
                    .init(title: "Técnica", text: """
• Transição rápida
• Recepção estável
""", order: 3),
                    .init(title: "WOD", text: """
3 rounds:
• 3 Cleans em cada estação crescente
(245 → 275 → 305 → 315 lb)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: 135–185 lb
• Scale: 185–225 lb
• RX: Prescrito
""", order: 5)
                ]
            ),

            // MARK: - 2018 - BICOUPLET 1
            DefaultWorkoutSeed(
                name: "BICOUPLET 1",
                title: "Bicouplet 1 – Potência e Ginástica",
                description: "Combinação curta e explosiva.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de ombros
Thrusters leves
""", order: 1),
                    .init(title: "Detalhes", text: "Alto turnover de barra.", order: 2),
                    .init(title: "Técnica", text: """
• Respiração coordenada
• Movimento cíclico
""", order: 3),
                    .init(title: "WOD", text: """
5 rounds:
• 9 Thrusters (155/105 lb)
• 35 Double-Unders
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: 95/65 lb
• Scale: 115/75 lb
• RX: conforme prescrito
""", order: 5)
                ]
            ),

            // MARK: - 2019 – ROGUE INVITATIONAL - AMANDA 45
            DefaultWorkoutSeed(
                name: "AMANDA 45",
                title: "Amanda 45 – Clássico com Carga Elevada",
                description: "Versão pesada do benchmark Amanda.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Técnica de snatch leve
Muscle-up técnico
""", order: 1),
                    .init(title: "Detalhes", text: "Snatch pesado exige precisão.", order: 2),
                    .init(title: "Técnica", text: """
• Pull vertical eficiente
• Muscle-up fluido
""", order: 3),
                    .init(title: "WOD", text: """
9-7-5:
• Squat Snatch (135/95 lb)
• Bar Muscle-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: 75/55 lb
• Scale: 95/65 lb
• RX: Prescrito
""", order: 5)
                ]
            ),

            // MARK: - 2020 - CROSSFIT TOTAL (GAMES VERSION)
            DefaultWorkoutSeed(
                name: "CROSSFIT TOTAL",
                title: "CrossFit Total – Força Absoluta",
                description: "Soma do melhor levantamento em 3 movimentos.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Progressão técnica
Mobilidade de quadril e ombros
""", order: 1),
                    .init(title: "Detalhes", text: "3 tentativas por movimento.", order: 2),
                    .init(title: "Técnica", text: """
• Agachamento profundo
• Press estável
• Deadlift sólido
""", order: 3),
                    .init(title: "WOD", text: """
1RM:
• Back Squat
• Strict Press
• Deadlift
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: 5RM
• Scale: carga técnica
• RX: máximo absoluto
""", order: 5)
                ]
            ),

            // MARK: - 2020 – ROGUE INVITATIONAL - THE MULE
            DefaultWorkoutSeed(
                name: "THE MULE",
                title: "The Mule – Posterior Chain Destroyer",
                description: "Evento pesado focado em deadlift sob volume.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Deadlift progressivo
Good mornings leves
""", order: 1),
                    .init(title: "Detalhes", text: "Grip e lombar são limitantes.", order: 2),
                    .init(title: "Técnica", text: """
• Barra colada na perna
• Evitar extensão excessiva
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 50 Deadlifts (405/275 lb)
• 50 Box Jump Overs
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: 185/125 lb
• Scale: 275/185 lb
• RX: Prescrito
""", order: 5)
                ]
            ),

            // MARK: - 2021 - CAPITOL
            DefaultWorkoutSeed(
                name: "CAPITOL",
                title: "Capitol – Resistência Longa e Técnica",
                description: "Evento de longa duração nas finais.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Bike leve
Rope climb progressivo
""", order: 1),
                    .init(title: "Detalhes", text: "Exige pacing extremo.", order: 2),
                    .init(title: "Técnica", text: """
• Rope climb com eficiência
• Controle na descida
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 3.5 mile run
• 20 rope climbs
• 200 m farmers carry (70/50 lb)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: 1.5 mile
• Scale: rope assistido
• RX: conforme prescrito
""", order: 5)
                ]
            ),

            // MARK: - 2021 – ROGUE INVITATIONAL - THE GOBLET
            DefaultWorkoutSeed(
                name: "THE GOBLET",
                title: "The Goblet – Resistência com Implemento",
                description: "Evento com kettlebell pesado e corrida.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de quadril
Lunges leves
""", order: 1),
                    .init(title: "Detalhes", text: "Carga unilateral exige estabilidade.", order: 2),
                    .init(title: "Técnica", text: """
• Postura ereta
• Passadas longas e controladas
""", order: 3),
                    .init(title: "WOD", text: """
4 rounds:
• 400 m run
• 40 Goblet Squats (70/53 lb)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: 35/26 lb
• Scale: 53/35 lb
• RX: Prescrito
""", order: 5)
                ]
            ),

            // MARK: - 2022 - SANDBAG LADDER
            DefaultWorkoutSeed(
                name: "SANDBAG LADDER",
                title: "Sandbag Ladder – Potência Funcional",
                description: "Evento outdoor com carga instável.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Lunges leves
Deadlifts leves
""", order: 1),
                    .init(title: "Detalhes", text: "Movimento instável exige core ativo.", order: 2),
                    .init(title: "Técnica", text: """
• Postura neutra
• Abraço firme no sandbag
""", order: 3),
                    .init(title: "WOD", text: """
Sandbag carry ladder:
• 200 lb
• 250 lb
• 300 lb
(distância fixa)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: 100 lb
• Scale: 150–200 lb
• RX: conforme prescrito
""", order: 5)
                ]
            ),

            // MARK: - 2022 – ROGUE INVITATIONAL - DT WITH A SPIN
            DefaultWorkoutSeed(
                name: "DT WITH A SPIN",
                title: "DT with a Spin – Complexo com Interferência",
                description: "Versão modificada do clássico DT com elemento extra.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Deadlift leve
Hang clean técnico
""", order: 1),
                    .init(title: "Detalhes", text: "Complexo repetido sob fadiga.", order: 2),
                    .init(title: "Técnica", text: """
• Touch-and-go controlado
• Split jerk estável
""", order: 3),
                    .init(title: "WOD", text: """
5 rounds:
• 12 Deadlifts
• 9 Hang Cleans
• 6 Push Jerks (155/105 lb)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: 95/65 lb
• Scale: 115/75 lb
• RX: Prescrito
""", order: 5)
                ]
            )
        ]
    }
}
