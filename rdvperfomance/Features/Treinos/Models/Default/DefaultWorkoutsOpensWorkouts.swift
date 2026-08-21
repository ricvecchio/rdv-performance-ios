import Foundation

extension DefaultWorkoutsCrossfit {

    static func openWodsDefaults() -> [DefaultWorkoutSeed] {
        return [

            // MARK: - OPEN 11.1
            DefaultWorkoutSeed(
                name: "OPEN 11.1",
                title: "Open 11.1 – AMRAP Burpee Ladder",
                description: "Primeiro WOD da história do CrossFit Open. Teste simples e brutal de capacidade aeróbica e resistência mental.",
                blocks: [
                    .init(title: "Aquecimento", text: """
3 rounds leves:
• 10 air squats
• 5 push-ups
• 5 burpees step
Mobilidade de quadril e ombros
""", order: 1),
                    .init(title: "Detalhes", text: "O atleta realiza burpees completos com salto e toque acima da cabeça. Ritmo constante é determinante.", order: 2),
                    .init(title: "Técnica", text: """
• Manter respiração ritmada
• Queda controlada ao solo
• Salto econômico, sem desperdício energético
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 10 min:
• Burpees
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: step burpee
• Scale: burpee sem salto alto
• RX: burpee completo com extensão total
""", order: 5)
                ]
            ),

            // MARK: - OPEN 11.2
            DefaultWorkoutSeed(
                name: "OPEN 11.2",
                title: "Open 11.2 – Chipper Técnico de Resistência",
                description: "Combinação de levantamento olímpico leve e ginástica, com grande volume e controle técnico.",
                blocks: [
                    .init(title: "Aquecimento", text: """
5 min bike leve
Técnica de toes-to-bar
Progressão de snatch leve
""", order: 1),
                    .init(title: "Detalhes", text: "Transições rápidas e economia nos toes-to-bar são fundamentais para manter ritmo.", order: 2),
                    .init(title: "Técnica", text: """
• Snatch: barra próxima ao corpo
• Toes-to-bar em ritmo constante
• Saltos eficientes nos box jumps
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 15 min:
• 9 Deadlifts (70kg)
• 12 Push-ups
• 15 Box Jumps (60cm)
• 9 Power Cleans (70kg)
• 12 Toes-to-Bar
• 15 Wall Balls (9kg)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: cargas reduzidas e knee raises
• Scale: 50kg barra / 6kg wall ball
• RX: cargas prescritas
""", order: 5)
                ]
            ),

            // MARK: - OPEN 11.3
            DefaultWorkoutSeed(
                name: "OPEN 11.3",
                title: "Open 11.3 – For Time Heavy & Gymnastics",
                description: "Prova clássica de força sob fadiga combinada com ginástica avançada.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade ombro/torácica
Pull-ups com elástico
Progressão de deadlift
""", order: 1),
                    .init(title: "Detalhes", text: "Volume crescente com aumento de carga exige estratégia de pausas.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift com coluna neutra
• Chest-to-bar com kip eficiente
• Controle de ritmo para evitar falha precoce
""", order: 3),
                    .init(title: "WOD", text: """
For time (5 min cap):
• 100 Pull-ups
• 100 Push-ups
• 100 Sit-ups
• 100 Air Squats
• 100 Deadlifts (45kg)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: reps reduzidas
• Scale: deadlift 30kg / pull-up elástico
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 11.4
            DefaultWorkoutSeed(
                name: "OPEN 11.4",
                title: "Open 11.4 – Força Máxima Sob Pressão",
                description: "Teste puro de força máxima no deadlift após fadiga acumulada.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade posterior
Deadlift progressivo
""", order: 1),
                    .init(title: "Detalhes", text: "Execução perfeita e tentativas inteligentes são essenciais.", order: 2),
                    .init(title: "Técnica", text: """
• Ativação de glúteos
• Barra colada ao corpo
• Respiração e brace abdominal
""", order: 3),
                    .init(title: "WOD", text: """
7 min para encontrar:
• 1RM Deadlift
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga moderada técnica
• Scale: buscar 5RM
• RX: 1RM
""", order: 5)
                ]
            ),

