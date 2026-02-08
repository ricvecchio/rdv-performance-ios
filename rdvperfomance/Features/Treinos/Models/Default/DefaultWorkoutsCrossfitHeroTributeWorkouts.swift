import Foundation

extension DefaultWorkoutsCrossfit {

    static func heroTributeWorkoutsDefaults() -> [DefaultWorkoutSeed] {
        return [

            // MARK: - JT (2005)
            DefaultWorkoutSeed(
                name: "JT (2005)",
                title: "JT – Volume Ginástico sob Fadiga",
                description: "Primeiro Hero WOD publicado pelo CrossFit. Treino curto e extremamente intenso focado em empurrar na ginástica. Exige resistência muscular localizada de ombros e tríceps.",
                blocks: [
                    .init(title: "Aquecimento", text: """
2 rounds leves:
• 10 Push-ups
• 10 Ring rows
• 10 Air squats
Mobilidade de ombros e punhos
2 séries técnicas de handstand hold (20s)
""", order: 1),
                    .init(title: "Detalhes", text: "Treino descendente que aumenta a fadiga dos movimentos de empurrar. A estratégia é controlar o início para evitar falha precoce nos handstand push-ups.", order: 2),
                    .init(title: "Técnica", text: """
• Manter core ativo no HSPU
• Cotovelos próximos ao corpo nos dips
• Push-ups com linha corporal estável
• Quebrar séries antes da falha
""", order: 3),
                    .init(title: "WOD", text: """
21-15-9 reps de:
• Handstand Push-ups
• Ring Dips
• Push-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: Pike push-ups / Bench dips / Push-ups inclinados
• Scale: HSPU com abmat / Dips assistidos com elástico
• RX: Prescrito
• Elite: Unbroken sempre que possível
""", order: 5)
                ]
            ),

            // MARK: - MICHAEL (2005)
            DefaultWorkoutSeed(
                name: "MICHAEL (2005)",
                title: "Michael – Resistência e Capacidade Aeróbica",
                description: "Hero WOD contínuo de endurance misturando corrida e trabalho de core/posterior. Mantém frequência cardíaca elevada do início ao fim.",
                blocks: [
                    .init(title: "Aquecimento", text: """
5 min corrida leve
2 rounds:
• 10 Back extensions
• 10 Sit-ups
Mobilidade de quadril e lombar
""", order: 1),
                    .init(title: "Detalhes", text: "Treino cíclico sem pausas longas. Objetivo é manter ritmo constante, não sprintar a corrida inicial.", order: 2),
                    .init(title: "Técnica", text: """
• Passada econômica na corrida
• Back extension controlado
• Sit-ups com respiração ritmada
""", order: 3),
                    .init(title: "WOD", text: """
3 rounds for time:
• 800 m corrida
• 50 Back Extensions
• 50 Sit-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: 400 m corrida / 30 reps cada
• Scale: 600 m corrida / 40 reps
• RX: Prescrito
• Elite: Ritmo constante sem pausa
""", order: 5)
                ]
            ),

            // MARK: - MURPH (2005)
            DefaultWorkoutSeed(
                name: "MURPH (2005)",
                title: "Murph – Hero de Resistência Extrema",
                description: "Um dos Hero WODs mais icônicos. Volume altíssimo de ginástica combinado com corrida. Teste mental e físico.",
                blocks: [
                    .init(title: "Aquecimento", text: """
800 m corrida leve
2 rounds:
• 10 Push-ups
• 10 Squats
• 5 Pull-ups assistidos
Mobilidade de ombros e quadril
""", order: 1),
                    .init(title: "Detalhes", text: "Treino pode ser particionado. Estratégia clássica: dividir em séries (ex: 20 rounds de Cindy).", order: 2),
                    .init(title: "Técnica", text: """
• Pull-ups eficientes (kipping ou butterfly)
• Push-ups com respiração controlada
• Squats com ritmo constante
• Não iniciar forte demais
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 1 mile run
• 100 Pull-ups
• 200 Push-ups
• 300 Air squats
• 1 mile run
(Com colete 9kg/14lb opcional RX+)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: 800 m corrida / reps reduzidas 50-100-150
• Scale: Pull-ups com elástico / push-ups joelho
• RX: Prescrito
• Elite: Com colete, séries longas
""", order: 5)
                ]
            ),

            // MARK: - DANIEL (2005)
            DefaultWorkoutSeed(
                name: "DANIEL (2005)",
                title: "Daniel – Sprint Metcon com Barra",
                description: "Treino rápido e agressivo combinando ginástica e levantamento olímpico leve/moderado.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de tornozelo e quadril
3 rounds leves:
• 5 Thrusters leves
• 5 Pull-ups
• 200 m corrida leve
""", order: 1),
                    .init(title: "Detalhes", text: "Treino curto onde o pacing é decisivo. Thrusters elevam frequência cardíaca rapidamente.", order: 2),
                    .init(title: "Técnica", text: """
• Thruster com transição fluida
• Barra próxima ao corpo
• Pull-ups eficientes
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 50 Pull-ups
• 400 m run
• 21 Thrusters (95/65 lb)
• 800 m run
• 21 Thrusters (95/65 lb)
• 400 m run
• 50 Pull-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: 45/35 lb / reps reduzidas
• Scale: 65/45 lb
• RX: 95/65 lb
• Elite: Thrusters unbroken
""", order: 5)
                ]
            ),

            // MARK: - JOSH (2006)
            DefaultWorkoutSeed(
                name: "JOSH (2006)",
                title: "Josh – Ginástica com Sobrecarga",
                description: "Combinação de pull-ups com snatch moderado. Exige coordenação e resistência de grip.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de ombros
Técnica de snatch com PVC
3 rounds leves:
• 5 Snatch leve
• 5 Pull-ups
""", order: 1),
                    .init(title: "Detalhes", text: "Grip é fator limitante. Estratégia é evitar falha nos pull-ups.", order: 2),
                    .init(title: "Técnica", text: """
• Snatch com extensão completa do quadril
• Pull-ups consistentes
• Respiração controlada
""", order: 3),
                    .init(title: "WOD", text: """
21-15-9 reps for time:
• Overhead squat (95/65 lb)
• Pull-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: PVC ou barra leve / ring rows
• Scale: 65/45 lb / pull-ups com elástico
• RX: 95/65 lb
• Elite: Unbroken rounds iniciais
""", order: 5)
                ]
            ),