            // MARK: - OPEN 11.5
            DefaultWorkoutSeed(
                name: "OPEN 11.5",
                title: "Open 11.5 – Benchmark Revisitado (Fran Modificado)",
                description: "Versão do clássico Fran com volume ampliado. Final brutal do primeiro Open.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Thruster leve progressivo
Pull-ups técnicos
""", order: 1),
                    .init(title: "Detalhes", text: "Sprint total, controle de falha muscular e transições rápidas.", order: 2),
                    .init(title: "Técnica", text: """
• Thruster com respiração sincronizada
• Pull-ups unbroken sempre que possível
""", order: 3),
                    .init(title: "WOD", text: """
For time (20 min cap):
• 30 Thrusters (43kg)
• 30 Chest-to-Bar Pull-ups
• 20 Thrusters
• 20 Chest-to-Bar
• 10 Thrusters
• 10 Chest-to-Bar
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: 20kg barra
• Scale: pull-up elástico
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 12.1
            DefaultWorkoutSeed(
                name: "OPEN 12.1",
                title: "Open 12.1 – Burpee Endurance Test",
                description: "Treino clássico de capacidade aeróbica e resistência muscular global. Simples na estrutura, mas extremamente exigente no pacing.",
                blocks: [
                    .init(title: "Aquecimento", text: """
5 min cardio leve (remo ou bike)
3 rounds:
• 5 burpees step
• 10 air squats
Mobilidade de tornozelo e ombro
""", order: 1),
                    .init(title: "Detalhes", text: "Movimento repetitivo com impacto metabólico crescente. O controle do ritmo inicial define o desempenho final.", order: 2),
                    .init(title: "Técnica", text: """
• Queda controlada no solo
• Extensão completa de quadril no salto
• Respiração cadenciada para evitar acidose precoce
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 7 min:
• Burpees
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: burpee step-back
• Scale: salto reduzido
• RX: burpee completo com salto e extensão total
""", order: 5)
                ]
            ),

            // MARK: - OPEN 12.2
            DefaultWorkoutSeed(
                name: "OPEN 12.2",
                title: "Open 12.2 – Snatch Ladder",
                description: "Teste progressivo de levantamento olímpico, combinando técnica e resistência muscular sob fadiga.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de ombros e punhos
Técnica com PVC
Progressão de snatch leve
""", order: 1),
                    .init(title: "Detalhes", text: "Aumentos de carga exigem técnica refinada. Pausas estratégicas preservam execução segura.", order: 2),
                    .init(title: "Técnica", text: """
• Barra próxima ao corpo
• Recepção estável em overhead
• Uso eficiente do quadril
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 10 min:
• 30 Snatches (34kg)
• 30 Snatches (45kg)
• 30 Snatches (61kg)
• 30 Snatches (75kg)
• 30 Snatches (84kg)
• 30 Snatches (93kg)
Continuar aumentando conforme progressão
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: halter leve
• Scale: progressão adaptada
• RX: cargas prescritas
""", order: 5)
                ]
            ),

            // MARK: - OPEN 12.3
            DefaultWorkoutSeed(
                name: "OPEN 12.3",
                title: "Open 12.3 – Chipper Ginástico e Levantamento",
                description: "Combinação de ginástica avançada com levantamento moderado e volume elevado. Exige estratégia e consistência.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Pull-ups com elástico
Técnica de double-under
Progressão de push press
""", order: 1),
                    .init(title: "Detalhes", text: "A gestão da fadiga nos movimentos ginásticos é determinante para sustentar o ritmo.", order: 2),
                    .init(title: "Técnica", text: """
• Double-unders com salto mínimo
• Chest-to-bar com kip eficiente
• Push press usando extensão de quadril
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 18 min:
• 15 Box Jumps (60cm)
• 12 Push Press (52kg)
• 9 Toes-to-Bar
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: step box / knee raises
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 12.4
            DefaultWorkoutSeed(
                name: "OPEN 12.4",
                title: "Open 12.4 – Volume Progressivo Clássico",
                description: "Treino de volume crescente com movimentos básicos de ginástica e carga moderada. Exige pacing inteligente.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de ombros
Thrusters leves
Pull-ups com elástico
""", order: 1),
                    .init(title: "Detalhes", text: "Estratégia de divisão de repetições é essencial para evitar falha muscular.", order: 2),
                    .init(title: "Técnica", text: """
• Thruster com respiração coordenada
• Pull-ups em séries controladas
• Transições rápidas
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 12 min:
• 150 Wall Balls (9kg)
• 90 Double-Unders
• 30 Muscle-Ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: wall ball leve / singles
• Scale: chest-to-bar
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 12.5
            DefaultWorkoutSeed(
                name: "OPEN 12.5",
                title: "Open 12.5 – Final Benchmark Fran Style",
                description: "Treino de sprint metabólico inspirado no clássico Fran. Combinação explosiva de thrusters e pull-ups.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Thrusters progressivos leves
Pull-ups técnicos
Mobilidade de ombros
""", order: 1),
                    .init(title: "Detalhes", text: "Ritmo agressivo desde o início. Pausas curtas e planejadas.", order: 2),
                    .init(title: "Técnica", text: """
• Thruster fluido (front squat + push press)
• Pull-ups unbroken sempre que possível
• Respiração coordenada nas transições
""", order: 3),
                    .init(title: "WOD", text: """
For time:
3 rounds:
• 45 Thrusters (43kg)
• 45 Chest-to-Bar Pull-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: thruster leve / pull-up elástico
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 13.1
            DefaultWorkoutSeed(
                name: "OPEN 13.1",
                title: "Open 13.1 – Snatch & Burpee Capacity",
                description: "Treino que combina levantamento olímpico leve/moderado com burpees, testando coordenação, potência e capacidade aeróbica contínua.",
                blocks: [
                    .init(title: "Aquecimento", text: """
5 min remo leve
Técnica de snatch com PVC
Progressão de snatch leve
2 rounds:
• 5 burpees controlados
• 5 overhead squats leves
""", order: 1),
                    .init(title: "Detalhes", text: "A chave está no ritmo constante e na economia de movimento. Burpees rápidos demais podem comprometer os snatches.", order: 2),
                    .init(title: "Técnica", text: """
• Barra próxima ao corpo no snatch
• Recepção estável overhead
• Burpee com salto eficiente e sem pausa
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 17 min:
• 40 Burpees
• 30 Snatches (34kg)
• 30 Burpees
• 30 Snatches (61kg)
• 20 Burpees
• 30 Snatches (75kg)
• 10 Burpees
• Snatches (102kg) até o tempo acabar
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: snatch com halter leve
• Scale: cargas reduzidas progressivas
• RX: cargas prescritas
""", order: 5)
                ]
            ),

            // MARK: - OPEN 13.2
            DefaultWorkoutSeed(
                name: "OPEN 13.2",
                title: "Open 13.2 – Engine & Skill Flow",
                description: "Treino com movimentos cíclicos e ginástica técnica, exigindo eficiência de transições e constância.",
                blocks: [
                    .init(title: "Aquecimento", text: """
5 min bike leve
Técnica de shoulder-to-overhead
Double-unders progressivos
Box step jumps
""", order: 1),
                    .init(title: "Detalhes", text: "Treino de ritmo alto e sustentado. Transições rápidas impactam diretamente o score final.", order: 2),
                    .init(title: "Técnica", text: """
• Box jump com uso mínimo de braços
• Shoulder-to-overhead usando drive de quadril
• Double-unders com salto baixo e constante
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 10 min:
• 5 Shoulder-to-Overhead (52kg)
• 10 Deadlifts (52kg)
• 15 Box Jumps (60cm)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: cargas leves / step box
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 13.3
            DefaultWorkoutSeed(
                name: "OPEN 13.3",
                title: "Open 13.3 – Skill Ladder Endurance",
                description: "Progressão de ginástica avançada combinada com carga moderada. Exige estratégia para evitar falha muscular.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Pull-ups com elástico
Técnica de toes-to-bar
Push press leve progressivo
""", order: 1),
                    .init(title: "Detalhes", text: "Reps crescentes aumentam rapidamente a fadiga. Gestão do grip é essencial.", order: 2),
                    .init(title: "Técnica", text: """
• Toes-to-bar com kip eficiente
• Push press com extensão total de quadril
• Chest-to-bar em séries planejadas
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 12 min:
• 150 Wall Balls (9kg)
• 90 Double-Unders
• 30 Muscle-Ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: singles / ring rows
• Scale: chest-to-bar
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 13.4
            DefaultWorkoutSeed(
                name: "OPEN 13.4",
                title: "Open 13.4 – Clean & Gymnastics Volume",
                description: "Treino que mistura levantamento técnico com ginástica de alto volume, testando consistência e resistência muscular.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de quadril e tornozelo
Progressão de clean leve
Toes-to-bar técnico
""", order: 1),
                    .init(title: "Detalhes", text: "Controle de respiração e séries curtas ajudam a manter a qualidade técnica.", order: 2),
                    .init(title: "Técnica", text: """
• Clean com extensão completa de quadril
• Toes-to-bar com economia de swing
• Gestão de grip ao longo do treino
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 7 min:
• 3 Cleans (61kg)
• 6 Toes-to-Bar
• 9 Shoulder-to-Overhead (61kg)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: halter leve / knee raises
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 13.5
            DefaultWorkoutSeed(
                name: "OPEN 13.5",
                title: "Open 13.5 – Final Sprint Chipper",
                description: "Treino final do Open com volume elevado e exigência metabólica extrema. Similar a benchmark Fran em intensidade.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Thrusters leves progressivos
Pull-ups técnicos
Mobilidade de ombros
""", order: 1),
                    .init(title: "Detalhes", text: "Estratégia de séries e controle de falha muscular são decisivos.", order: 2),
                    .init(title: "Técnica", text: """
• Thruster fluido com respiração sincronizada
• Pull-ups unbroken quando possível
• Transições rápidas entre movimentos
""", order: 3),
                    .init(title: "WOD", text: """
For time (4 min cap inicial):
• 15 Thrusters (43kg)
• 15 Chest-to-Bar Pull-ups

Se completado dentro do cap:
• adiciona-se mais 3 min e repete o ciclo aumentando reps para 18/18, depois 21/21, etc.
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: thruster leve / pull-up elástico
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 14.1
            DefaultWorkoutSeed(
                name: "OPEN 14.1",
                title: "Open 14.1 – Skill & Engine com Corda",
                description: "Treino cíclico com alto volume de double-unders combinado a snatch leve, exigindo coordenação e constância aeróbica.",
                blocks: [
                    .init(title: "Aquecimento", text: """
5 min remo leve
Técnica de double-under (singles → doubles)
Snatch com PVC e progressão leve
""", order: 1),
                    .init(title: "Detalhes", text: "A chave é manter cadência constante na corda e evitar falhas nos snatches iniciais.", order: 2),
                    .init(title: "Técnica", text: """
• Saltos baixos e ritmados no double-under
• Snatch com barra próxima ao corpo
• Respiração contínua para evitar quebra de ritmo
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 10 min:
• 30 Double-Unders
• 15 Power Snatches (34kg)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: singles + halter leve
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 14.2
            DefaultWorkoutSeed(
                name: "OPEN 14.2",
                title: "Open 14.2 – Ginástica Progressiva Sob Fadiga",
                description: "Treino progressivo com aumento de repetições de overhead squat e chest-to-bar. Teste de resistência muscular e controle técnico.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de ombros e tornozelos
Overhead squat leve
Pull-ups e chest-to-bar técnicos
""", order: 1),
                    .init(title: "Detalhes", text: "Aumento gradual de reps gera fadiga acumulada. Estratégia de séries e respiração são essenciais.", order: 2),
                    .init(title: "Técnica", text: """
• Overhead squat com estabilidade de tronco
• Chest-to-bar com kip eficiente
• Transições rápidas entre movimentos
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP em blocos de 3 min:
• 2 Overhead Squats (43kg)
• 2 Chest-to-Bar Pull-ups

A cada bloco de 3 min:
• aumentar 2 reps de cada movimento
Continuar enquanto completar o bloco dentro do tempo
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: overhead squat leve / pull-up elástico
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 14.3
            DefaultWorkoutSeed(
                name: "OPEN 14.3",
                title: "Open 14.3 – Deadlift & Box Jump Volume",
                description: "Combinação clássica de levantamento pesado com movimento cíclico explosivo. Teste de potência e resistência muscular.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade posterior (glúteo/hamstring)
Deadlift progressivo
Box jumps leves
""", order: 1),
                    .init(title: "Detalhes", text: "Carga aumenta a cada rodada. Gestão de fadiga lombar é determinante.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift com coluna neutra
• Box jump com aterrissagem suave
• Respiração antes de cada repetição pesada
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 8 min:
• 10 Deadlifts (102kg)
• 15 Box Jumps (60cm)

A cada rodada:
• aumentar carga do deadlift progressivamente
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga moderada / step box
• Scale: progressão adaptada
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 14.4
            DefaultWorkoutSeed(
                name: "OPEN 14.4",
                title: "Open 14.4 – Chipper Completo do Open",
                description: "Treino longo com múltiplos domínios: ginástica, levantamento e resistência. Considerado um dos mais completos do Open.",
                blocks: [
                    .init(title: "Aquecimento", text: """
5 min bike leve
Técnica de toes-to-bar
Clean progressivo leve
Wall ball técnico
""", order: 1),
                    .init(title: "Detalhes", text: "Treino de pacing. Gestão de grip e transições define performance.", order: 2),
                    .init(title: "Técnica", text: """
• Toes-to-bar econômicos
• Clean com uso de quadril
• Wall ball com ciclo respiratório coordenado
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 14 min:
• 60 Row (cal)
• 50 Toes-to-Bar
• 40 Wall Balls (9kg)
• 30 Cleans (61kg)
• 20 Muscle-Ups
• Row até o tempo acabar
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: knee raises / carga reduzida
• Scale: chest-to-bar
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 14.5
            DefaultWorkoutSeed(
                name: "OPEN 14.5",
                title: "Open 14.5 – Chipper Final Sem Time Cap",
                description: "Treino final sem limite de tempo. Teste mental e físico extremo com volume elevado de thrusters e burpees.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Thrusters leves progressivos
Burpees controlados
Mobilidade de ombros
""", order: 1),
                    .init(title: "Detalhes", text: "Sem time cap, o desafio é manter consistência e evitar pausas longas.", order: 2),
                    .init(title: "Técnica", text: """
• Thruster fluido com respiração coordenada
• Burpee com queda controlada
• Estratégia de séries desde o início
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 21 Thrusters (43kg)
• 21 Burpees over bar
• 18 Thrusters
• 18 Burpees
• 15 Thrusters
• 15 Burpees
• 12 Thrusters
• 12 Burpees
• 9 Thrusters
• 9 Burpees
• 6 Thrusters
• 6 Burpees
• 3 Thrusters
• 3 Burpees
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: thruster leve / burpee step
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 15.1
            DefaultWorkoutSeed(
                name: "OPEN 15.1",
                title: "Open 15.1 – Engine + Grip Capacity",
                description: "Treino que combina movimentos cíclicos e ginásticos, exigindo resistência de grip e consistência aeróbica.",
                blocks: [
                    .init(title: "Aquecimento", text: """
5 min remo leve
Técnica de toes-to-bar
Deadlift progressivo leve
Double-unders técnicos
""", order: 1),
                    .init(title: "Detalhes", text: "Grip e controle respiratório são os fatores limitantes. Ritmo constante evita quebra precoce.", order: 2),
                    .init(title: "Técnica", text: """
• Toes-to-bar com kip eficiente
• Deadlift com coluna neutra
• Double-unders com salto econômico
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 9 min:
• 15 Toes-to-Bar
• 10 Deadlifts (52kg)
• 5 Snatches (52kg)
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: knee raises / halter leve
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 15.1A
            DefaultWorkoutSeed(
                name: "OPEN 15.1A",
                title: "Open 15.1A – Clean & Jerk Max",
                description: "Prova complementar focada em força máxima após fadiga metabólica.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de quadril e ombro
Técnica de clean & jerk com PVC
Progressão de carga leve
""", order: 1),
                    .init(title: "Detalhes", text: "Gestão de tentativas e execução técnica perfeita são determinantes.", order: 2),
                    .init(title: "Técnica", text: """
• Extensão completa de quadril
• Recepção estável no jerk
• Respiração e brace abdominal
""", order: 3),
                    .init(title: "WOD", text: """
6 min para encontrar:
• 1RM Clean & Jerk
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga moderada técnica
• Scale: busca de carga confortável
• RX: 1RM
""", order: 5)
                ]
            ),

            // MARK: - OPEN 15.2
            DefaultWorkoutSeed(
                name: "OPEN 15.2",
                title: "Open 15.2 – Gymnastics & Barbell Progression",
                description: "Treino progressivo com aumento de reps combinando ginástica e thrusters. Altamente metabólico.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Thrusters leves
Pull-ups técnicos
Mobilidade de ombros
""", order: 1),
                    .init(title: "Detalhes", text: "Gestão de séries e respiração evita falha muscular precoce.", order: 2),
                    .init(title: "Técnica", text: """
• Thruster fluido
• Chest-to-bar com kip eficiente
• Transições rápidas
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP em blocos de 3 min:
• 2 Thrusters (43kg)
• 2 Chest-to-Bar Pull-ups

A cada bloco:
• adicionar 2 reps de cada movimento
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: thruster leve / pull-up elástico
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 15.3
            DefaultWorkoutSeed(
                name: "OPEN 15.3",
                title: "Open 15.3 – Ginástica Avançada & Levantamento",
                description: "Treino técnico com handstand push-ups e snatch, exigindo coordenação e controle sob fadiga.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de ombro
HSPU progressivo na parede
Snatch leve técnico
""", order: 1),
                    .init(title: "Detalhes", text: "Controle do ombro e estratégia de séries são essenciais.", order: 2),
                    .init(title: "Técnica", text: """
• HSPU com linha corporal alinhada
• Snatch com barra próxima ao corpo
• Respiração controlada
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 14 min:
• 7 Muscle-Ups
• 50 Wall Balls (9kg)
• 100 Double-Unders
• 50 Wall Balls
• 7 Muscle-Ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: ring rows / singles
• Scale: chest-to-bar
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 15.4
            DefaultWorkoutSeed(
                name: "OPEN 15.4",
                title: "Open 15.4 – Deadlift & Handstand Push-Up Volume",
                description: "Treino exigente para cadeia posterior e ombros. Alto volume sob fadiga acumulada.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade posterior
Deadlift leve progressivo
HSPU técnico
""", order: 1),
                    .init(title: "Detalhes", text: "Controle lombar e estratégia de pausas são fundamentais.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift com coluna neutra
• HSPU com ritmo constante
• Gestão de grip
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 8 min:
• 3 Deadlifts (143kg)
• 3 HSPU

A cada rodada:
• adicionar 3 reps de cada movimento
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: deadlift leve / pike push-up
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 15.5
            DefaultWorkoutSeed(
                name: "OPEN 15.5",
                title: "Open 15.5 – Final Row & Thruster Sprint",
                description: "Treino final do Open com combinação metabólica clássica: remo e thrusters. Exige sprint controlado.",
                blocks: [
                    .init(title: "Aquecimento", text: """
5 min remo leve
Thrusters progressivos
Mobilidade de ombro
""", order: 1),
                    .init(title: "Detalhes", text: "Pacing no remo e transição rápida para thrusters são decisivos.", order: 2),
                    .init(title: "Técnica", text: """
• Remo com cadência constante
• Thruster fluido com respiração coordenada
• Transições imediatas
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 27 cal Row
• 27 Thrusters (43kg)
• 21 cal Row
• 21 Thrusters
• 15 cal Row
• 15 Thrusters
• 9 cal Row
• 9 Thrusters
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: remo reduzido / thruster leve
• Scale: carga adaptada
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 16.1
            DefaultWorkoutSeed(
                name: "OPEN 16.1",
                title: "Open 16.1 – Chipper Longo de Resistência",
                description: "Treino longo e contínuo que combina levantamento, ginástica e movimentos cíclicos. Testa resistência global e pacing.",
                blocks: [
                    .init(title: "Aquecimento", text: """
5 min remo leve
Mobilidade de quadril e ombros
Deadlift progressivo leve
Lunges e burpees controlados
""", order: 1),
                    .init(title: "Detalhes", text: "Treino de gestão energética. Ritmo constante evita queda de performance nas rodadas finais.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift com coluna neutra
• Lunges com tronco ereto
• Burpee over bar com salto eficiente
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 20 min:
• 25-ft Overhead Walking Lunges (43kg)
• 8 Burpees over bar
• 25-ft Overhead Walking Lunges
• 8 Chest-to-Bar Pull-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: halter leve / lunges sem carga
• Scale: carga reduzida / pull-up com elástico
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 16.2
            DefaultWorkoutSeed(
                name: "OPEN 16.2",
                title: "Open 16.2 – Interval Ladder Complex",
                description: "Treino em blocos com aumento progressivo de reps e carga. Exige estratégia e consistência técnica.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Double-unders técnicos
Toes-to-bar progressivos
Squat clean leve
""", order: 1),
                    .init(title: "Detalhes", text: "Cada bloco exige completar as reps antes do tempo para avançar. Gestão do grip é fundamental.", order: 2),
                    .init(title: "Técnica", text: """
• Double-unders com salto mínimo
• Toes-to-bar com swing controlado
• Squat clean com recepção estável
""", order: 3),
                    .init(title: "WOD", text: """
Blocos de 4 min:
• 25 Toes-to-Bar
• 50 Double-Unders
• 15 Squat Cleans (61kg)

Se completar dentro do tempo:
• avançar para o próximo bloco aumentando carga e reps
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: knee raises / singles / halter leve
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 16.3
            DefaultWorkoutSeed(
                name: "OPEN 16.3",
                title: "Open 16.3 – Ginástica Avançada & Snatch",
                description: "Treino técnico que combina ginástica avançada com levantamento olímpico leve, exigindo coordenação sob fadiga.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Muscle-ups progressivos
Snatch leve técnico
Mobilidade de ombro
""", order: 1),
                    .init(title: "Detalhes", text: "Transições rápidas e economia de movimento são determinantes.", order: 2),
                    .init(title: "Técnica", text: """
• Bar muscle-up com kip eficiente
• Snatch fluido com barra próxima
• Respiração controlada
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 7 min:
• 10 Power Snatches (34kg)
• 3 Bar Muscle-Ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: halter leve / jumping muscle-up
• Scale: pull-up + dip
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 16.4
            DefaultWorkoutSeed(
                name: "OPEN 16.4",
                title: "Open 16.4 – Chipper Metabólico Completo",
                description: "Treino longo e variado envolvendo remo, levantamento e ginástica. Forte impacto cardiovascular.",
                blocks: [
                    .init(title: "Aquecimento", text: """
5 min remo leve
Deadlift progressivo
Wall balls técnicos
Handstand push-ups progressivos
""", order: 1),
                    .init(title: "Detalhes", text: "Pacing e gestão de grip são essenciais para avançar no chipper.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift eficiente
• Wall ball com ciclo respiratório
• HSPU com linha corporal alinhada
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 13 min:
• 55 Deadlifts (102kg)
• 55 Wall Balls (9kg)
• 55 cal Row
• 55 Handstand Push-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve / pike push-up
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 16.5
            DefaultWorkoutSeed(
                name: "OPEN 16.5",
                title: "Open 16.5 – Final Clássico Thruster & Burpee",
                description: "Treino final no estilo benchmark. Volume progressivo de thrusters e burpees over bar sem limite de tempo.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Thrusters leves progressivos
Burpees controlados
Mobilidade de ombros
""", order: 1),
                    .init(title: "Detalhes", text: "Gestão de séries e controle de respiração são decisivos. Alto desgaste metabólico.", order: 2),
                    .init(title: "Técnica", text: """
• Thruster fluido
• Burpee com salto eficiente
• Transições rápidas
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 21 Thrusters (43kg)
• 21 Burpees over bar
• 18 Thrusters
• 18 Burpees
• 15 Thrusters
• 15 Burpees
• 12 Thrusters
• 12 Burpees
• 9 Thrusters
• 9 Burpees
• 6 Thrusters
• 6 Burpees
• 3 Thrusters
• 3 Burpees
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: thruster leve / burpee step
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 17.1
            DefaultWorkoutSeed(
                name: "OPEN 17.1",
                title: "Open 17.1 – Dumbbell Snatch & Burpee Box Jump Over",
                description: "Primeiro Open a introduzir dumbbells. Treino cíclico, técnico e altamente metabólico, exigindo resistência e coordenação.",
                blocks: [
                    .init(title: "Aquecimento", text: """
5 min bike leve
Snatch com halter leve alternado
Burpee step-over box
Mobilidade de ombro e quadril
""", order: 1),
                    .init(title: "Detalhes", text: "Volume progressivo exige pacing. Alternância de braços no snatch reduz fadiga localizada.", order: 2),
                    .init(title: "Técnica", text: """
• Snatch com extensão total de quadril
• Alternância eficiente de mãos
• Burpee box jump over com transição rápida
""", order: 3),
                    .init(title: "WOD", text: """
For time (20 min cap):
• 10 Dumbbell Snatches (22,5kg)
• 15 Burpee Box Jump Overs (60cm)
• 20 Dumbbell Snatches
• 15 Burpees
• 30 Dumbbell Snatches
• 15 Burpees
• 40 Dumbbell Snatches
• 15 Burpees
• 50 Dumbbell Snatches
• 15 Burpees
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: halter leve / step over
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 17.2
            DefaultWorkoutSeed(
                name: "OPEN 17.2",
                title: "Open 17.2 – Interval Engine & Gymnastics",
                description: "Treino intervalado com remo, dumbbell lunges e ginástica avançada. Alta exigência cardiovascular.",
                blocks: [
                    .init(title: "Aquecimento", text: """
5 min remo leve
Lunges com halter leve
Toes-to-bar técnicos
Double-unders progressivos
""", order: 1),
                    .init(title: "Detalhes", text: "Cada bloco tem tempo definido para completar reps e avançar.", order: 2),
                    .init(title: "Técnica", text: """
• Remo com cadência constante
• Lunges com tronco estável
• Toes-to-bar econômicos
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP em blocos de 4 min:
• 50-ft Dumbbell Walking Lunges (22,5kg)
• 16 Toes-to-Bar
• 8 Power Cleans (61kg)

Se completar antes do tempo:
• avançar e aumentar reps
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: lunges sem carga / knee raises
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 17.3
            DefaultWorkoutSeed(
                name: "OPEN 17.3",
                title: "Open 17.3 – Pulling Strength & Snatch Ladder",
                description: "Treino técnico com ginástica avançada e snatch progressivo. Exige controle de grip e técnica refinada.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Pull-ups técnicos
Muscle-ups progressivos
Snatch leve
""", order: 1),
                    .init(title: "Detalhes", text: "Movimentos aumentam em complexidade. Estratégia de pausas é essencial.", order: 2),
                    .init(title: "Técnica", text: """
• Chest-to-bar eficiente
• Bar muscle-up com kip coordenado
• Snatch com barra próxima ao corpo
""", order: 3),
                    .init(title: "WOD", text: """
Time cap 24 min:
• 6 Chest-to-Bar Pull-ups
• 6 Squat Snatches (43kg)
• 7 Chest-to-Bar
• 5 Squat Snatches (52kg)
• 8 Chest-to-Bar
• 4 Squat Snatches (61kg)
• 9 Chest-to-Bar
• 3 Squat Snatches (70kg)
• 10 Chest-to-Bar
• 2 Squat Snatches (79kg)
• 11 Chest-to-Bar
• 1 Squat Snatch (88kg)
Continuar progressão com bar muscle-ups e cargas maiores.
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: pull-up elástico / snatch leve
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 17.4
            DefaultWorkoutSeed(
                name: "OPEN 17.4",
                title: "Open 17.4 – Chipper Completo de Força e Ginástica",
                description: "Treino longo combinando deadlift pesado e ginástica técnica. Alta exigência de resistência muscular.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Deadlift progressivo
Wall balls leves
Remo leve
HSPU técnico
""", order: 1),
                    .init(title: "Detalhes", text: "Gestão de grip e lombar define o avanço no chipper.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift eficiente
• Wall ball com respiração coordenada
• HSPU com linha corporal estável
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 13 min:
• 55 Deadlifts (102kg)
• 55 Wall Balls (9kg)
• 55 cal Row
• 55 Handstand Push-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve / pike push-up
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 17.5
            DefaultWorkoutSeed(
                name: "OPEN 17.5",
                title: "Open 17.5 – Final Thruster & Double-Under",
                description: "Treino final de sprint metabólico combinando levantamento e corda. Alto desgaste cardiovascular.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Thrusters leves
Double-unders técnicos
Mobilidade de ombro
""", order: 1),
                    .init(title: "Detalhes", text: "Transições rápidas e ritmo consistente são fundamentais.", order: 2),
                    .init(title: "Técnica", text: """
• Thruster fluido
• Double-unders com salto mínimo
• Respiração coordenada
""", order: 3),
                    .init(title: "WOD", text: """
For time (40 min cap):
• 10 rounds:
    • 9 Thrusters (43kg)
    • 35 Double-Unders
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: singles / thruster leve
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 18.1
            DefaultWorkoutSeed(
                name: "OPEN 18.1",
                title: "Open 18.1 – Engine Longo com Dumbbell",
                description: "Treino de longa duração combinando remo, ginástica e levantamento com halter. Exige pacing consistente e resistência de grip.",
                blocks: [
                    .init(title: "Aquecimento", text: """
5 min remo leve
Toes-to-bar técnicos
Hang clean com halter leve
Mobilidade de quadril e ombro
""", order: 1),
                    .init(title: "Detalhes", text: "Volume contínuo e progressivo. Transições rápidas impactam diretamente o score.", order: 2),
                    .init(title: "Técnica", text: """
• Remo com cadência estável
• Toes-to-bar com swing eficiente
• Hang clean com uso do quadril
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 20 min:
• 8 Toes-to-Bar
• 10 Dumbbell Hang Clean & Jerks (22,5kg)
• 14/12 cal Row
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: knee raises / halter leve
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 18.2
            DefaultWorkoutSeed(
                name: "OPEN 18.2",
                title: "Open 18.2 – Sprint Ginástico e Barbell",
                description: "Treino curto e intenso com ginástica e levantamento moderado. Ritmo alto e execução técnica.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Thrusters leves
Pull-ups técnicos
Mobilidade de ombro
""", order: 1),
                    .init(title: "Detalhes", text: "Sprint metabólico. Transições rápidas são determinantes.", order: 2),
                    .init(title: "Técnica", text: """
• Thruster fluido
• Pull-ups com kip eficiente
• Respiração coordenada
""", order: 3),
                    .init(title: "WOD", text: """
For time (12 min cap):
1-2-3-4-5-6-7-8-9-10 reps de:
• Dumbbell Squat (22,5kg)
• Bar-Facing Burpees
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: halter leve / step burpee
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 18.2A
            DefaultWorkoutSeed(
                name: "OPEN 18.2A",
                title: "Open 18.2A – Front Squat Max",
                description: "Prova complementar de força máxima após esforço metabólico.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de quadril
Front squat progressivo leve
""", order: 1),
                    .init(title: "Detalhes", text: "Gestão de tentativas e técnica são essenciais.", order: 2),
                    .init(title: "Técnica", text: """
• Cotovelos altos
• Tronco estável
• Respiração e brace abdominal
""", order: 3),
                    .init(title: "WOD", text: """
5 min para encontrar:
• 1RM Front Squat
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga moderada técnica
• Scale: carga confortável
• RX: 1RM
""", order: 5)
                ]
            ),

            // MARK: - OPEN 18.3
            DefaultWorkoutSeed(
                name: "OPEN 18.3",
                title: "Open 18.3 – Skills Complex Chipper",
                description: "Treino técnico e completo com ginástica avançada, levantamento e corda. Testa domínio técnico sob fadiga.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Double-unders técnicos
Pull-ups e muscle-ups progressivos
Snatch leve
""", order: 1),
                    .init(title: "Detalhes", text: "Progressão técnica exige controle e economia de movimento.", order: 2),
                    .init(title: "Técnica", text: """
• Double-unders com salto baixo
• Pull-ups e muscle-ups com kip eficiente
• Snatch com barra próxima ao corpo
""", order: 3),
                    .init(title: "WOD", text: """
Time cap 14 min:
• 100 Double-Unders
• 20 Overhead Squats (52kg)
• 100 Double-Unders
• 12 Ring Muscle-Ups
• 100 Double-Unders
• 20 Dumbbell Snatches (22,5kg)
• 100 Double-Unders
• 12 Bar Muscle-Ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: singles / ring rows
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 18.4
            DefaultWorkoutSeed(
                name: "OPEN 18.4",
                title: "Open 18.4 – Deadlift & HSPU Chipper",
                description: "Treino exigente combinando levantamento pesado e ginástica avançada. Testa força e resistência muscular.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Deadlift progressivo
HSPU técnico
Mobilidade posterior
""", order: 1),
                    .init(title: "Detalhes", text: "Controle de lombar e estratégia de séries são fundamentais.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift com coluna neutra
• HSPU com linha corporal alinhada
• Respiração controlada
""", order: 3),
                    .init(title: "WOD", text: """
For time (9 min cap):
• 21 Deadlifts (102kg)
• 21 Handstand Push-ups
• 15 Deadlifts
• 15 HSPU
• 9 Deadlifts
• 9 HSPU

Se completar dentro do cap:
• 21 Deadlifts (143kg)
• 50-ft Handstand Walk
• 15 Deadlifts
• 50-ft Handstand Walk
• 9 Deadlifts
• 50-ft Handstand Walk
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve / pike push-up
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 18.5
            DefaultWorkoutSeed(
                name: "OPEN 18.5",
                title: "Open 18.5 – Final Thruster & Pull-Up Ladder",
                description: "Treino final com estrutura tipo Fran, escolhido por votação da comunidade. Alto volume e intensidade.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Thrusters leves
Pull-ups técnicos
Mobilidade de ombro
""", order: 1),
                    .init(title: "Detalhes", text: "Estratégia de séries e transições rápidas são decisivas.", order: 2),
                    .init(title: "Técnica", text: """
• Thruster fluido com respiração coordenada
• Pull-ups unbroken quando possível
• Controle do ritmo inicial
""", order: 3),
                    .init(title: "WOD", text: """
For time:
3-6-9-12-15-18-21 reps de:
• Thrusters (43kg)
• Chest-to-Bar Pull-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: thruster leve / pull-up elástico
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 19.1
            DefaultWorkoutSeed(
                name: "OPEN 19.1",
                title: "Open 19.1 – Engine & Full Body Capacity",
                description: "Treino longo e cíclico com wall balls e remo, exigindo resistência muscular e consistência aeróbica.",
                blocks: [
                    .init(title: "Aquecimento", text: """
5 min remo leve
Wall balls leves
Mobilidade de quadril e tornozelo
""", order: 1),
                    .init(title: "Detalhes", text: "Treino de ritmo constante. Pausas longas prejudicam fortemente o score.", order: 2),
                    .init(title: "Técnica", text: """
• Wall ball com ciclo respiratório sincronizado
• Arremesso consistente para o alvo
• Remo com cadência controlada
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 15 min:
• 19 Wall Balls (9kg)
• 19 cal Row
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: wall ball leve / remo reduzido
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 19.2
            DefaultWorkoutSeed(
                name: "OPEN 19.2",
                title: "Open 19.2 – Interval Gymnastics & Barbell",
                description: "Treino progressivo com ginástica e levantamento, repetindo o clássico 16.2. Exige estratégia e resistência de grip.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Double-unders técnicos
Toes-to-bar progressivos
Squat clean leve
""", order: 1),
                    .init(title: "Detalhes", text: "Cada bloco exige conclusão antes do tempo para avançar.", order: 2),
                    .init(title: "Técnica", text: """
• Double-unders com salto mínimo
• Toes-to-bar econômicos
• Squat clean com recepção estável
""", order: 3),
                    .init(title: "WOD", text: """
Blocos de 4 min:
• 25 Toes-to-Bar
• 50 Double-Unders
• 15 Squat Cleans (61kg)

Se completar dentro do tempo:
• avançar com aumento progressivo de carga e reps
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: knee raises / singles / halter leve
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 19.3
            DefaultWorkoutSeed(
                name: "OPEN 19.3",
                title: "Open 19.3 – Skills Complex & Grip Test",
                description: "Treino técnico com alto volume de ginástica e levantamento moderado, exigindo domínio técnico e resistência muscular.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de ombro
HSPU progressivo
Lunges com halter leve
Step-ups técnicos
""", order: 1),
                    .init(title: "Detalhes", text: "Treino de progressão longa. Grip e ombros são limitantes.", order: 2),
                    .init(title: "Técnica", text: """
• HSPU com linha corporal alinhada
• Lunges com estabilidade
• Step-ups controlados
""", order: 3),
                    .init(title: "WOD", text: """
For time (10 min cap):
• 200-ft Dumbbell Overhead Lunges (22,5kg)
• 50 Dumbbell Box Step-Ups
• 50 Strict Handstand Push-ups
• 200-ft Handstand Walk
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: lunges sem carga / pike push-up
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 19.4
            DefaultWorkoutSeed(
                name: "OPEN 19.4",
                title: "Open 19.4 – Deadlift & Sprint Gymnastics",
                description: "Treino curto e intenso com levantamento pesado e ginástica explosiva.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Deadlift progressivo
Mobilidade posterior
HSPU técnico
""", order: 1),
                    .init(title: "Detalhes", text: "Sprint com gestão de fadiga lombar e de ombros.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift com postura neutra
• HSPU com ritmo constante
• Transições rápidas
""", order: 3),
                    .init(title: "WOD", text: """
For time (9 min cap):
• 3 rounds:
    • 10 Snatches (43kg)
    • 12 Bar-Facing Burpees

Se completar:
• 3 rounds:
    • 10 Bar Muscle-Ups
    • 12 Bar-Facing Burpees
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: halter leve / step burpee
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 19.5
            DefaultWorkoutSeed(
                name: "OPEN 19.5",
                title: "Open 19.5 – Final Chipper de Resistência",
                description: "Treino final com volume elevado de thrusters e pull-ups. Alta demanda metabólica e muscular.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Thrusters leves progressivos
Pull-ups técnicos
Mobilidade de ombro
""", order: 1),
                    .init(title: "Detalhes", text: "Controle de séries e respiração é decisivo.", order: 2),
                    .init(title: "Técnica", text: """
• Thruster fluido
• Pull-ups com kip eficiente
• Transições rápidas
""", order: 3),
                    .init(title: "WOD", text: """
For time (20 min cap):
• 33 Thrusters (43kg)
• 33 Chest-to-Bar Pull-ups
• 27 Thrusters
• 27 Chest-to-Bar
• 21 Thrusters
• 21 Chest-to-Bar
• 15 Thrusters
• 15 Chest-to-Bar
• 9 Thrusters
• 9 Chest-to-Bar
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: thruster leve / pull-up elástico
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 20.1
            DefaultWorkoutSeed(
                name: "OPEN 20.1",
                title: "Open 20.1 – Chipper de Ginástica e Dumbbell",
                description: "Treino longo combinando movimentos ginásticos e levantamento unilateral com halter. Testa coordenação, resistência e pacing.",
                blocks: [
                    .init(title: "Aquecimento", text: """
5 min remo leve
Ground-to-overhead com halter leve
Mobilidade de ombros
Lunges e burpees controlados
""", order: 1),
                    .init(title: "Detalhes", text: "Alternância de braços no dumbbell reduz fadiga. Estratégia de respiração e ritmo constante são essenciais.", order: 2),
                    .init(title: "Técnica", text: """
• Dumbbell snatch com extensão completa do quadril
• Bar-facing burpee com transição eficiente
• Lunges com estabilidade de tronco
""", order: 3),
                    .init(title: "WOD", text: """
For time (15 min cap):
• 10 Ground-to-Overheads (Dumbbell 22,5kg)
• 15 Bar-Facing Burpees
• 20 Ground-to-Overheads
• 15 Burpees
• 30 Ground-to-Overheads
• 15 Burpees
• 40 Ground-to-Overheads
• 15 Burpees
• 50 Ground-to-Overheads
• 15 Burpees
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: halter leve / step burpee
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 20.2
            DefaultWorkoutSeed(
                name: "OPEN 20.2",
                title: "Open 20.2 – Engine & Skill Interval",
                description: "Treino intervalado que combina ginástica e levantamento técnico. Alta demanda cardiovascular.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Double-unders técnicos
Toes-to-bar progressivos
Dumbbell thrusters leves
""", order: 1),
                    .init(title: "Detalhes", text: "Transições rápidas são fundamentais para manter o ritmo.", order: 2),
                    .init(title: "Técnica", text: """
• Double-unders com salto mínimo
• Toes-to-bar eficientes
• Thruster com drive de quadril
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 20 min:
• 4 Dumbbell Thrusters (22,5kg)
• 6 Toes-to-Bar
• 24 Double-Unders
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: singles / knee raises
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 20.3
            DefaultWorkoutSeed(
                name: "OPEN 20.3",
                title: "Open 20.3 – Deadlift Heavy & Gymnastics",
                description: "Treino que combina levantamento pesado e ginástica técnica, exigindo força e resistência muscular.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Deadlift progressivo
Mobilidade posterior
HSPU técnico
""", order: 1),
                    .init(title: "Detalhes", text: "Estratégia de séries e controle de fadiga são essenciais para avançar.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift com coluna neutra
• Handstand push-ups com alinhamento corporal
• Respiração coordenada
""", order: 3),
                    .init(title: "WOD", text: """
For time (9 min cap):
• 21 Deadlifts (102kg)
• 21 Handstand Push-ups
• 15 Deadlifts
• 15 HSPU
• 9 Deadlifts
• 9 HSPU

Se completar dentro do cap:
• 21 Deadlifts (143kg)
• 50-ft Handstand Walk
• 15 Deadlifts
• 50-ft Handstand Walk
• 9 Deadlifts
• 50-ft Handstand Walk
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve / pike push-up
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 20.4
            DefaultWorkoutSeed(
                name: "OPEN 20.4",
                title: "Open 20.4 – Clean Ladder & Bar-Facing Burpees",
                description: "Treino técnico com progressão de carga em clean and jerk combinada com burpees. Teste de força sob fadiga.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Clean técnico com PVC
Progressão de carga leve
Burpees controlados
""", order: 1),
                    .init(title: "Detalhes", text: "Aumentos de carga exigem execução perfeita. Gestão de tentativas é determinante.", order: 2),
                    .init(title: "Técnica", text: """
• Clean com extensão total do quadril
• Jerk com recepção estável
• Burpee com ritmo constante
""", order: 3),
                    .init(title: "WOD", text: """
For time (20 min cap):
• 30 Clean & Jerks (61kg)
• 15 Bar-Facing Burpees
• 30 Clean & Jerks (84kg)
• 15 Burpees
• 30 Clean & Jerks (102kg)
• 15 Burpees
• 30 Clean & Jerks (124kg)
• 15 Burpees
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve
• Scale: progressão adaptada
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 20.5
            DefaultWorkoutSeed(
                name: "OPEN 20.5",
                title: "Open 20.5 – Final Gymnastics & Row",
                description: "Treino final focado em resistência cardiovascular e ginástica avançada.",
                blocks: [
                    .init(title: "Aquecimento", text: """
5 min remo leve
Pull-ups e muscle-ups progressivos
Mobilidade de ombro
""", order: 1),
                    .init(title: "Detalhes", text: "Gestão de grip e ritmo no remo são determinantes.", order: 2),
                    .init(title: "Técnica", text: """
• Remo com cadência constante
• Pull-ups e muscle-ups eficientes
• Transições rápidas
""", order: 3),
                    .init(title: "WOD", text: """
For time (20 min cap):
• 40 cal Row
• 120 Wall Balls (9kg)
• 40 Pull-ups
• 20 Muscle-Ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: remo reduzido / ring rows
• Scale: chest-to-bar
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 21.1
            DefaultWorkoutSeed(
                name: "OPEN 21.1",
                title: "Open 21.1 – Wall Walk & Double-Under Endurance",
                description: "Treino focado em ginástica de ombro e coordenação com corda. Alta exigência de resistência muscular e controle corporal.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de ombro e punho
Pike push-ups
Progressão de wall walk
Double-unders leves
""", order: 1),
                    .init(title: "Detalhes", text: "Movimento de wall walk gera fadiga acumulada nos ombros. Ritmo constante é fundamental.", order: 2),
                    .init(title: "Técnica", text: """
• Core ativo durante o wall walk
• Controle na descida e subida
• Double-unders com salto mínimo
""", order: 3),
                    .init(title: "WOD", text: """
For time (15 min cap):
• 1 Wall Walk
• 10 Double-Unders
• 3 Wall Walks
• 30 Double-Unders
• 6 Wall Walks
• 60 Double-Unders
• 9 Wall Walks
• 90 Double-Unders
• 15 Wall Walks
• 150 Double-Unders
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: bear crawl parcial / singles
• Scale: reps reduzidas
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 21.2
            DefaultWorkoutSeed(
                name: "OPEN 21.2",
                title: "Open 21.2 – Dumbbell Snatch & Burpee Box Jump Over",
                description: "Repetição do clássico 17.1. Treino cíclico e altamente metabólico com alternância de braços.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Snatch com halter leve
Burpee step-over box
Mobilidade de ombro e quadril
""", order: 1),
                    .init(title: "Detalhes", text: "Volume progressivo exige pacing. Grip e respiração são limitantes.", order: 2),
                    .init(title: "Técnica", text: """
• Snatch com extensão completa do quadril
• Alternância eficiente de braços
• Burpee box jump over com economia de movimento
""", order: 3),
                    .init(title: "WOD", text: """
For time (20 min cap):
• 10 Dumbbell Snatches (22,5kg)
• 15 Burpee Box Jump Overs
• 20 Dumbbell Snatches
• 15 Burpees
• 30 Dumbbell Snatches
• 15 Burpees
• 40 Dumbbell Snatches
• 15 Burpees
• 50 Dumbbell Snatches
• 15 Burpees
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: halter leve / step over
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 21.3
            DefaultWorkoutSeed(
                name: "OPEN 21.3",
                title: "Open 21.3 – Complexo Ginástico e Levantamento",
                description: "Treino técnico que combina ginástica avançada com levantamento moderado e movimentos cíclicos.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Front squats leves
Toes-to-bar técnicos
Thrusters leves
Pull-ups progressivos
""", order: 1),
                    .init(title: "Detalhes", text: "Controle técnico e gestão de séries são fundamentais para avançar.", order: 2),
                    .init(title: "Técnica", text: """
• Front squat com tronco estável
• Toes-to-bar econômicos
• Thruster fluido
""", order: 3),
                    .init(title: "WOD", text: """
For time (15 min cap):
• 30 Front Squats (43kg)
• 30 Toes-to-Bar
• 30 Thrusters (29kg)
• 30 Chest-to-Bar Pull-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve / knee raises
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 21.3A
            DefaultWorkoutSeed(
                name: "OPEN 21.3A",
                title: "Open 21.3A – Complexo de Força",
                description: "Prova complementar de força máxima após fadiga metabólica.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Clean técnico com PVC
Progressão de carga leve
""", order: 1),
                    .init(title: "Detalhes", text: "Execução técnica e estratégia de tentativas são determinantes.", order: 2),
                    .init(title: "Técnica", text: """
• Clean com extensão completa
• Jerk estável overhead
• Brace abdominal
""", order: 3),
                    .init(title: "WOD", text: """
7 min para encontrar:
• Complexo:
    • 1 Front Squat
    • 1 Clean
    • 1 Jerk
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga técnica
• Scale: progressão confortável
• RX: carga máxima possível
""", order: 5)
                ]
            ),

            // MARK: - OPEN 21.4
            DefaultWorkoutSeed(
                name: "OPEN 21.4",
                title: "Open 21.4 – Deadlift & Handstand Push-Up Progression",
                description: "Treino com aumento progressivo de reps combinando força e ginástica.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Deadlift progressivo leve
HSPU técnico
Mobilidade posterior
""", order: 1),
                    .init(title: "Detalhes", text: "Controle lombar e estratégia de séries são essenciais.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift com coluna neutra
• HSPU com alinhamento corporal
• Respiração coordenada
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 8 min:
• 3 Deadlifts (102kg)
• 3 HSPU

A cada rodada:
• adicionar 3 reps de cada movimento
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve / pike push-up
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 21.5
            DefaultWorkoutSeed(
                name: "OPEN 21.5",
                title: "Open 21.5 – Final Thruster & Row Sprint",
                description: "Treino final com alta exigência cardiovascular e volume de levantamento moderado.",
                blocks: [
                    .init(title: "Aquecimento", text: """
5 min remo leve
Thrusters leves progressivos
Mobilidade de ombro
""", order: 1),
                    .init(title: "Detalhes", text: "Pacing no remo e transições rápidas definem o desempenho.", order: 2),
                    .init(title: "Técnica", text: """
• Remo com cadência constante
• Thruster fluido com respiração coordenada
• Transições rápidas
""", order: 3),
                    .init(title: "WOD", text: """
For time (20 min cap):
• 27 cal Row
• 27 Thrusters (43kg)
• 21 cal Row
• 21 Thrusters
• 15 cal Row
• 15 Thrusters
• 9 cal Row
• 9 Thrusters
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: remo reduzido / thruster leve
• Scale: carga adaptada
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 22.1
            DefaultWorkoutSeed(
                name: "OPEN 22.1",
                title: "Open 22.1 – Engine com Wall Walk e Snatch",
                description: "Treino cíclico combinando ginástica e levantamento leve. Exige coordenação, resistência de ombro e consistência aeróbica.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade de ombros e punhos
Pike push-ups
Wall walk progressivo
Dumbbell snatch leve
""", order: 1),
                    .init(title: "Detalhes", text: "Wall walks acumulam fadiga nos ombros. Ritmo constante evita quebra no meio do treino.", order: 2),
                    .init(title: "Técnica", text: """
• Core ativo durante o wall walk
• Alternância eficiente no snatch
• Respiração cadenciada nas transições
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 15 min:
• 3 Wall Walks
• 12 Dumbbell Snatches (22,5kg)
• 6 Wall Walks
• 15 Dumbbell Snatches
• 9 Wall Walks
• 18 Dumbbell Snatches

Continuar progressão aumentando 3 wall walks e 3 snatches por rodada.
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: bear crawl parcial / halter leve
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 22.2
            DefaultWorkoutSeed(
                name: "OPEN 22.2",
                title: "Open 22.2 – Deadlift & Bar-Facing Burpee Ladder",
                description: "Treino simples e intenso focado em resistência muscular da cadeia posterior e capacidade metabólica.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade posterior
Deadlift progressivo leve
Burpees controlados
""", order: 1),
                    .init(title: "Detalhes", text: "Volume crescente exige estratégia de séries desde o início.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift com coluna neutra
• Burpee com salto eficiente
• Respiração controlada entre reps
""", order: 3),
                    .init(title: "WOD", text: """
For time (10 min cap):
1-2-3-4-5-6-7-8-9-10 reps de:
• Deadlifts (102kg)
• Bar-Facing Burpees
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve / step burpee
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 22.3
            DefaultWorkoutSeed(
                name: "OPEN 22.3",
                title: "Open 22.3 – Ginástica & Barbell Complex",
                description: "Treino técnico com progressão de ginástica e levantamento. Testa domínio técnico sob fadiga.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Pull-ups técnicos
Double-unders progressivos
Thrusters leves
""", order: 1),
                    .init(title: "Detalhes", text: "Gestão de grip e respiração são determinantes.", order: 2),
                    .init(title: "Técnica", text: """
• Pull-ups eficientes
• Double-unders com salto baixo
• Thruster fluido
""", order: 3),
                    .init(title: "WOD", text: """
For time (12 min cap):
• 21 Pull-ups
• 42 Double-Unders
• 21 Thrusters (43kg)
• 18 Chest-to-Bar Pull-ups
• 36 Double-Unders
• 18 Thrusters
• 15 Bar Muscle-Ups
• 30 Double-Unders
• 15 Thrusters
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: ring rows / singles
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 22.4
            DefaultWorkoutSeed(
                name: "OPEN 22.4",
                title: "Open 22.4 – Chipper de Força e Ginástica",
                description: "Treino longo e completo combinando levantamento pesado e movimentos ginásticos avançados.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Deadlift progressivo
Mobilidade posterior
HSPU técnico
Lunges leves
""", order: 1),
                    .init(title: "Detalhes", text: "Pacing e gestão de fadiga lombar e de ombro são essenciais.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift com postura neutra
• HSPU com alinhamento corporal
• Lunges com estabilidade
""", order: 3),
                    .init(title: "WOD", text: """
For time (9 min cap):
• 21 Deadlifts (102kg)
• 21 Handstand Push-ups
• 15 Deadlifts
• 15 HSPU
• 9 Deadlifts
• 9 HSPU

Se completar dentro do cap:
• 21 Deadlifts (143kg)
• 50-ft Handstand Walk
• 15 Deadlifts
• 50-ft Handstand Walk
• 9 Deadlifts
• 50-ft Handstand Walk
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve / pike push-up
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 22.5
            DefaultWorkoutSeed(
                name: "OPEN 22.5",
                title: "Open 22.5 – Final Thruster & Pull-Up Ladder",
                description: "Treino final inspirado no benchmark Fran. Volume crescente e alta exigência metabólica.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Thrusters leves progressivos
Pull-ups técnicos
Mobilidade de ombro
""", order: 1),
                    .init(title: "Detalhes", text: "Estratégia de séries e controle do ritmo inicial são decisivos.", order: 2),
                    .init(title: "Técnica", text: """
• Thruster fluido com respiração coordenada
• Pull-ups com kip eficiente
• Transições rápidas
""", order: 3),
                    .init(title: "WOD", text: """
For time:
3-6-9-12-15-18-21 reps de:
• Thrusters (43kg)
• Chest-to-Bar Pull-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: thruster leve / pull-up elástico
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 23.1
            DefaultWorkoutSeed(
                name: "OPEN 23.1",
                title: "Open 23.1 – Chipper de Engine e Ginástica",
                description: "Treino longo com volume alto de remo, wall balls e ginástica. Exige pacing consistente e resistência muscular.",
                blocks: [
                    .init(title: "Aquecimento", text: """
5 min remo leve
Wall balls leves
Toes-to-bar técnicos
Pull-ups progressivos
""", order: 1),
                    .init(title: "Detalhes", text: "Controle de ritmo é essencial para avançar nas etapas finais.", order: 2),
                    .init(title: "Técnica", text: """
• Remo com cadência constante
• Wall ball com respiração sincronizada
• Economia de swing nos toes-to-bar
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 14 min:
• 60 cal Row
• 50 Toes-to-Bar
• 40 Wall Balls (9kg)
• 30 Cleans (61kg)
• 20 Bar Muscle-Ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: knee raises / carga reduzida
• Scale: chest-to-bar
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 23.2
            DefaultWorkoutSeed(
                name: "OPEN 23.2",
                title: "Open 23.2 – Deadlift, Burpee e Shuttle Run",
                description: "Treino intervalado combinando levantamento moderado e corrida curta. Teste de engine e consistência.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Mobilidade posterior
Deadlift progressivo leve
Shuttle runs leves
""", order: 1),
                    .init(title: "Detalhes", text: "Mudanças de direção e transições rápidas impactam diretamente o score.", order: 2),
                    .init(title: "Técnica", text: """
• Deadlift eficiente
• Burpee com salto econômico
• Corrida com passadas curtas e rápidas
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 15 min:
• 5 Deadlifts (102kg)
• 10 Shuttle Runs
• 5 Deadlifts
• 10 Burpees
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve / corrida reduzida
• Scale: carga adaptada
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 23.3
            DefaultWorkoutSeed(
                name: "OPEN 23.3",
                title: "Open 23.3 – Gymnastics Ladder & Thrusters",
                description: "Treino técnico com progressão de ginástica avançada e levantamento moderado.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Pull-ups e chest-to-bar progressivos
Thrusters leves
Mobilidade de ombro
""", order: 1),
                    .init(title: "Detalhes", text: "Gestão de grip e estratégia de séries são decisivas.", order: 2),
                    .init(title: "Técnica", text: """
• Pull-ups com kip eficiente
• Thruster fluido
• Respiração coordenada
""", order: 3),
                    .init(title: "WOD", text: """
For time (12 min cap):
• 21 Pull-ups
• 21 Thrusters (43kg)
• 18 Chest-to-Bar
• 18 Thrusters
• 15 Bar Muscle-Ups
• 15 Thrusters
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: ring rows / thruster leve
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 23.4
            DefaultWorkoutSeed(
                name: "OPEN 23.4",
                title: "Open 23.4 – Clean & Gymnastics Capacity",
                description: "Treino combinando levantamento técnico e ginástica avançada, exigindo resistência e consistência.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Clean técnico leve
Toes-to-bar progressivos
Mobilidade de quadril
""", order: 1),
                    .init(title: "Detalhes", text: "Transições rápidas e controle de fadiga determinam desempenho.", order: 2),
                    .init(title: "Técnica", text: """
• Clean com uso do quadril
• Toes-to-bar econômicos
• Respiração constante
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 10 min:
• 10 Squat Cleans (61kg)
• 20 Toes-to-Bar
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: halter leve / knee raises
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 23.5
            DefaultWorkoutSeed(
                name: "OPEN 23.5",
                title: "Open 23.5 – Final Thruster & Pull-Up Sprint",
                description: "Treino final de alta intensidade inspirado no benchmark Fran.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Thrusters leves progressivos
Pull-ups técnicos
Mobilidade de ombro
""", order: 1),
                    .init(title: "Detalhes", text: "Controle de séries e respiração são decisivos.", order: 2),
                    .init(title: "Técnica", text: """
• Thruster fluido
• Pull-ups unbroken quando possível
• Transições rápidas
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 21 Thrusters (43kg)
• 21 Pull-ups
• 15 Thrusters
• 15 Pull-ups
• 9 Thrusters
• 9 Pull-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: thruster leve / ring rows
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 24.1
            DefaultWorkoutSeed(
                name: "OPEN 24.1",
                title: "Open 24.1 – Engine & Dumbbell Complex",
                description: "Treino contínuo combinando levantamento unilateral e ginástica simples. Teste de resistência global.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Dumbbell snatch leve
Lunges sem carga
Mobilidade de ombro
""", order: 1),
                    .init(title: "Detalhes", text: "Alternância de braços preserva energia e grip.", order: 2),
                    .init(title: "Técnica", text: """
• Extensão completa no snatch
• Lunges com estabilidade
• Respiração constante
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 15 min:
• 12 Dumbbell Snatches (22,5kg)
• 12 Walking Lunges
• 12 Burpees
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: halter leve
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 24.2
            DefaultWorkoutSeed(
                name: "OPEN 24.2",
                title: "Open 24.2 – Row & Gymnastics Capacity",
                description: "Treino focado em engine com remo e ginástica em volume.",
                blocks: [
                    .init(title: "Aquecimento", text: """
5 min remo leve
Pull-ups técnicos
Wall balls leves
""", order: 1),
                    .init(title: "Detalhes", text: "Gestão de ritmo no remo é essencial.", order: 2),
                    .init(title: "Técnica", text: """
• Remo com cadência constante
• Pull-ups eficientes
• Wall ball sincronizado com respiração
""", order: 3),
                    .init(title: "WOD", text: """
AMRAP 20 min:
• 500m Row
• 30 Wall Balls (9kg)
• 20 Pull-ups
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: remo reduzido / ring rows
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            ),

            // MARK: - OPEN 24.3
            DefaultWorkoutSeed(
                name: "OPEN 24.3",
                title: "Open 24.3 – Barbell Complex & Burpees",
                description: "Treino de levantamento técnico sob fadiga metabólica.",
                blocks: [
                    .init(title: "Aquecimento", text: """
Clean leve progressivo
Burpees controlados
Mobilidade posterior
""", order: 1),
                    .init(title: "Detalhes", text: "Estratégia de séries e controle de técnica são essenciais.", order: 2),
                    .init(title: "Técnica", text: """
• Clean com extensão completa
• Burpee com salto eficiente
• Respiração coordenada
""", order: 3),
                    .init(title: "WOD", text: """
For time:
• 21 Clean & Jerks (61kg)
• 21 Burpees
• 15 Clean & Jerks
• 15 Burpees
• 9 Clean & Jerks
• 9 Burpees
""", order: 4),
                    .init(title: "Cargas / Movimentos", text: """
• Iniciante: carga leve
• Scale: carga reduzida
• RX: prescrito
""", order: 5)
                ]
            )

        ]
    }
}