            // MARK: - RANDY (2008)
            DefaultWorkoutSeed(
                name: "RANDY (2008)",
                title: "Randy – Potência e Velocidade no Snatch",
                description: "Hero WOD curto e explosivo focado em snatch. Exige técnica consistente sob fadiga metabólica crescente.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de ombros e tornozelos
Técnica de snatch com PVC
3 séries progressivas:
• 5 Power snatch leve
• 3 Power snatch moderado
""", order: 1),
                    .init(title: "Detalhes", text: "Treino rápido. A barra deve permanecer leve o suficiente para manter ciclo contínuo.", order: 2),
                    .init(title: "Técnica", text: """
• Barra próxima ao corpo
• Recepção estável acima da cabeça
• Extensão completa do quadril
• Evitar puxar apenas com braços
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 75 Power Snatches (75/55 lb)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: 35/25 lb
• Scale: 55/35 lb
• RX: 75/55 lb
• Elite: séries longas (10–15 reps)
""", order: 5)
                ]
            ),

            // MARK: - JASON (2008)
            DefaultWorkoutSeed(
                name: "JASON (2008)",
                title: "Jason – Ginástica sob Alta Fadiga",
                description: "Hero WOD pesado de ginástica avançada. Testa controle corporal e resistência de membros superiores.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade ombros e punhos
3 rounds leves:
• 5 Pull-ups
• 5 Push-ups
• 20s Handstand hold
""", order: 1),
                    .init(title: "Detalhes", text: "Treino altamente técnico. Estratégia é dividir cedo para evitar falha completa.", order: 2),
                    .init(title: "Técnica", text: """
• Handstand push-ups com core ativo
• Pull-ups eficientes
• Controle de respiração
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 100 Squats
• 5 Muscle-ups
• 75 Squats
• 10 Muscle-ups
• 50 Squats
• 15 Muscle-ups
• 25 Squats
• 20 Muscle-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: ring rows / dips assistidos
• Scale: pull-ups + dips
• RX: muscle-ups prescritos
• Elite: séries maiores unbroken
""", order: 5)
                ]
            ),

            // MARK: - BADGER (2008)
            DefaultWorkoutSeed(
                name: "BADGER (2008)",
                title: "Badger – Chipper de Força e Resistência",
                description: "Treino pesado combinando levantamento e saltos. Exige força e capacidade anaeróbica.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de quadril e tornozelo
3 séries leves:
• 5 Power cleans
• 10 Air squats
• 5 Box step-ups
""", order: 1),
                    .init(title: "Detalhes", text: "Carga moderada/alta. Estratégia é manter consistência no clean.", order: 2),
                    .init(title: "Técnica", text: """
• Recepção sólida do clean
• Saltos controlados na caixa
• Respiração entre reps
""", order: 3),
                    .init(title: "WOD", text: """
3 rounds for time:
• 30 Power Cleans (95/65 lb)
• 30 Box Jumps (24/20 in)
• 800 m run
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: 45/35 lb / step-ups
• Scale: 65/45 lb
• RX: Prescrito
• Elite: cleans em séries grandes
""", order: 5)
                ]
            ),

            // MARK: - DT (2009)
            DefaultWorkoutSeed(
                name: "DT (2009)",
                title: "DT – Barbell Cycling sob Pressão",
                description: "Hero clássico com barra. Testa técnica e eficiência no cycling com carga moderada.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade ombros e quadril
Técnica com barra vazia
3 rounds:
• 5 Deadlift leve
• 5 Hang clean leve
• 5 Push jerk leve
""", order: 1),
                    .init(title: "Detalhes", text: "Grip e respiração são determinantes. Estratégia clássica: 11/9 no deadlift.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift com postura neutra
• Hang clean explosivo
• Push jerk com transferência de força
""", order: 3),
                    .init(title: "WOD", text: """
5 rounds for time:
• 12 Deadlifts
• 9 Hang Power Cleans
• 6 Push Jerks
(155/105 lb)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: 65/45 lb
• Scale: 95/65 lb
• RX: 155/105 lb
• Elite: cycling contínuo
""", order: 5)
                ]
            ),

            // MARK: - NATE (2009)
            DefaultWorkoutSeed(
                name: "NATE (2009)",
                title: "Nate – EMOM de Alta Habilidade",
                description: "Treino técnico com ginástica avançada e kettlebell. Exige coordenação e consistência.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade ombros
Prática de muscle-up
KB swings leves
""", order: 1),
                    .init(title: "Detalhes", text: "Treino em rounds máximos. Controle técnico é mais importante que velocidade.", order: 2),
                    .init(title: "Técnica", text: """
• Muscle-ups eficientes
• KB swing até overhead estável
• Handstand push-ups com amplitude completa
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 20 min:
• 2 Muscle-ups
• 4 Handstand Push-ups
• 8 KB swings (2/1.5 pood)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: ring rows + push-ups + KB leve
• Scale: pull-ups + dips
• RX: Prescrito
• Elite: ritmo constante sem pausas
""", order: 5)
                ]
            ),

            // MARK: - RYAN (2009)
            DefaultWorkoutSeed(
                name: "RYAN (2009)",
                title: "Ryan – Ginástica Avançada e Técnica",
                description: "Treino exigente com foco em estabilidade e controle corporal.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de ombros
Técnica de ring muscle-up
Wall walks leves
""", order: 1),
                    .init(title: "Detalhes", text: "Alta exigência técnica. Manter consistência é prioridade.", order: 2),
                    .init(title: "Técnica", text: """
• Transição eficiente no muscle-up
• Handstand push-ups com alinhamento corporal
• Respiração controlada
""", order: 3),
                    .init(title: "WOD", text: """
5 rounds for time:
• 7 Muscle-ups
• 21 Burpees
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: ring rows + burpees reduzidos
• Scale: pull-ups + dips
• RX: Prescrito
• Elite: séries unbroken
""", order: 5)
                ]
            ),

            // MARK: - HANSEN (2009)
            DefaultWorkoutSeed(
                name: "HANSEN (2009)",
                title: "Hansen – Resistência de Posterior e Core",
                description: "Hero WOD com grande volume para cadeia posterior e abdômen. Exige resistência muscular e controle técnico ao longo do tempo.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade lombar e quadril
2 rounds leves:
• 10 Kettlebell swings leves
• 10 Back extensions
• 10 Sit-ups
""", order: 1),
                    .init(title: "Detalhes", text: "Volume alto e repetitivo. O ritmo deve ser controlado para evitar falha prematura na lombar.", order: 2),
                    .init(title: "Técnica", text: """
• Swing com extensão de quadril, não puxar com braços
• Back extension controlado
• Sit-ups com respiração constante
""", order: 3),
                    .init(title: "WOD", text: """
5 rounds for time:
• 30 Kettlebell swings (2/1.5 pood)
• 30 Burpees
• 30 GHD sit-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: KB leve / sit-ups tradicionais
• Scale: 1.5/1 pood
• RX: Prescrito
• Elite: ritmo contínuo sem pausas longas
""", order: 5)
                ]
            ),

            // MARK: - JERRY (2009)
            DefaultWorkoutSeed(
                name: "JERRY (2009)",
                title: "Jerry – Endurance Longo com Corrida e Carga",
                description: "Hero longo que mistura corrida e levantamento. Exige pacing e resistência cardiovascular.",
                blocks: [
                    .init(title: "Aquecimento", text: """
800 m corrida leve
Mobilidade de quadril
2 séries leves de deadlift
""", order: 1),
                    .init(title: "Detalhes", text: "Treino longo. Estratégia é manter consistência e não acelerar demais no início.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift com postura neutra
• Corrida com cadência estável
• Respiração controlada
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 1 mile run
• 2 km row
• 1 mile run
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: 800 m corrida / 1 km row
• Scale: 1200 m corrida / 1500 m row
• RX: Prescrito
• Elite: ritmo competitivo constante
""", order: 5)
                ]
            ),

            // MARK: - HOLBROOK (2010)
            DefaultWorkoutSeed(
                name: "HOLBROOK (2010)",
                title: "Holbrook – Barbell Cycling Sustentado",
                description: "Treino com barra moderada exigindo resistência muscular e técnica sob fadiga.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade ombros e quadril
Barra vazia:
• 5 Deadlift
• 5 Power clean
• 5 Push jerk
""", order: 1),
                    .init(title: "Detalhes", text: "Estratégia baseada em consistência e eficiência nos movimentos com barra.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift com ativação de posterior
• Power clean explosivo
• Push jerk com transferência de força
""", order: 3),
                    .init(title: "WOD", text: """
10 rounds for time:
• 5 Thrusters (135/95 lb)
• 10 Pull-ups
• 15 Burpees
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: 65/45 lb
• Scale: 95/65 lb
• RX: Prescrito
• Elite: rounds rápidos e consistentes
""", order: 5)
                ]
            ),

            // MARK: - WHITTEN (2010)
            DefaultWorkoutSeed(
                name: "WHITTEN (2010)",
                title: "Whitten – Hero Chipper Longo",
                description: "Treino longo com grande variedade de movimentos e alto desgaste metabólico.",
                blocks: [
                    .init(title: "Aquecimento", text: """
800 m corrida leve
Mobilidade geral
2 rounds leves de:
• 10 Squats
• 10 Sit-ups
• 5 Burpees
""", order: 1),
                    .init(title: "Detalhes", text: "Chipper de endurance. Estratégia é dividir os movimentos e manter ritmo constante.", order: 2),
                    .init(title: "Técnica", text: """
• Corrida com economia
• Kettlebell swings com quadril dominante
• Box jumps com aterrissagem segura
""", order: 3),
                    .init(title: "WOD", text: """
5 rounds for time:
• 22 Kettlebell swings (2/1.5 pood)
• 22 Box jumps (24/20 in)
• 400 m run
• 22 Burpees
• 22 Wall-ball shots (20/14 lb)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: KB leve / box step-up
• Scale: cargas reduzidas
• RX: Prescrito
• Elite: transições rápidas
""", order: 5)
                ]
            ),

            // MARK: - LUMBERJACK 20 (2010)
            DefaultWorkoutSeed(
                name: "LUMBERJACK 20 (2010)",
                title: "Lumberjack 20 – Hero de Alto Volume",
                description: "Um dos Hero WODs mais extensos e simbólicos. Alto volume e desgaste metabólico extremo.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade geral
800 m corrida leve
2 rounds leves de movimentos do treino
""", order: 1),
                    .init(title: "Detalhes", text: "Chipper muito longo. Estratégia é dividir reps desde o início e controlar a frequência cardíaca.", order: 2),
                    .init(title: "Técnica", text: """
• Pull-ups eficientes
• Deadlift com postura neutra
• Clean com boa recepção
• Squats controlados
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 20 Deadlifts (275/185 lb)
• 400 m run
• 20 KB swings (2/1.5 pood)
• 400 m run
• 20 Overhead squats (115/75 lb)
• 400 m run
• 20 Burpees
• 400 m run
• 20 Pull-ups
• 400 m run
• 20 Box jumps (24/20 in)
• 400 m run
• 20 Dumbbell squat cleans (45/25 lb)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: cargas reduzidas / reps reduzidas
• Scale: carga intermediária
• RX: Prescrito
• Elite: pacing estratégico para final forte
""", order: 5)
                ]
            ),

            // MARK: - GARRETT (2010)
            DefaultWorkoutSeed(
                name: "GARRETT (2010)",
                title: "Garrett – Ginástica e Resistência Muscular",
                description: "Treino focado em ginástica e resistência de membros superiores, com alto volume de reps.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de ombros e punhos
2 rounds leves:
• 10 Push-ups
• 5 Pull-ups
• 20s Handstand hold
""", order: 1),
                    .init(title: "Detalhes", text: "Volume elevado em ginástica. Estratégia é dividir as séries antes da falha.", order: 2),
                    .init(title: "Técnica", text: """
• Pull-ups eficientes
• Push-ups com linha corporal firme
• Respiração controlada
""", order: 3),
                    .init(title: "WOD", text: """
3 rounds for time:
• 75 Squats
• 25 Ring handstand push-ups
• 25 L-pull-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: push-ups inclinados / ring rows
• Scale: HSPU com apoio / pull-ups assistidos
• RX: Prescrito
• Elite: séries maiores sem pausa
""", order: 5)
                ]
            ),

            // MARK: - BLANCHARD (2010)
            DefaultWorkoutSeed(
                name: "BLANCHARD (2010)",
                title: "Blanchard – Long Endurance Hero",
                description: "Treino longo com corrida e movimentos repetitivos. Testa resistência cardiovascular e mental.",
                blocks: [
                    .init(title: "Aquecimento", text: """
800 m corrida leve
Mobilidade geral
2 rounds leves:
• 10 Air squats
• 10 Sit-ups
""", order: 1),
                    .init(title: "Detalhes", text: "Manter ritmo constante. O fator limitante é a resistência global.", order: 2),
                    .init(title: "Técnica", text: """
• Corrida com cadência estável
• Movimentos econômicos
• Respiração contínua
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 800 m run
• 100 Pull-ups
• 800 m run
• 100 Push-ups
• 800 m run
• 100 Sit-ups
• 800 m run
• 100 Squats
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: reps reduzidas (50)
• Scale: pull-ups assistidos
• RX: Prescrito
• Elite: ritmo contínuo
""", order: 5)
                ]
            ),

            // MARK: - BULL (2010)
            DefaultWorkoutSeed(
                name: "BULL (2010)",
                title: "Bull – Força e Capacidade Anaeróbica",
                description: "Hero com barra pesada e corrida. Exige força e resistência muscular.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade quadril e tornozelo
Barra vazia:
• 5 Power clean
• 5 Front squat
• 5 Push press
""", order: 1),
                    .init(title: "Detalhes", text: "Carga moderada/alta. Estratégia é manter consistência nas reps.", order: 2),
                    .init(title: "Técnica", text: """
• Clean eficiente
• Squat com estabilidade
• Push press com transferência de força
""", order: 3),
                    .init(title: "WOD", text: """
2 rounds for time:
• 200 Double unders
• 50 Overhead squats (135/95 lb)
• 50 Pull-ups
• 1 mile run
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: singles / carga leve
• Scale: 95/65 lb
• RX: Prescrito
• Elite: double unders contínuos
""", order: 5)
                ]
            ),

            // MARK: - MOORE (2010)
            DefaultWorkoutSeed(
                name: "MOORE (2010)",
                title: "Moore – Ginástica Avançada sob Fadiga",
                description: "Treino técnico e intenso com foco em handstand push-ups e muscle-ups.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de ombros
Prática de HSPU
2 rounds leves:
• 5 Pull-ups
• 5 Dips
""", order: 1),
                    .init(title: "Detalhes", text: "Alta exigência técnica. Evitar falha precoce nos muscle-ups.", order: 2),
                    .init(title: "Técnica", text: """
• Transição eficiente no muscle-up
• HSPU com amplitude completa
• Respiração ritmada
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 1 mile run
• 100 Handstand push-ups
• 1 mile run
• 100 Pull-ups
• 1 mile run
• 100 Push-ups
• 1 mile run
• 100 Squats
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: push-ups inclinados / ring rows
• Scale: HSPU assistido
• RX: Prescrito
• Elite: séries longas contínuas
""", order: 5)
                ]
            ),

            // MARK: - GLEN (2010)
            DefaultWorkoutSeed(
                name: "GLEN (2010)",
                title: "Glen – Hero de Endurance Extremo",
                description: "Treino longo com corrida e carga externa. Grande desgaste físico e mental.",
                blocks: [
                    .init(title: "Aquecimento", text: """
800 m corrida leve
Mobilidade de quadril
Caminhada com carga leve
""", order: 1),
                    .init(title: "Detalhes", text: "Treino de resistência. Estratégia é manter pacing constante e gerenciar o peso externo.", order: 2),
                    .init(title: "Técnica", text: """
• Corrida com mochila estável
• Lunges com postura ereta
• Pull-ups eficientes
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 30 Clean and jerks (135/95 lb)
• 1 mile run
• 10 Rope climbs
• 1 mile run
• 100 Burpees
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga reduzida / rope rows
• Scale: 95/65 lb
• RX: Prescrito
• Elite: ritmo constante com poucas pausas
""", order: 5)
                ]
            ),

            // MARK: - COLLIN (2010)
            DefaultWorkoutSeed(
                name: "COLLIN (2010)",
                title: "Collin – Chipper de Alta Resistência",
                description: "Treino longo combinando corrida e trabalho de barra.",
                blocks: [
                    .init(title: "Aquecimento", text: """
800 m corrida leve
Mobilidade geral
Barra leve técnica
""", order: 1),
                    .init(title: "Detalhes", text: "Grande volume de reps. Estratégia é dividir e manter consistência.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift com postura neutra
• Pull-ups eficientes
• Sit-ups controlados
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 20 min:
• 400 m run
• 12 Deadlifts (225/155 lb)
• 21 Box jumps
• 21 Pull-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve / box step-up
• Scale: 155/105 lb
• RX: Prescrito
• Elite: rounds consistentes
""", order: 5)
                ]
            ),

            // MARK: - ADAM BROWN (2010)
            DefaultWorkoutSeed(
                name: "ADAM BROWN (2010)",
                title: "Adam Brown – Resistência com Carga e Ginástica",
                description: "Hero longo com levantamento moderado e corrida. Exige capacidade aeróbica e controle técnico sob fadiga.",
                blocks: [
                    .init(title: "Aquecimento", text: """
800 m corrida leve
Mobilidade quadril e ombros
2 rounds leves:
• 5 Deadlifts
• 5 Pull-ups
• 5 Box jumps
""", order: 1),
                    .init(title: "Detalhes", text: "Volume alto e constante. Estratégia é manter pacing estável e evitar falha no levantamento.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift com postura neutra
• Pull-ups eficientes
• Saltos seguros na caixa
""", order: 3),
                    .init(title: "WOD", text: """
2 rounds for time:
• 24 Deadlifts (295/205 lb)
• 24 Box jumps (24/20 in)
• 24 Wall-ball shots (20/14 lb)
• 24 Bench press (195/135 lb)
• 24 Box jumps
• 24 Wall-ball shots
• 24 Clean (145/105 lb)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: cargas reduzidas
• Scale: carga intermediária
• RX: Prescrito
• Elite: rounds consistentes sem pausas longas
""", order: 5)
                ]
            ),

            // MARK: - ANDY (2010)
            DefaultWorkoutSeed(
                name: "ANDY (2010)",
                title: "Andy – Ginástica e Squat sob Volume",
                description: "Treino focado em ginástica e agachamento com grande volume. Exige resistência muscular e consistência.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade quadril e tornozelo
2 rounds leves:
• 10 Squats
• 5 Pull-ups
• 5 Push-ups
""", order: 1),
                    .init(title: "Detalhes", text: "Treino progressivo de fadiga muscular. Estratégia é dividir reps desde o início.", order: 2),
                    .init(title: "Técnica", text: """
• Squat com controle de joelhos
• Pull-ups eficientes
• Respiração contínua
""", order: 3),
                    .init(title: "WOD", text: """
25 rounds for time:
• 5 Pull-ups
• 10 Push-ups
• 15 Squats
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: rounds reduzidos
• Scale: pull-ups assistidos
• RX: Prescrito
• Elite: rounds unbroken
""", order: 5)
                ]
            ),

            // MARK: - ALEXANDER (2010)
            DefaultWorkoutSeed(
                name: "ALEXANDER (2010)",
                title: "Alexander – Barbell e Ginástica em Intervalos",
                description: "Treino intenso que combina levantamento e ginástica. Alto desgaste metabólico.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Técnica com barra leve
Mobilidade ombros
2 rounds leves de movimentos do treino
""", order: 1),
                    .init(title: "Detalhes", text: "Carga moderada exige técnica consistente.", order: 2),
                    .init(title: "Técnica", text: """
• Clean eficiente
• Burpees ritmados
• Respiração controlada
""", order: 3),
                    .init(title: "WOD", text: """
5 rounds for time:
• 31 Back squats (135/95 lb)
• 12 Power cleans (185/135 lb)
• 31 Box jumps
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve
• Scale: carga intermediária
• RX: Prescrito
• Elite: pacing agressivo
""", order: 5)
                ]
            ),

            // MARK: - CAMERON (2010)
            DefaultWorkoutSeed(
                name: "CAMERON (2010)",
                title: "Cameron – Chipper de Resistência Global",
                description: "Hero longo combinando corrida, carga e ginástica. Alto desgaste físico.",
                blocks: [
                    .init(title: "Aquecimento", text: """
800 m corrida leve
Mobilidade geral
2 rounds leves de movimentos do treino
""", order: 1),
                    .init(title: "Detalhes", text: "Treino de endurance. Estratégia é manter ritmo constante e dividir reps.", order: 2),
                    .init(title: "Técnica", text: """
• Corrida econômica
• Lunges controlados
• Pull-ups consistentes
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 50 Walking lunges (135/95 lb)
• 25 Pull-ups
• 50 Box jumps
• 25 Triple-unders
• 50 Back extensions
• 25 Ring dips
• 50 Knees-to-elbows
• 25 Wall-ball shots
• 50 Sit-ups
• 5 Rope climbs
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga reduzida / substituições técnicas
• Scale: intermediário
• RX: Prescrito
• Elite: ritmo constante
""", order: 5)
                ]
            ),

            // MARK: - ERIN (2010)
            DefaultWorkoutSeed(
                name: "ERIN (2010)",
                title: "Erin – Intervalos de Ginástica e Sprint",
                description: "Hero curto e intenso com rounds máximos. Testa potência e resistência.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade ombros
3 rounds leves:
• 5 Pull-ups
• 5 Burpees
""", order: 1),
                    .init(title: "Detalhes", text: "Treino em rounds máximos. Intensidade alta do início ao fim.", order: 2),
                    .init(title: "Técnica", text: """
• Pull-ups rápidos
• Burpees com transição eficiente
""", order: 3),
                    .init(title: "WOD", text: """
5 rounds for max reps:
• 40 Double unders
• 20 Pull-ups
• 15 Burpees
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: singles / ring rows
• Scale: pull-ups assistidos
• RX: Prescrito
• Elite: rounds contínuos
""", order: 5)
                ]
            ),

            // MARK: - HAMILTON (2013)
            DefaultWorkoutSeed(
                name: "HAMILTON (2013)",
                title: "Hamilton – Intervalos de Alta Intensidade com Corrida/Remo",
                description: "Hero WOD intervalado com estímulo anaeróbico e grande demanda de transição. Exige ritmo forte e recuperação rápida.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de ombros e quadril
5 min de cardio leve (remo/corrida)
2 rounds leves:
• 10 Push-ups
• 5 Pull-ups (ou ring rows)
• 200 m corrida leve
""", order: 1),
                    .init(title: "Detalhes", text: "Treino com rounds intensos. O desafio é manter consistência sem quebrar completamente nas transições.", order: 2),
                    .init(title: "Técnica", text: """
• Respiração controlada durante o cardio
• Pull-ups com reps curtas e consistentes
• Evitar sprint inicial que “apaga” no meio
""", order: 3),
                    .init(title: "WOD", text: """
3 rounds for time:
• Row 1000 m
• 50 Push-ups
• Run 1000 m
• 50 Pull-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: 500 m row / 500 m run / reps reduzidas
• Scale: pull-ups assistidos / push-ups inclinados
• RX: Prescrito
• Elite: transições imediatas e séries longas
""", order: 5)
                ]
            ),

            // MARK: - HELTON (2010)
            DefaultWorkoutSeed(
                name: "HELTON (2010)",
                title: "Helton – Corrida + DB Squat Clean sob Pressão",
                description: "Treino cíclico com corrida e trabalho explosivo com halteres. Alto desgaste metabólico e demanda de pernas/grip.",
                blocks: [
                    .init(title: "Aquecimento", text: """
800 m corrida leve
Mobilidade de tornozelo/quadril
2 rounds leves:
• 10 Air squats
• 6 DB hang squat cleans leves
• 5 Burpees
""", order: 1),
                    .init(title: "Detalhes", text: "Treino repetitivo. A consistência na corrida e o controle da respiração no squat clean determinam o ritmo.", order: 2),
                    .init(title: "Técnica", text: """
• DB squat clean com tronco firme e base estável
• Burpees com transição imediata
• Corrida com cadência constante
""", order: 3),
                    .init(title: "WOD", text: """
3 rounds for time:
• Run 800 m
• 30 DB squat cleans (50/35 lb)
• 30 Burpees
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: DB leve / reps reduzidas
• Scale: 35/20 lb
• RX: Prescrito
• Elite: DB em séries longas + corrida agressiva
""", order: 5)
                ]
            ),

            // MARK: - HORTON (2015)
            DefaultWorkoutSeed(
                name: "HORTON (2015)",
                title: "Horton – Parceiros: Bar MU + C&J + Carry",
                description: "Hero WOD em dupla com estímulo de potência e força, exigindo coordenação, ritmo e divisão inteligente do trabalho.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de ombros/quadril
Técnica leve de clean and jerk
2 rounds leves:
• 5 bar dips (ou dip em caixa)
• 5 power cleans leves
• 20 m buddy carry leve (ou sandbag carry)
""", order: 1),
                    .init(title: "Detalhes", text: "Treino em dupla: apenas um trabalha por vez. Estratégia é dividir por blocos curtos para manter intensidade alta.", order: 2),
                    .init(title: "Técnica", text: """
• Bar muscle-up com ritmo e kip eficiente
• Clean and jerk com recepção estável
• Carry com tronco firme e passos curtos
""", order: 3),
                    .init(title: "WOD", text: """
9 rounds for time (com parceiro):
• 9 Bar muscle-ups
• 11 Clean and jerks (155 lb)
• 50-yard buddy carry
(Compartilhar o trabalho; 1 pessoa por vez)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: ring rows + push-ups / carga leve / sandbag carry
• Scale: bar pull-ups + dips / 95–115 lb
• RX: Prescrito
• Elite: trocas rápidas e sets curtos sem descanso
""", order: 5)
                ]
            ),

            // MARK: - JACK (2010)
            DefaultWorkoutSeed(
                name: "JACK (2010)",
                title: "Jack – Consistência no AMRAP com Press",
                description: "Hero WOD em AMRAP com press, swing e salto. Exige ritmo constante e transições rápidas, com foco em resistência de ombros.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de ombros
2 rounds leves:
• 8 Push press leve
• 10 KB swings leves
• 8 Box step-ups
""", order: 1),
                    .init(title: "Detalhes", text: "Treino de densidade: o objetivo é manter séries unbroken e minimizar descanso nas transições.", order: 2),
                    .init(title: "Técnica", text: """
• Push press com drive de pernas e travamento sólido
• Swing com quadril dominante (não puxar com braços)
• Saltos com aterrissagem suave e controle
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 20 min:
• 10 Push presses (115/80 lb)
• 10 KB swings (24/16 kg)
• 10 Box jumps (24/20 in)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: push press leve / KB leve / step-ups
• Scale: reduzir carga e altura da caixa
• RX: Prescrito
• Elite: rounds consistentes com transições imediatas
""", order: 5)
                ]
            ),

            // MARK: - JAKE (2011)
            DefaultWorkoutSeed(
                name: "JAKE (2011)",
                title: "Jake – Endurance com Barra",
                description: "Hero longo combinando corrida e levantamento com volume moderado. Exige consistência e pacing estável.",
                blocks: [
                    .init(title: "Aquecimento", text: """
800 m corrida leve
Mobilidade de quadril
Técnica de deadlift com barra vazia
""", order: 1),
                    .init(title: "Detalhes", text: "Treino simples e eficiente: controlar o ritmo na corrida e manter técnica no levantamento são os fatores-chave.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift com coluna neutra e tensão de dorsal
• Corrida econômica (sem sprintar no início)
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 1000 m run
• 50 deadlifts (135/95 lb)
• 1000 m run
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: corrida reduzida / carga leve
• Scale: 95/65 lb
• RX: Prescrito
• Elite: transições rápidas e deadlift em séries longas
""", order: 5)
                ]
            ),

            // MARK: - KALSU (2011)
            DefaultWorkoutSeed(
                name: "KALSU (2011)",
                title: "Kalsu – Thrusters sob Interrupção",
                description: "Um dos Hero WODs mais desafiadores mentalmente. Thrusters com burpees obrigatórios a cada minuto, exigindo controle emocional e ritmo.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade ombros e quadril
Técnica de thruster com barra vazia
2 rounds leves:
• 5 Burpees
• 5 Thrusters leves
""", order: 1),
                    .init(title: "Detalhes", text: "A cada minuto inicia com burpees e depois acumula thrusters. A estratégia é não falhar no thruster e manter burpees rápidos.", order: 2),
                    .init(title: "Técnica", text: """
• Thruster com transição fluida (front squat → press)
• Burpees com respiração ritmada
• Quebrar thrusters antes da falha
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 100 Thrusters (135/95 lb)
A cada minuto:
• 5 Burpees
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve / burpees reduzidos
• Scale: 95/65 lb
• RX: Prescrito
• Elite: thrusters em séries longas, burpees sem pausa
""", order: 5)
                ]
            ),

            // MARK: - LEE (2012)
            DefaultWorkoutSeed(
                name: "LEE (2012)",
                title: "Lee – Corrida + Deadlift em Densidade",
                description: "Treino com rounds repetitivos de corrida e deadlift, exigindo resistência muscular e bom controle de pacing.",
                blocks: [
                    .init(title: "Aquecimento", text: """
5 min corrida leve
Mobilidade de quadril/lombar
2 séries leves de deadlift
""", order: 1),
                    .init(title: "Detalhes", text: "O desafio é manter o deadlift eficiente sem perder o ritmo na corrida. Grip e respiração são determinantes.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift com barra próxima do corpo e costas neutras
• Corrida com cadência estável e respiração contínua
""", order: 3),
                    .init(title: "WOD", text: """
5 rounds for time:
• 400 m run
• 21 deadlifts (225/155 lb)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve / reps reduzidas
• Scale: 155/105 lb
• RX: Prescrito
• Elite: deadlift em séries grandes sem descanso
""", order: 5)
                ]
            ),

            // MARK: - LOREDO (2012)
            DefaultWorkoutSeed(
                name: "LOREDO (2012)",
                title: "Loredo – Volume Corporal com Corrida",
                description: "Hero de endurance com rounds repetitivos de movimentos corporais e corrida, exigindo consistência e controle de fadiga.",
                blocks: [
                    .init(title: "Aquecimento", text: """
800 m corrida leve
Mobilidade geral
2 rounds leves:
• 10 Air squats
• 8 Push-ups
• 10 Lunges (passos)
""", order: 1),
                    .init(title: "Detalhes", text: "Treino de volume constante: manter um ritmo sustentável e evitar quebrar demais os push-ups é o ponto-chave.", order: 2),
                    .init(title: "Técnica", text: """
• Lunges com tronco ereto e passo controlado
• Push-ups com core firme
• Corrida sem sprintar no começo
""", order: 3),
                    .init(title: "WOD", text: """
6 rounds for time:
• 24 Air squats
• 24 Push-ups
• 24 Walking lunges
• 400 m run
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: reps reduzidas / corrida reduzida
• Scale: push-ups inclinados / lunges assistidos
• RX: Prescrito
• Elite: transições rápidas e ritmo contínuo
""", order: 5)
                ]
            ),

            // MARK: - LUCAS (2012)
            DefaultWorkoutSeed(
                name: "LUCAS (2012)",
                title: "Lucas – Ginástica Avançada + Squat",
                description: "Treino técnico e intenso com muscle-ups e alto volume de agachamentos, exigindo habilidade e resistência muscular.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de ombros
Prática de transição do muscle-up (baixa intensidade)
2 rounds leves:
• 10 Air squats
• 5 Pull-ups (ou ring rows)
• 5 Dips (assistido)
""", order: 1),
                    .init(title: "Detalhes", text: "O fator limitante é a consistência nos muscle-ups sob fadiga. Controlar o ritmo dos squats preserva a técnica.", order: 2),
                    .init(title: "Técnica", text: """
• Muscle-up com kip eficiente e transição rápida
• Squats com cadência estável e joelhos acompanhando os pés
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 15 min:
• 7 Muscle-ups
• 50 Squats
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: ring rows + push-ups / reps reduzidas
• Scale: pull-ups + dips (assistido) / reps reduzidas
• RX: Prescrito
• Elite: rounds consistentes com muscle-ups unbroken quando possível
""", order: 5)
                ]
            ),

            // MARK: - LUCE (2012)
            DefaultWorkoutSeed(
                name: "LUCE (2012)",
                title: "Luce – Endurance Ginástico com Corrida",
                description: "Hero de resistência com alto volume de ginástica e corrida. Exige estratégia de séries e pacing estável.",
                blocks: [
                    .init(title: "Aquecimento", text: """
800 m corrida leve
Mobilidade de ombros
2 rounds leves:
• 5 Pull-ups (assistido)
• 10 Push-ups
• 10 Squats
""", order: 1),
                    .init(title: "Detalhes", text: "Treino longo de volume. Estratégia comum é dividir em séries pequenas desde o início para evitar falha total.", order: 2),
                    .init(title: "Técnica", text: """
• Pull-ups com economia (kipping consistente)
• Push-ups com respiração ritmada
• Corrida em ritmo de recuperação ativa
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 1000 m run
• 100 Pull-ups
• 100 Push-ups
• 100 Squats
• 1000 m run
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: reps reduzidas / corrida reduzida
• Scale: pull-ups com elástico / push-ups joelho
• RX: Prescrito
• Elite: manter séries longas e corrida consistente
""", order: 5)
                ]
            ),

            // MARK: - MARCO (2011)
            DefaultWorkoutSeed(
                name: "MARCO (2011)",
                title: "Marco – Chipper de Resistência Global",
                description: "Hero WOD longo combinando corrida, carga e ginástica. Exige resistência cardiovascular e controle técnico sob fadiga.",
                blocks: [
                    .init(title: "Aquecimento", text: """
800 m corrida leve
Mobilidade quadril e ombros
2 rounds leves:
• 10 Squats
• 5 Pull-ups
• 5 Push-ups
""", order: 1),
                    .init(title: "Detalhes", text: "Treino com alto volume. Estratégia é manter ritmo constante e dividir reps desde o início.", order: 2),
                    .init(title: "Técnica", text: """
• Pull-ups eficientes
• Lunges controlados
• Respiração contínua
""", order: 3),
                    .init(title: "WOD", text: """
For time:
21-15-9 reps de:
• Thrusters (95/65 lb)
• Pull-ups
400 m run após cada round
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve / assistido
• Scale: carga intermediária
• RX: Prescrito
• Elite: transições rápidas
""", order: 5)
                ]
            ),

            // MARK: - MARSTON (2011)
            DefaultWorkoutSeed(
                name: "MARSTON (2011)",
                title: "Marston – Hero de Endurance Extremo",
                description: "Treino longo e exigente com corrida e ginástica em grande volume. Teste físico e mental.",
                blocks: [
                    .init(title: "Aquecimento", text: """
800 m corrida leve
Mobilidade geral
2 rounds leves dos movimentos
""", order: 1),
                    .init(title: "Detalhes", text: "Treino muito longo. Estratégia é pacing constante e divisão eficiente das reps.", order: 2),
                    .init(title: "Técnica", text: """
• Corrida econômica
• Pull-ups consistentes
• Push-ups controlados
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
• Iniciante: reps reduzidas
• Scale: assistido
• RX: Prescrito
• Elite: ritmo contínuo
""", order: 5)
                ]
            ),

            // MARK: - MATHEW (2011)
            DefaultWorkoutSeed(
                name: "MATHEW (2011)",
                title: "Mathew – Sprint com Barra",
                description: "Hero curto e intenso combinando corrida e levantamento. Exige agressividade controlada e boa técnica.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Corrida leve
Técnica com barra vazia
Mobilidade de quadril e ombros
""", order: 1),
                    .init(title: "Detalhes", text: "Treino rápido e agressivo. O pacing inicial é determinante para não perder eficiência no levantamento.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift com postura neutra
• Corrida com cadência estável
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 800 m run
• 50 Deadlifts (135/95 lb)
• 800 m run
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: corrida reduzida / carga leve
• Scale: 95/65 lb
• RX: Prescrito
• Elite: transições imediatas
""", order: 5)
                ]
            ),

            // MARK: - MAUPIN (2011)
            DefaultWorkoutSeed(
                name: "MAUPIN (2011)",
                title: "Maupin – Ginástica e Resistência",
                description: "Treino baseado em movimentos corporais com alto volume e desgaste metabólico. Demanda pacing e consistência.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade ombros
2 rounds leves:
• 10 Push-ups
• 5 Pull-ups
• 10 Squats
""", order: 1),
                    .init(title: "Detalhes", text: "Volume contínuo. Estratégia é dividir séries antes da falha e manter a respiração sob controle.", order: 2),
                    .init(title: "Técnica", text: """
• Pull-ups eficientes
• Push-ups com core ativo
• Squats ritmados
""", order: 3),
                    .init(title: "WOD", text: """
4 rounds for time:
• 800 m run
• 49 Push-ups
• 49 Sit-ups
• 49 Squats
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: reps reduzidas
• Scale: assistido
• RX: Prescrito
• Elite: ritmo constante com poucas pausas
""", order: 5)
                ]
            ),

            // MARK: - MCCLUSKEY (2012)
            DefaultWorkoutSeed(
                name: "MCCLUSKEY (2012)",
                title: "McCluskey – Força e Volume com Barra",
                description: "Hero com levantamento e corrida, exigindo resistência muscular e técnica consistente em rounds longos.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Corrida leve
Técnica com barra vazia
Mobilidade de quadril
""", order: 1),
                    .init(title: "Detalhes", text: "Carga moderada. Estratégia é manter consistência e evitar falha, especialmente no grip.", order: 2),
                    .init(title: "Técnica", text: """
• Power clean eficiente
• Corrida controlada entre rounds
""", order: 3),
                    .init(title: "WOD", text: """
For time:
9 rounds:
• 9 Power cleans (135/95 lb)
• 800 m run
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve / corrida reduzida
• Scale: carga intermediária
• RX: Prescrito
• Elite: rounds consistentes sem “quebrar”
""", order: 5)
                ]
            ),

            // MARK: - MCGHEE (2012)
            DefaultWorkoutSeed(
                name: "MCGHEE (2012)",
                title: "McGhee – Densidade e Potência em AMRAP",
                description: "Treino em AMRAP com deadlift pesado/moderado, push-ups e box jumps. Exige consistência e boa gestão do ritmo.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de quadril/lombar
Técnica de deadlift com barra leve
2 rounds leves:
• 6 Deadlifts leves
• 10 Push-ups
• 6 Box step-ups
""", order: 1),
                    .init(title: "Detalhes", text: "Treino de densidade. O objetivo é manter rounds estáveis sem perder a técnica no deadlift.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift com tensão de dorsal e coluna neutra
• Box jumps com aterrissagem estável
• Push-ups com respiração constante
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 30 min:
• 5 Deadlifts (275/185 lb)
• 13 Push-ups
• 9 Box jumps
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve / step-ups
• Scale: 185/125 lb
• RX: Prescrito
• Elite: rounds contínuos sem pausas longas
""", order: 5)
                ]
            ),

            // MARK: - NELSON (2012)
            DefaultWorkoutSeed(
                name: "NELSON (2012)",
                title: "Nelson – Sprint e Ginástica",
                description: "Treino curto e intenso com corrida e ginástica, exigindo transições rápidas e consistência nas séries.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Corrida leve
Mobilidade ombros
2 rounds leves:
• 5 Pull-ups (assistido)
• 8 Burpees
""", order: 1),
                    .init(title: "Detalhes", text: "Alta intensidade. Estratégia é manter consistência e evitar quebrar muito as séries de pull-up.", order: 2),
                    .init(title: "Técnica", text: """
• Pull-ups em séries curtas e rápidas
• Burpees com transição imediata
• Corrida em ritmo agressivo, mas sustentável
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 50 Burpees
• 400 m run
• 50 Pull-ups
• 400 m run
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: reps reduzidas / ring rows
• Scale: pull-ups assistidos
• RX: Prescrito
• Elite: manter ritmo alto com poucas pausas
""", order: 5)
                ]
            ),

            // MARK: - OMAR (2013)
            DefaultWorkoutSeed(
                name: "OMAR (2013)",
                title: "Omar – Thrusters e Burpees em Escada",
                description: "Treino intenso em formato crescente, com thrusters e bar-facing burpees. Exige tolerância a lactato e controle do ritmo.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de ombros e quadril
Técnica de thruster com barra vazia
2 rounds leves:
• 5 Thrusters leves
• 5 Burpees
""", order: 1),
                    .init(title: "Detalhes", text: "A intensidade cresce a cada bloco. Estratégia é manter thrusters em séries inteligentes e burpees constantes.", order: 2),
                    .init(title: "Técnica", text: """
• Thruster com drive de pernas e travamento forte
• Burpees com ritmo constante (não sprintar e quebrar)
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• Thrusters (95/65 lb) 10
• Bar-facing burpees 15
• Thrusters 20
• Bar-facing burpees 25
• Thrusters 30
• Bar-facing burpees 35
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve / burpees reduzidos
• Scale: 65/45 lb
• RX: Prescrito
• Elite: thrusters em séries longas e burpees sem pausa
""", order: 5)
                ]
            ),

            // MARK: - PAT (2013)
            DefaultWorkoutSeed(
                name: "PAT (2013)",
                title: "Pat – Hero de Longa Duração",
                description: "Treino longo com corrida e ginástica em alto volume. Exige pacing constante e disciplina nas séries.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Corrida leve
Mobilidade geral
2 rounds leves dos movimentos
""", order: 1),
                    .init(title: "Detalhes", text: "Grande volume. A estratégia é começar conservador e dividir as séries desde o início.", order: 2),
                    .init(title: "Técnica", text: """
• Pull-ups consistentes
• Push-ups controlados
• Corrida em ritmo sustentável
""", order: 3),
                    .init(title: "WOD", text: """
For time:
6 rounds:
• 25 Pull-ups
• 50 Push-ups
• 75 Squats
• 400 m run
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: reps reduzidas
• Scale: pull-ups assistidos / push-ups adaptados
• RX: Prescrito
• Elite: transições rápidas e ritmo constante
""", order: 5)
                ]
            ),

            // MARK: - RANKEL (2013)
            DefaultWorkoutSeed(
                name: "RANKEL (2013)",
                title: "Rankel – Barbell e Ginástica em Densidade",
                description: "Treino com rounds repetitivos exigindo consistência no levantamento e estabilidade no condicionamento.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Técnica com barra leve
Mobilidade ombros e quadril
2 rounds leves:
• 6 Deadlifts leves
• 5 Burpee pull-ups (ou burpees + ring rows)
• 8 KB swings leves
""", order: 1),
                    .init(title: "Detalhes", text: "Treino de rounds longos: o desafio é manter ritmo sem quebrar a técnica do deadlift.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift com coluna neutra e controle
• Burpee pull-up com transição imediata
• Swing com extensão de quadril
""", order: 3),
                    .init(title: "WOD", text: """
20 rounds for time:
• 6 Deadlifts (225/155 lb)
• 7 Burpee pull-ups
• 10 KB swings
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve / substituições
• Scale: 155/105 lb
• RX: Prescrito
• Elite: rounds rápidos e constantes
""", order: 5)
                ]
            ),

            // MARK: - RAUF (2013)
            DefaultWorkoutSeed(
                name: "RAUF (2013)",
                title: "Rauf – Sprint Hero com Barra",
                description: "Treino curto e intenso combinando levantamento e corrida. Exige eficiência nas transições e técnica sob fadiga.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Corrida leve
Mobilidade geral
Técnica de deadlift com carga leve
""", order: 1),
                    .init(title: "Detalhes", text: "Alta intensidade. Estratégia é evitar falha no deadlift e manter corrida forte porém controlada.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift com postura neutra
• Corrida com respiração controlada
• Push-ups consistentes (evitar falha)
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 50 Deadlifts (135/95 lb)
• 800 m run
• 50 Push-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve / reps reduzidas
• Scale: 95/65 lb
• RX: Prescrito
• Elite: transições rápidas e séries longas
""", order: 5)
                ]
            ),

            // MARK: - RILEY (2013)
            DefaultWorkoutSeed(
                name: "RILEY (2013)",
                title: "Riley – Corrida Longa + Burpees",
                description: "Treino brutal de resistência com grande volume de burpees entre duas corridas longas. Forte desafio mental e aeróbico.",
                blocks: [
                    .init(title: "Aquecimento", text: """
800 m corrida leve
Mobilidade de tornozelo/quadril
2 rounds leves:
• 6 Burpees
• 10 Air squats
""", order: 1),
                    .init(title: "Detalhes", text: "Treino de resistência. A estratégia é manter burpees em ritmo constante, sem “sprintar” e quebrar.", order: 2),
                    .init(title: "Técnica", text: """
• Burpees com cadência estável e respiração ritmada
• Corrida como “controle” para manter frequência cardíaca
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 1.5 mile run
• 150 Burpees
• 1.5 mile run
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: corrida reduzida / burpees reduzidos
• Scale: burpees com step-back
• RX: Prescrito
• Elite: manter burpees sem pausas longas
""", order: 5)
                ]
            ),

            // MARK: - ROY (2013)
            DefaultWorkoutSeed(
                name: "ROY (2013)",
                title: "Roy – Deadlift, Burpee e Pull-up",
                description: "Hero clássico de força e condicionamento. Deadlift com volume moderado/alto combinado com burpees e pull-ups exige resistência total.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de quadril/lombar
Técnica de deadlift com barra vazia
2 rounds leves:
• 6 Deadlifts leves
• 6 Burpees
• 5 Ring rows
""", order: 1),
                    .init(title: "Detalhes", text: "A chave é não queimar o grip no deadlift e manter burpees constantes. Pull-ups em séries curtas ajudam muito.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift com coluna neutra e barras próximas
• Burpees com transição eficiente
• Pull-ups com economia (kipping consistente)
""", order: 3),
                    .init(title: "WOD", text: """
5 rounds for time:
• 15 Deadlifts (225/155 lb)
• 20 Burpees
• 25 Pull-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve / reps reduzidas
• Scale: 155/105 lb / pull-ups com elástico
• RX: Prescrito
• Elite: rounds consistentes com poucas pausas
""", order: 5)
                ]
            ),

            // MARK: - SAMAN (2013)
            DefaultWorkoutSeed(
                name: "SAMAN (2013)",
                title: "Saman – Densidade com Corrida",
                description: "Hero de rounds repetitivos com levantamento e corrida. Exige consistência e pacing bem controlado.",
                blocks: [
                    .init(title: "Aquecimento", text: """
800 m corrida leve
Mobilidade quadril e ombros
2 rounds leves:
• 6 Deadlifts leves
• 10 Wall-ball shots leves
""", order: 1),
                    .init(title: "Detalhes", text: "Treino de volume constante. A estratégia é manter rounds estáveis, evitando “explodir” no começo.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift com postura neutra
• Wall-ball com agachamento e arremesso fluido
• Corrida com respiração controlada
""", order: 3),
                    .init(title: "WOD", text: """
For time:
8 rounds:
• 13 Deadlifts (185/135 lb)
• 17 Wall-ball shots (20/14 lb)
• 400 m run
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve / reps reduzidas
• Scale: 135/95 lb / wall-ball leve
• RX: Prescrito
• Elite: rounds consistentes e transições rápidas
""", order: 5)
                ]
            ),

            // MARK: - SCHMIDT (2014)
            DefaultWorkoutSeed(
                name: "SCHMIDT (2014)",
                title: "Schmidt – Barbell Cycling sob Fadiga",
                description: "Treino com barra em AMRAP com padrão DT, exigindo consistência e boa técnica para cycling contínuo.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Técnica com barra vazia:
• 5 Deadlifts
• 5 Hang power cleans
• 5 Push jerks
Mobilidade de ombros/quadril
""", order: 1),
                    .init(title: "Detalhes", text: "O objetivo é manter rounds consistentes. Quebrar em séries curtas preserva o grip e a técnica.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift com tensão de dorsal e barra rente ao corpo
• Hang clean com extensão completa
• Push jerk com dip/drive eficiente
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 20 min:
• 9 Deadlifts
• 9 Hang power cleans
• 9 Push jerks
(155/105 lb)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve
• Scale: 95/65 lb
• RX: Prescrito
• Elite: rounds contínuos com poucas pausas
""", order: 5)
                ]
            ),

            // MARK: - SEÁN (2014)
            DefaultWorkoutSeed(
                name: "SEÁN (2014)",
                title: "Seán – Corrida e Ginástica sob Volume",
                description: "Hero com padrão de corrida alternada e volume de movimentos corporais. Exige pacing e resistência muscular.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Corrida leve
Mobilidade de ombros e quadril
2 rounds leves:
• 5 Pull-ups (assistido)
• 10 Push-ups
• 10 Sit-ups
""", order: 1),
                    .init(title: "Detalhes", text: "Treino longo. Manter a corrida em ritmo sustentável ajuda a segurar a qualidade das reps de ginástica.", order: 2),
                    .init(title: "Técnica", text: """
• Pull-ups em séries curtas e consistentes
• Push-ups com core firme e respiração ritmada
• Corrida com cadência estável
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 50 Pull-ups
• 800 m run
• 50 Push-ups
• 800 m run
• 50 Sit-ups
• 800 m run
• 50 Squats
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: reps reduzidas / corrida reduzida
• Scale: pull-ups assistidos / push-ups adaptados
• RX: Prescrito
• Elite: transições rápidas e ritmo contínuo
""", order: 5)
                ]
            ),

            // MARK: - SHIP (2014)
            DefaultWorkoutSeed(
                name: "SHIP (2014)",
                title: "Ship – Sprint com Ginástica",
                description: "Treino curto e intenso focado em muscle-ups e burpees. Exige habilidade sob alta frequência cardíaca.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de ombros
Prática leve de transição no muscle-up
2 rounds leves:
• 6 Burpees
• 5 Pull-ups (assistido)
• 5 Dips (assistido)
""", order: 1),
                    .init(title: "Detalhes", text: "Alta intensidade. Estratégia é manter muscle-ups consistentes (séries pequenas) e burpees sem pausa.", order: 2),
                    .init(title: "Técnica", text: """
• Muscle-up com kip eficiente e transição rápida
• Burpees com cadência estável e respiração controlada
""", order: 3),
                    .init(title: "WOD", text: """
For time:
7 rounds:
• 7 Muscle-ups
• 7 Burpees
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: ring rows + burpees reduzidos
• Scale: pull-ups + dips (assistido)
• RX: Prescrito
• Elite: rounds unbroken
""", order: 5)
                ]
            ),

            // MARK: - SMALL (2014)
            DefaultWorkoutSeed(
                name: "SMALL (2014)",
                title: "Small – Corrida + Back Squat em Rounds",
                description: "Treino de endurance com padrão simples: corrida e back squat. Exige consistência e controle da fadiga de pernas.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Corrida leve
Mobilidade de quadril/tornozelo
Técnica de back squat com carga leve
""", order: 1),
                    .init(title: "Detalhes", text: "Treino de longa duração. Evitar acelerar demais na corrida preserva o agachamento ao longo dos rounds.", order: 2),
                    .init(title: "Técnica", text: """
• Back squat com profundidade consistente e tronco firme
• Corrida com cadência estável (controle de respiração)
""", order: 3),
                    .init(title: "WOD", text: """
For time:
3 rounds:
• 800 m run
• 50 Back squats (135/95 lb)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: corrida reduzida / carga leve
• Scale: 95/65 lb
• RX: Prescrito
• Elite: rounds consistentes com pausas mínimas
""", order: 5)
                ]
            ),

            // MARK: - STEPHEN (2015)
            DefaultWorkoutSeed(
                name: "STEPHEN (2015)",
                title: "Stephen – Ginástica e Corrida em AMRAP",
                description: "Treino de densidade com push-ups, pull-ups e corrida. Exige ritmo sustentável e transições rápidas.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Corrida leve
Mobilidade de ombros
2 rounds leves:
• 10 Push-ups
• 5 Ring rows
• 200 m run
""", order: 1),
                    .init(title: "Detalhes", text: "AMRAP de controle: manter séries curtas e constantes evita falha e mantém a densidade do treino.", order: 2),
                    .init(title: "Técnica", text: """
• Push-ups com linha corporal firme
• Pull-ups (ou variação) em séries pequenas
• Corrida em ritmo de “manutenção”
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 20 min:
• 30 Push-ups
• 15 Pull-ups
• 400 m run
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: reps reduzidas / corrida reduzida
• Scale: ring rows / push-ups inclinados
• RX: Prescrito
• Elite: rounds contínuos com transições rápidas
""", order: 5)
                ]
            ),

            // MARK: - STRANG (2015)
            DefaultWorkoutSeed(
                name: "STRANG (2015)",
                title: "Strang – Barbell + Volume Corporal",
                description: "Treino com power clean e grande volume de movimentos corporais. Exige resistência muscular e técnica consistente.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de quadril/ombros
Técnica de power clean com barra leve
2 rounds leves:
• 5 Power cleans leves
• 10 Push-ups
• 10 Squats
""", order: 1),
                    .init(title: "Detalhes", text: "O desafio é manter o clean eficiente sob fadiga. Dividir reps com consistência melhora muito o desempenho.", order: 2),
                    .init(title: "Técnica", text: """
• Power clean com extensão completa e recepção estável
• Push-ups com core ativo
• Squats em ritmo constante
""", order: 3),
                    .init(title: "WOD", text: """
5 rounds for time:
• 10 Power cleans (135/95 lb)
• 20 Push-ups
• 30 Squats
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve / reps reduzidas
• Scale: 95/65 lb
• RX: Prescrito
• Elite: rounds rápidos com poucas pausas
""", order: 5)
                ]
            ),

            // MARK: - SUAREZ (2015)
            DefaultWorkoutSeed(
                name: "SUAREZ (2015)",
                title: "Suarez – Chipper Metabólico",
                description: "Treino de alto volume e desgaste metabólico. Exige ritmo constante e estratégia para não quebrar.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Corrida leve
Mobilidade geral
2 rounds leves:
• 6 Burpees
• 10 Push-ups
• 10 Squats
""", order: 1),
                    .init(title: "Detalhes", text: "A melhor estratégia é manter ritmo constante e dividir as reps antes da falha muscular.", order: 2),
                    .init(title: "Técnica", text: """
• Burpees com cadência e respiração ritmada
• Push-ups em séries curtas
• Squats com ritmo estável
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 50 Burpees
• 100 Push-ups
• 150 Squats
• 800 m run
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: reps reduzidas / corrida reduzida
• Scale: push-ups adaptados
• RX: Prescrito
• Elite: manter densidade alta com poucas pausas
""", order: 5)
                ]
            ),

            // MARK: - TAYLOR (2015)
            DefaultWorkoutSeed(
                name: "TAYLOR (2015)",
                title: "Taylor – Corrida + HSPU",
                description: "Hero exigente combinando corrida e grande volume de handstand push-ups. Exige resistência de ombros e pacing inteligente.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Corrida leve
Mobilidade de ombros e punhos
Prática leve:
• 2-3 séries de HSPU (ou pike) bem controladas
""", order: 1),
                    .init(title: "Detalhes", text: "Evitar falha precoce no HSPU é fundamental. Manter séries pequenas e constantes preserva o ritmo.", order: 2),
                    .init(title: "Técnica", text: """
• HSPU com core ativo e amplitude consistente
• Corrida em ritmo sustentável para “voltar” pro HSPU
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 1 mile run
• 100 Handstand push-ups
• 1 mile run
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: corrida reduzida / pike push-ups
• Scale: HSPU com abmat / reps reduzidas
• RX: Prescrito
• Elite: HSPU em séries longas e corrida forte
""", order: 5)
                ]
            ),

            // MARK: - THE SEVEN (2015)
            DefaultWorkoutSeed(
                name: "THE SEVEN (2015)",
                title: "The Seven – Chipper de Alto Volume e Resistência",
                description: "Hero WOD extremamente exigente, combinando levantamento, ginástica e corrida em grande volume. Teste completo físico e mental.",
                blocks: [
                    .init(title: "Aquecimento", text: """
800 m corrida leve
Mobilidade geral
2 rounds leves dos movimentos do treino
""", order: 1),
                    .init(title: "Detalhes", text: "Treino longo com múltiplos estímulos. Estratégia é dividir reps e manter pacing constante.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift com postura neutra
• Pull-ups eficientes
• KB swings com quadril dominante
• Respiração contínua
""", order: 3),
                    .init(title: "WOD", text: """
For time:
7 rounds:
• 7 Handstand push-ups
• 7 Thrusters (135/95 lb)
• 7 Knees-to-elbows
• 7 Deadlifts (245/165 lb)
• 7 Burpees
• 7 Kettlebell swings
• 7 Pull-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve / substituições técnicas
• Scale: carga intermediária
• RX: Prescrito
• Elite: rounds consistentes sem pausas longas
""", order: 5)
                ]
            ),

            // MARK: - THOMPSON (2015)
            DefaultWorkoutSeed(
                name: "THOMPSON (2015)",
                title: "Thompson – Endurance com Barra e Corrida",
                description: "Hero longo com rounds repetitivos, exigindo consistência e controle do ritmo em um domínio de tempo prolongado.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Corrida leve
Mobilidade de quadril/lombar
Técnica com barra vazia
""", order: 1),
                    .init(title: "Detalhes", text: "Manter rounds consistentes é a chave. Evite sprintar para não perder eficiência nos movimentos seguintes.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift com alinhamento e barra próxima
• Corrida com cadência estável
• Quebrar séries cedo para manter ritmo
""", order: 3),
                    .init(title: "WOD", text: """
10 rounds for time:
• 5 Deadlifts (135/95 lb)
• 10 Push-ups
• 15 Squats
• 100 m run
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve / corrida reduzida
• Scale: intermediário
• RX: Prescrito
• Elite: rounds contínuos com transições imediatas
""", order: 5)
                ]
            ),

            // MARK: - TOMMY V (2016)
            DefaultWorkoutSeed(
                name: "TOMMY V (2016)",
                title: "Tommy V – Barbell Cycling e Ginástica",
                description: "Treino com barra e ginástica em formato clássico 21-15-9. Exige eficiência, ritmo e transições rápidas.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de ombros
Técnica de thruster com barra leve
2 rounds leves:
• 6 Thrusters leves
• 5 Pull-ups (assistido)
""", order: 1),
                    .init(title: "Detalhes", text: "Treino curto e intenso. A estratégia é manter thrusters em séries grandes e pull-ups consistentes.", order: 2),
                    .init(title: "Técnica", text: """
• Thruster com drive de pernas e travamento firme
• Pull-ups com economia (kipping consistente)
• Transições imediatas
""", order: 3),
                    .init(title: "WOD", text: """
21-15-9 for time:
• Thrusters (115/75 lb)
• Pull-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve / ring rows
• Scale: 95/65 lb / pull-ups assistidos
• RX: Prescrito
• Elite: séries longas e rápidas
""", order: 5)
                ]
            ),

            // MARK: - TRAVIS MANION (2016)
            DefaultWorkoutSeed(
                name: "TRAVIS MANION (2016)",
                title: "Travis Manion – Lunges e Corrida com Carga",
                description: "Hero focado em resistência de membros inferiores com carga externa e corrida. Alto volume e forte exigência mental.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Caminhada leve com carga (opcional)
Mobilidade de quadril
2 rounds leves:
• 10 Lunges (passos)
• 200 m corrida leve
""", order: 1),
                    .init(title: "Detalhes", text: "Volume alto e repetitivo. Estratégia é manter ritmo constante e controlar fadiga muscular das pernas.", order: 2),
                    .init(title: "Técnica", text: """
• Lunges com postura ereta e joelho alinhado
• Corrida econômica (não sprintar)
• Respiração contínua
""", order: 3),
                    .init(title: "WOD", text: """
For time:
7 rounds:
• 400 m run
• 29 Back squats (135/95 lb)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve / reps reduzidas
• Scale: 95/65 lb
• RX: Prescrito
• Elite: rounds consistentes com pausas mínimas
""", order: 5)
                ]
            ),

            // MARK: - TULLY (2016)
            DefaultWorkoutSeed(
                name: "TULLY (2016)",
                title: "Tully – Sprint Metcon com Barra",
                description: "Treino curto e intenso combinando levantamento e corrida. Exige velocidade com técnica e transições rápidas.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Corrida leve
Mobilidade ombros/quadril
Técnica de thruster com barra leve
""", order: 1),
                    .init(title: "Detalhes", text: "Alta intensidade. A estratégia é manter thrusters consistentes e usar a corrida para “reiniciar” a respiração.", order: 2),
                    .init(title: "Técnica", text: """
• Thruster fluido e estável no overhead
• Corrida com cadência constante e boa respiração
""", order: 3),
                    .init(title: "WOD", text: """
5 rounds for time:
• 10 Thrusters (115/75 lb)
• 400 m run
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve / corrida reduzida
• Scale: 95/65 lb
• RX: Prescrito
• Elite: ritmo agressivo e transições imediatas
""", order: 5)
                ]
            ),

            // MARK: - WALSH (2016)
            DefaultWorkoutSeed(
                name: "WALSH (2016)",
                title: "Walsh – Ginástica e Resistência",
                description: "Hero focado em resistência muscular e consistência de movimentos corporais. Exige ritmo e transições rápidas.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade ombros
2 rounds leves:
• 6 Burpees
• 5 Pull-ups (assistido)
• 8 Push-ups
""", order: 1),
                    .init(title: "Detalhes", text: "Treino de densidade. A estratégia é manter movimentos em séries curtas e sem “morrer” no burpee.", order: 2),
                    .init(title: "Técnica", text: """
• Burpees com cadência estável
• Pull-ups com economia e séries pequenas
• Push-ups com core firme
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 20 min:
• 10 Burpees
• 10 Pull-ups
• 10 Push-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: ring rows / push-ups inclinados
• Scale: pull-ups assistidos
• RX: Prescrito
• Elite: rounds contínuos sem pausas longas
""", order: 5)
                ]
            ),

            // MARK: - WHITE (2016)
            DefaultWorkoutSeed(
                name: "WHITE (2016)",
                title: "White – Endurance com Corrida e Core",
                description: "Treino longo com foco em resistência cardiovascular e volume repetitivo de movimentos corporais.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Corrida leve
Mobilidade geral
2 rounds leves:
• 10 Squats
• 10 Sit-ups
""", order: 1),
                    .init(title: "Detalhes", text: "Volume contínuo. A estratégia é manter ritmo sustentável e evitar pausas longas entre movimentos.", order: 2),
                    .init(title: "Técnica", text: """
• Corrida econômica e constante
• Sit-ups com respiração ritmada
• Squats em cadência estável
""", order: 3),
                    .init(title: "WOD", text: """
For time:
5 rounds:
• 800 m run
• 50 Squats
• 50 Sit-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: corrida reduzida / reps reduzidas
• Scale: intermediário
• RX: Prescrito
• Elite: ritmo contínuo com transições rápidas
""", order: 5)
                ]
            ),

            // MARK: - WOOD (2017)
            DefaultWorkoutSeed(
                name: "WOOD (2017)",
                title: "Wood – Corrida + Deadlift sob Volume",
                description: "Hero com rounds repetitivos de corrida e deadlift. Exige resistência muscular, grip e pacing consistente.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Corrida leve
Mobilidade de quadril/lombar
2 séries leves de deadlift
""", order: 1),
                    .init(title: "Detalhes", text: "A consistência é tudo: manter deadlifts eficientes e corrida estável evita queda brusca de desempenho.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift com postura neutra e barra próxima
• Corrida com cadência estável e respiração controlada
""", order: 3),
                    .init(title: "WOD", text: """
5 rounds for time:
• 400 m run
• 20 Deadlifts (225/155 lb)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve / reps reduzidas
• Scale: 155/105 lb
• RX: Prescrito
• Elite: rounds rápidos e consistentes
""", order: 5)
                ]
            ),

            // MARK: - WRIGHT (2017)
            DefaultWorkoutSeed(
                name: "WRIGHT (2017)",
                title: "Wright – Barbell + Volume Corporal",
                description: "Treino em AMRAP com padrão clássico de força e condicionamento. Exige consistência de rounds e técnica eficiente.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade geral
Técnica de power clean com barra leve
2 rounds leves:
• 5 Power cleans leves
• 8 Push-ups
• 10 Squats
""", order: 1),
                    .init(title: "Detalhes", text: "Manter rounds estáveis é mais importante que explosões de velocidade. A consistência no clean dita o ritmo.", order: 2),
                    .init(title: "Técnica", text: """
• Power clean com extensão completa e recepção estável
• Push-ups com core ativo
• Squats em ritmo constante
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 20 min:
• 5 Power cleans
• 10 Push-ups
• 15 Squats
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve
• Scale: intermediário
• RX: Prescrito
• Elite: rounds contínuos com transições rápidas
""", order: 5)
                ]
            ),

            // MARK: - ZEMBIEC (2017)
            DefaultWorkoutSeed(
                name: "ZEMBIEC (2017)",
                title: "Zembiec – Barbell e Ginástica sob Fadiga",
                description: "Treino intenso com agachamento pesado/moderado, pull-ups e burpees. Exige técnica e consistência de rounds.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de quadril/tornozelo
Técnica de back squat com carga leve
2 rounds leves:
• 5 Pull-ups (assistido)
• 6 Burpees
""", order: 1),
                    .init(title: "Detalhes", text: "Treino de rounds curtos. A estratégia é manter o squat estável e usar o burpee para controlar a respiração.", order: 2),
                    .init(title: "Técnica", text: """
• Back squat com base firme e profundidade consistente
• Pull-ups em séries curtas e eficientes
• Burpees com cadência estável
""", order: 3),
                    .init(title: "WOD", text: """
For time:
5 rounds:
• 11 Back squats (185/135 lb)
• 10 Pull-ups
• 9 Burpees
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve / pull-ups assistidos
• Scale: 135/95 lb
• RX: Prescrito
• Elite: rounds rápidos com poucas pausas
""", order: 5)
                ]
            ),

            // MARK: - BURIak (2020)
            DefaultWorkoutSeed(
                name: "BURIAK (2020)",
                title: "Buriak – Endurance com Barra e Corrida",
                description: "Treino contínuo com corrida e trabalho de barra, exigindo resistência cardiovascular e consistência no ciclo de reps.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Corrida leve
Mobilidade de quadril/ombros
2 séries leves de deadlift e push press
""", order: 1),
                    .init(title: "Detalhes", text: "Volume contínuo. Estratégia é manter ritmo estável e evitar falha no levantamento, preservando o grip.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift com postura neutra
• Push press com drive de pernas eficiente
• Corrida com cadência constante
""", order: 3),
                    .init(title: "WOD", text: """
For time:
5 rounds:
• 400 m run
• 20 Deadlifts (185/135 lb)
• 20 Push presses (95/65 lb)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve / reps reduzidas
• Scale: intermediário
• RX: Prescrito
• Elite: rounds contínuos com transições rápidas
""", order: 5)
                ]
            ),

            // MARK: - GOOSE (2021)
            DefaultWorkoutSeed(
                name: "GOOSE (2021)",
                title: "Goose – Ginástica e Sprint Metabólico",
                description: "Treino de alta intensidade com foco em ginástica sob frequência cardíaca elevada. Exige consistência e transições rápidas.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de ombros
2 rounds leves:
• 6 Pull-ups (assistido)
• 10 Push-ups
• 10 Squats
""", order: 1),
                    .init(title: "Detalhes", text: "Treino de densidade. A estratégia é manter séries curtas e rápidas, sem pausas longas.", order: 2),
                    .init(title: "Técnica", text: """
• Pull-ups com economia (kipping consistente)
• Push-ups com core firme
• Corrida como transição ativa
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 18 min:
• 8 Pull-ups
• 16 Push-ups
• 24 Air squats
• 200 m run
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: ring rows / push-ups inclinados / corrida reduzida
• Scale: pull-ups assistidos
• RX: Prescrito
• Elite: rounds contínuos com transições imediatas
""", order: 5)
                ]
            ),

            // MARK: - GALE FORCE (2022)
            DefaultWorkoutSeed(
                name: "GALE FORCE (2022)",
                title: "Gale Force – Resistência Global em Rounds",
                description: "Treino longo combinando remo, agachamento frontal, ginástica e burpees. Exige pacing e consistência no volume.",
                blocks: [
                    .init(title: "Aquecimento", text: """
5 min remo leve
Mobilidade de quadril/tornozelo
Técnica de front squat com carga leve
2 rounds leves:
• 5 Front squats leves
• 5 Pull-ups (assistido)
• 5 Burpees
""", order: 1),
                    .init(title: "Detalhes", text: "Treino com volume alto por round. Estratégia é manter ritmo sustentável e quebrar pull-ups/burpees cedo.", order: 2),
                    .init(title: "Técnica", text: """
• Front squat com cotovelos altos e tronco firme
• Pull-ups em séries curtas
• Burpees com respiração ritmada
""", order: 3),
                    .init(title: "WOD", text: """
For time:
4 rounds:
• 500 m row
• 25 Front squats (115/75 lb)
• 25 Pull-ups
• 25 Burpees
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve / reps reduzidas
• Scale: intermediário / pull-ups assistidos
• RX: Prescrito
• Elite: manter rounds consistentes com pausas mínimas
""", order: 5)
                ]
            ),

            // MARK: - ODA 7313 (2023)
            DefaultWorkoutSeed(
                name: "ODA 7313 (2023)",
                title: "ODA 7313 – Chipper Hero de Alta Intensidade",
                description: "Hero com grande volume e movimentos variados. Exige resistência e consistência técnica sob fadiga progressiva.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade geral
2 rounds leves dos movimentos:
• 30 singles (corda)
• 8 Wall-ball shots leves
• 6 Deadlifts leves
• 5 Pull-ups (assistido)
""", order: 1),
                    .init(title: "Detalhes", text: "Chipper longo. Estratégia é dividir reps e manter ritmo estável, preservando o grip para a parte final.", order: 2),
                    .init(title: "Técnica", text: """
• Double unders com ritmo constante
• Deadlift com postura neutra
• Thruster fluido e eficiente
• Muscle-up com transição rápida (ou variação)
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 100 Double unders
• 50 Wall-ball shots
• 40 Deadlifts (185/135 lb)
• 30 Pull-ups
• 20 Thrusters (115/75 lb)
• 10 Muscle-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: singles / carga leve / ring rows
• Scale: pull-ups assistidos / thruster leve / muscle-up substituído
• RX: Prescrito
• Elite: transições rápidas e sets grandes
""", order: 5)
                ]
            ),

            // MARK: - NORTHRUP (2024)
            DefaultWorkoutSeed(
                name: "NORTHRUP (2024)",
                title: "Northrup – Endurance e Ginástica sob Volume",
                description: "Treino longo com corrida e alto volume de movimentos corporais. Exige resistência cardiovascular e consistência.",
                blocks: [
                    .init(title: "Aquecimento", text: """
800 m corrida leve
Mobilidade geral
2 rounds leves:
• 10 Push-ups
• 10 Sit-ups
• 10 Squats
""", order: 1),
                    .init(title: "Detalhes", text: "Volume alto por round. Estratégia é manter pacing constante, evitando pausas longas em push-ups.", order: 2),
                    .init(title: "Técnica", text: """
• Push-ups em séries curtas e constantes
• Sit-ups com respiração ritmada
• Corrida em ritmo sustentável
""", order: 3),
                    .init(title: "WOD", text: """
For time:
6 rounds:
• 400 m run
• 30 Push-ups
• 30 Sit-ups
• 30 Squats
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: reps reduzidas / corrida reduzida
• Scale: push-ups inclinados / sit-ups reduzidos
• RX: Prescrito
• Elite: ritmo contínuo e transições imediatas
""", order: 5)
                ]
            )
        ]
    }
}

