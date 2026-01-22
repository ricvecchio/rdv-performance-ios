import SwiftUI

// Tela do Aluno: Recorde Pessoal > Open (lista fixa + PR em texto)
struct StudentOpenPersonalRecordsView: View {

    @Binding var path: [AppRoute]

    private let contentMaxWidth: CGFloat = 380

    private struct OpenItem: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let storageKey: String
    }

    private struct OpenWod: Hashable {
        let titleLine: String
        let description: String
    }

    // ✅ Dados fixos conforme solicitado (ordem exata)
    private let items: [OpenItem] = [
        .init(name: "Open 11.1", storageKey: "open_11_1"),
        .init(name: "Open 11.2", storageKey: "open_11_2"),
        .init(name: "Open 11.3", storageKey: "open_11_3"),
        .init(name: "Open 12.1", storageKey: "open_12_1"),
        .init(name: "Open 12.2", storageKey: "open_12_2"),
        .init(name: "Open 12.3", storageKey: "open_12_3"),
        .init(name: "Open 12.4", storageKey: "open_12_4"),
        .init(name: "Open 12.5", storageKey: "open_12_5"),
        .init(name: "Open 13.1", storageKey: "open_13_1"),
        .init(name: "Open 13.2", storageKey: "open_13_2"),
        .init(name: "Open 13.3", storageKey: "open_13_3"),
        .init(name: "Open 13.4", storageKey: "open_13_4"),
        .init(name: "Open 13.5", storageKey: "open_13_5"),
        .init(name: "Open 14.1", storageKey: "open_14_1"),
        .init(name: "Open 14.2", storageKey: "open_14_2"),
        .init(name: "Open 14.3", storageKey: "open_14_3"),
        .init(name: "Open 14.4", storageKey: "open_14_4"),
        .init(name: "Open 14.5", storageKey: "open_14_5"),
        .init(name: "Open 15.1", storageKey: "open_15_1"),
        .init(name: "Open 15.1a", storageKey: "open_15_1a"),
        .init(name: "Open 15.2", storageKey: "open_15_2"),
        .init(name: "Open 15.3", storageKey: "open_15_3"),
        .init(name: "Open 15.4", storageKey: "open_15_4"),
        .init(name: "Open 15.5", storageKey: "open_15_5"),
        .init(name: "Open 16.1", storageKey: "open_16_1"),
        .init(name: "Open 16.2", storageKey: "open_16_2"),
        .init(name: "Open 16.3", storageKey: "open_16_3"),
        .init(name: "Open 16.4", storageKey: "open_16_4"),
        .init(name: "Open 16.5", storageKey: "open_16_5"),

        .init(name: "Open 17.1 RX", storageKey: "open_17_1_rx"),
        .init(name: "Open 17.1 SCALE", storageKey: "open_17_1_scale"),
        .init(name: "Open 17.2 RX", storageKey: "open_17_2_rx"),
        .init(name: "Open 17.2 SCALE", storageKey: "open_17_2_scale"),
        .init(name: "Open 17.3 RX", storageKey: "open_17_3_rx"),
        .init(name: "Open 17.3 SCALE", storageKey: "open_17_3_scale"),
        .init(name: "Open 17.4 RX", storageKey: "open_17_4_rx"),
        .init(name: "Open 17.4 SCALE", storageKey: "open_17_4_scale"),
        .init(name: "Open 17.5 RX", storageKey: "open_17_5_rx"),
        .init(name: "Open 17.5 SCALE", storageKey: "open_17_5_scale"),

        .init(name: "Open 18.1 RX", storageKey: "open_18_1_rx"),
        .init(name: "Open 18.1 SCALE", storageKey: "open_18_1_scale"),
        .init(name: "Open 18.2", storageKey: "open_18_2"),
        .init(name: "Open 18.2a", storageKey: "open_18_2a"),
        .init(name: "Open 18.3 RX", storageKey: "open_18_3_rx"),
        .init(name: "Open 18.3 SCALE", storageKey: "open_18_3_scale"),
        .init(name: "Open 18.4 RX", storageKey: "open_18_4_rx"),
        .init(name: "Open 18.4 SCALE", storageKey: "open_18_4_scale"),
        .init(name: "Open 18.5 RX", storageKey: "open_18_5_rx"),
        .init(name: "Open 18.5 SCALE", storageKey: "open_18_5_scale"),

        .init(name: "Open 19.1 RX", storageKey: "open_19_1_rx"),
        .init(name: "Open 19.1 SCALE", storageKey: "open_19_1_scale"),
        .init(name: "Open 19.2 RX", storageKey: "open_19_2_rx"),
        .init(name: "Open 19.2 SCALE", storageKey: "open_19_2_scale"),
        .init(name: "Open 19.3 RX", storageKey: "open_19_3_rx"),
        .init(name: "Open 19.3 SCALE", storageKey: "open_19_3_scale"),
        .init(name: "Open 19.4 RX", storageKey: "open_19_4_rx"),
        .init(name: "Open 19.4 SCALE", storageKey: "open_19_4_scale"),
        .init(name: "Open 19.5 RX", storageKey: "open_19_5_rx"),
        .init(name: "Open 19.5 SCALE", storageKey: "open_19_5_scale"),

        .init(name: "Open 20.1 RX", storageKey: "open_20_1_rx"),
        .init(name: "Open 20.1 SCALE", storageKey: "open_20_1_scale"),
        .init(name: "Open 20.2 RX", storageKey: "open_20_2_rx"),
        .init(name: "Open 20.2 SCALE", storageKey: "open_20_2_scale"),
        .init(name: "Open 20.3 RX", storageKey: "open_20_3_rx"),
        .init(name: "Open 20.3 SCALE", storageKey: "open_20_3_scale"),
        .init(name: "Open 20.4 RX", storageKey: "open_20_4_rx"),
        .init(name: "Open 20.4 SCALE", storageKey: "open_20_4_scale"),
        .init(name: "Open 20.5 RX", storageKey: "open_20_5_rx"),
        .init(name: "Open 20.5 SCALE", storageKey: "open_20_5_scale"),

        .init(name: "Open 21.1", storageKey: "open_21_1"),
        .init(name: "Open 21.2", storageKey: "open_21_2"),
        .init(name: "Open 21.3", storageKey: "open_21_3"),
        .init(name: "Open 21.4", storageKey: "open_21_4"),

        .init(name: "Open 22.1 RX", storageKey: "open_22_1_rx"),
        .init(name: "Open 22.1 SCALE", storageKey: "open_22_1_scale"),
        .init(name: "Open 22.2 RX", storageKey: "open_22_2_rx"),
        .init(name: "Open 22.2 SCALE", storageKey: "open_22_2_scale"),
        .init(name: "Open 22.3 RX", storageKey: "open_22_3_rx"),
        .init(name: "Open 22.3 SCALE", storageKey: "open_22_3_scale"),

        .init(name: "Open 23.1 RX", storageKey: "open_23_1_rx"),
        .init(name: "Open 23.1 SCALE", storageKey: "open_23_1_scale"),
        .init(name: "Open 23.2A RX", storageKey: "open_23_2a_rx"),
        .init(name: "Open 23.2A SCALE", storageKey: "open_23_2a_scale"),
        .init(name: "Open 23.2B", storageKey: "open_23_2b"),
        .init(name: "Open 23.3 RX", storageKey: "open_23_3_rx"),
        .init(name: "Open 23.3 SCALE", storageKey: "open_23_3_scale"),

        .init(name: "Open 24.1 RX", storageKey: "open_24_1_rx"),
        .init(name: "Open 24.1 SCALE", storageKey: "open_24_1_scale"),
        .init(name: "Open 24.2 RX", storageKey: "open_24_2_rx"),
        .init(name: "Open 24.2 SCALE", storageKey: "open_24_2_scale"),
        .init(name: "Open 24.3 RX", storageKey: "open_24_3_rx"),
        .init(name: "Open 24.3 SCALE", storageKey: "open_24_3_scale"),

        .init(name: "Open 25.1 RX", storageKey: "open_25_1_rx"),
        .init(name: "Open 25.1 SCALE", storageKey: "open_25_1_scale"),
        .init(name: "Open 25.2 RX", storageKey: "open_25_2_rx"),
        .init(name: "Open 25.2 SCALE", storageKey: "open_25_2_scale"),
        .init(name: "Open 25.3 RX", storageKey: "open_25_3_rx"),
        .init(name: "Open 25.3 SCALE", storageKey: "open_25_3_scale")
    ]

    // ✅ Descrições exatamente como você enviou
    private let wodsByKey: [String: OpenWod] = [

        // 2011
        "open_11_1": .init(
            titleLine: "Open 11.1 — AMRAP 10 min",
            description:
"""
30 Double-unders

15 Power Snatches (34/25 kg)
"""
        ),
        "open_11_2": .init(
            titleLine: "Open 11.2 — AMRAP 15 min",
            description:
"""
9 Deadlifts (70/47,5 kg)

12 Push-ups

15 Box Jumps (61/51 cm)
"""
        ),
        "open_11_3": .init(
            titleLine: "Open 11.3 — AMRAP 5 min",
            description:
"""
Squat Clean (61/43 kg)
(reps contínuas)
"""
        ),

        // 2012
        "open_12_1": .init(
            titleLine: "Open 12.1 — AMRAP 7 min",
            description:
"""
Burpees
"""
        ),
        "open_12_2": .init(
            titleLine: "Open 12.2 — AMRAP 10 min",
            description:
"""
Snatch (34/25 kg)
(reps contínuas)
"""
        ),
        "open_12_3": .init(
            titleLine: "Open 12.3 — AMRAP 18 min",
            description:
"""
15 Box Jumps

12 Push Press (52/34 kg)

9 Toes-to-Bar
"""
        ),
        "open_12_4": .init(
            titleLine: "Open 12.4 — For Time",
            description:
"""
150 Wall Balls (9/6 kg)

90 Double-unders

30 Muscle-ups
"""
        ),
        "open_12_5": .init(
            titleLine: "Open 12.5 — For Time",
            description:
"""
7 Muscle-ups

50 Wall Balls

100 Double-unders

50 Wall Balls

7 Muscle-ups
"""
        ),

        // 2013
        "open_13_1": .init(
            titleLine: "Open 13.1 — AMRAP 17 min",
            description:
"""
40 Burpees

30 Snatches (34/25 kg)

30 Burpees

30 Snatches (61/43 kg)

20 Burpees

30 Snatches (75/52 kg)

10 Burpees

Max Snatches (100/70 kg)
"""
        ),
        "open_13_2": .init(
            titleLine: "Open 13.2 — AMRAP 10 min",
            description:
"""
5 Shoulder-to-Overhead (52/34 kg)

10 Deadlifts (52/34 kg)

15 Box Jumps
"""
        ),
        "open_13_3": .init(
            titleLine: "Open 13.3 — AMRAP 12 min",
            description:
"""
150 Wall Balls

90 Double-unders

30 Muscle-ups
"""
        ),
        "open_13_4": .init(
            titleLine: "Open 13.4 — AMRAP 7 min",
            description:
"""
Clean & Jerk (61/43 kg)
"""
        ),
        "open_13_5": .init(
            titleLine: "Open 13.5 — For Time",
            description:
"""
15 Thrusters (45/30 kg)

15 Chest-to-Bar Pull-ups
(aumenta 15 reps por movimento até falhar)
"""
        ),

        // 2014
        "open_14_1": .init(
            titleLine: "Open 14.1 — AMRAP 10 min",
            description:
"""
30 Double-unders

15 Power Snatches (34/25 kg)
"""
        ),
        "open_14_2": .init(
            titleLine: "Open 14.2 — AMRAP 9 min",
            description:
"""
10 Toes-to-Bar

10 Deadlifts (52/34 kg)

10 Box Jumps
(aumenta 2 reps por round)
"""
        ),
        "open_14_3": .init(
            titleLine: "Open 14.3 — AMRAP 8 min",
            description:
"""
10 Deadlifts (61/43 kg)

15 Box Jumps

15 Wall Balls
"""
        ),
        "open_14_4": .init(
            titleLine: "Open 14.4 — For Time",
            description:
"""
60 Cal Row

50 Toes-to-Bar

40 Wall Balls

30 Cleans (61/43 kg)

20 Muscle-ups
"""
        ),
        "open_14_5": .init(
            titleLine: "Open 14.5 — For Time",
            description:
"""
21-18-15-12-9-6-3

Thrusters (43/30 kg)

Bar-Facing Burpees
"""
        ),

        // 2015
        "open_15_1": .init(
            titleLine: "Open 15.1 — AMRAP 9 min",
            description:
"""
15 Toes-to-Bar

10 Deadlifts (52/34 kg)

5 Snatches (52/34 kg)
"""
        ),
        "open_15_1a": .init(
            titleLine: "Open 15.1a — For Time",
            description:
"""
1RM Clean & Jerk (6 min)
"""
        ),
        "open_15_2": .init(
            titleLine: "Open 15.2 — AMRAP 8 min",
            description:
"""
10 Power Cleans (52/34 kg)

5 Front Squats

10 Toes-to-Bar
"""
        ),
        "open_15_3": .init(
            titleLine: "Open 15.3 — For Time",
            description:
"""
14.5 repeat
"""
        ),
        "open_15_4": .init(
            titleLine: "Open 15.4 — For Time",
            description:
"""
55 Deadlifts (102/70 kg)

55 Wall Balls

55 Row Calories

55 Handstand Push-ups
"""
        ),
        "open_15_5": .init(
            titleLine: "Open 15.5 — For Time",
            description:
"""
27-21-15-9

Row (cal)

Thrusters (43/30 kg)
"""
        ),

        // 2016
        "open_16_1": .init(
            titleLine: "Open 16.1 — AMRAP 20 min",
            description:
"""
25-ft Overhead Lunges

8 Bar-Facing Burpees

25-ft Overhead Lunges

8 Chest-to-Bar Pull-ups
"""
        ),
        "open_16_2": .init(
            titleLine: "Open 16.2 — AMRAP 20 min",
            description:
"""
Toes-to-Bar

Deadlifts

Squat Cleans
(carga sobe a cada round)
"""
        ),
        "open_16_3": .init(
            titleLine: "Open 16.3 — For Time",
            description:
"""
10 Power Snatches (34/25 kg)

3 Bar Muscle-ups
(aumenta reps)
"""
        ),
        "open_16_4": .init(
            titleLine: "Open 16.4 — For Time",
            description:
"""
55 Deadlifts

55 Wall Balls

55 Cal Row

55 Handstand Push-ups
"""
        ),
        "open_16_5": .init(
            titleLine: "Open 16.5 — For Time",
            description:
"""
21-18-15-12-9-6-3

Thrusters

Bar-Facing Burpees
"""
        ),

        // 2017–2025 (resumo fiel)
        "open_17_1_rx": .init(titleLine: "17.1 — RX", description: "Dumbbell Snatches + Burpee Box Jump Overs\n(20 min AMRAP)"),
        "open_17_1_scale": .init(titleLine: "17.1 — SCALE", description: "Dumbbell Snatches + Burpee Box Jump Overs\n(20 min AMRAP)"),
        "open_17_2_rx": .init(titleLine: "17.2 — RX", description: "Toes-to-Bar / DB Cleans / Bar Muscle-ups"),
        "open_17_2_scale": .init(titleLine: "17.2 — SCALE", description: "Toes-to-Bar / DB Cleans / Bar Muscle-ups"),
        "open_17_3_rx": .init(titleLine: "17.3 — RX", description: "Front Squats / Chest-to-Bar / Bar Muscle-ups"),
        "open_17_3_scale": .init(titleLine: "17.3 — SCALE", description: "Front Squats / Chest-to-Bar / Bar Muscle-ups"),
        "open_17_4_rx": .init(titleLine: "17.4 — RX", description: "Deadlifts / HSPU / Handstand Walk"),
        "open_17_4_scale": .init(titleLine: "17.4 — SCALE", description: "Deadlifts / HSPU / Handstand Walk"),
        "open_17_5_rx": .init(titleLine: "17.5 — RX", description: "Thrusters + Chest-to-Bar Ladder"),
        "open_17_5_scale": .init(titleLine: "17.5 — SCALE", description: "Thrusters + Chest-to-Bar Ladder"),

        "open_18_1_rx": .init(titleLine: "18.1 — RX", description: "20 min AMRAP\n\nTTB / DB Cleans / Burpees"),
        "open_18_1_scale": .init(titleLine: "18.1 — SCALE", description: "20 min AMRAP\n\nTTB / DB Cleans / Burpees"),
        "open_18_2": .init(titleLine: "18.2", description: "Front Squat / Bar-Facing Burpees"),
        "open_18_2a": .init(titleLine: "18.2a", description: "1RM Clean"),
        "open_18_3_rx": .init(titleLine: "18.3 — RX", description: "DB Snatch / Box Jumps / HSPU / Ring MU"),
        "open_18_3_scale": .init(titleLine: "18.3 — SCALE", description: "DB Snatch / Box Jumps / HSPU / Ring MU"),
        "open_18_4_rx": .init(titleLine: "18.4 — RX", description: "Deadlifts / HSPU / Handstand Walk"),
        "open_18_4_scale": .init(titleLine: "18.4 — SCALE", description: "Deadlifts / HSPU / Handstand Walk"),
        "open_18_5_rx": .init(titleLine: "18.5 — RX", description: "Thrusters / Chest-to-Bar Ladder"),
        "open_18_5_scale": .init(titleLine: "18.5 — SCALE", description: "Thrusters / Chest-to-Bar Ladder"),

        "open_18_4a": .init(titleLine: "18.4a", description: "1RM Clean & Jerk"),

        "open_19_1_rx": .init(titleLine: "19.1 — RX", description: "Clássicos com:\n\nWall Balls + Row"),
        "open_19_1_scale": .init(titleLine: "19.1 — SCALE", description: "Clássicos com:\n\nWall Balls + Row"),
        "open_19_2_rx": .init(titleLine: "19.2 — RX", description: "Clássicos com:\n\nTTB + DB Cleans"),
        "open_19_2_scale": .init(titleLine: "19.2 — SCALE", description: "Clássicos com:\n\nTTB + DB Cleans"),
        "open_19_3_rx": .init(titleLine: "19.3 — RX", description: "Clássicos com:\n\nSquats + Ring MU"),
        "open_19_3_scale": .init(titleLine: "19.3 — SCALE", description: "Clássicos com:\n\nSquats + Ring MU"),
        "open_19_4_rx": .init(titleLine: "19.4 — RX", description: "Clássicos com:\n\nDeadlifts + HSPU"),
        "open_19_4_scale": .init(titleLine: "19.4 — SCALE", description: "Clássicos com:\n\nDeadlifts + HSPU"),
        "open_19_5_rx": .init(titleLine: "19.5 — RX", description: "Clássicos com:\n\nThrusters + C2B"),
        "open_19_5_scale": .init(titleLine: "19.5 — SCALE", description: "Clássicos com:\n\nThrusters + C2B"),

        "open_20_1_rx": .init(titleLine: "20.1 — RX", description: "Incluem:\n\nGround-to-Overhead + Bar-Facing Burpees"),
        "open_20_1_scale": .init(titleLine: "20.1 — SCALE", description: "Incluem:\n\nGround-to-Overhead + Bar-Facing Burpees"),
        "open_20_2_rx": .init(titleLine: "20.2 — RX", description: "Incluem:\n\nDB Step Overs"),
        "open_20_2_scale": .init(titleLine: "20.2 — SCALE", description: "Incluem:\n\nDB Step Overs"),
        "open_20_3_rx": .init(titleLine: "20.3 — RX", description: "Incluem:\n\nHeavy Deadlift + HSPU"),
        "open_20_3_scale": .init(titleLine: "20.3 — SCALE", description: "Incluem:\n\nHeavy Deadlift + HSPU"),
        "open_20_4_rx": .init(titleLine: "20.4 — RX", description: "Incluem:\n\nBox Jumps + Cleans"),
        "open_20_4_scale": .init(titleLine: "20.4 — SCALE", description: "Incluem:\n\nBox Jumps + Cleans"),
        "open_20_5_rx": .init(titleLine: "20.5 — RX", description: "Incluem:\n\nThrusters + Pull-ups"),
        "open_20_5_scale": .init(titleLine: "20.5 — SCALE", description: "Incluem:\n\nThrusters + Pull-ups"),

        "open_21_1": .init(titleLine: "21.1", description: "Formato “quartet”:\n\nWall Walks\n\nDU / TTB\n\nThrusters / Burpees\n\nComplexos com cargas progressivas"),
        "open_21_2": .init(titleLine: "21.2", description: "Formato “quartet”:\n\nWall Walks\n\nDU / TTB\n\nThrusters / Burpees\n\nComplexos com cargas progressivas"),
        "open_21_3": .init(titleLine: "21.3", description: "Formato “quartet”:\n\nWall Walks\n\nDU / TTB\n\nThrusters / Burpees\n\nComplexos com cargas progressivas"),
        "open_21_4": .init(titleLine: "21.4", description: "Formato “quartet”:\n\nWall Walks\n\nDU / TTB\n\nThrusters / Burpees\n\nComplexos com cargas progressivas"),

        "open_22_1_rx": .init(titleLine: "22.1 — RX", description: "Incluem:\n\nDB Snatch + Burpees"),
        "open_22_1_scale": .init(titleLine: "22.1 — SCALE", description: "Incluem:\n\nDB Snatch + Burpees"),
        "open_22_2_rx": .init(titleLine: "22.2 — RX", description: "Incluem:\n\nDeadlifts + TTB"),
        "open_22_2_scale": .init(titleLine: "22.2 — SCALE", description: "Incluem:\n\nDeadlifts + TTB"),
        "open_22_3_rx": .init(titleLine: "22.3 — RX", description: "Incluem:\n\nPull-ups / Thrusters / Bar MU"),
        "open_22_3_scale": .init(titleLine: "22.3 — SCALE", description: "Incluem:\n\nPull-ups / Thrusters / Bar MU"),

        "open_23_1_rx": .init(titleLine: "23.1 — RX", description: "Destaques:\n\nTTB + DB Snatch"),
        "open_23_1_scale": .init(titleLine: "23.1 — SCALE", description: "Destaques:\n\nTTB + DB Snatch"),
        "open_23_2a_rx": .init(titleLine: "23.2A — RX", description: "Destaques:\n\nShuttle Runs"),
        "open_23_2a_scale": .init(titleLine: "23.2A — SCALE", description: "Destaques:\n\nShuttle Runs"),
        "open_23_2b": .init(titleLine: "23.2B", description: "Destaques:\n\nThrusters + Pull-ups"),
        "open_23_3_rx": .init(titleLine: "23.3 — RX", description: "Destaques:\n\nHeavy Complex"),
        "open_23_3_scale": .init(titleLine: "23.3 — SCALE", description: "Destaques:\n\nHeavy Complex"),

        "open_24_1_rx": .init(titleLine: "24.1 — RX", description: "Incluem:\n\nDU + Snatch"),
        "open_24_1_scale": .init(titleLine: "24.1 — SCALE", description: "Incluem:\n\nDU + Snatch"),
        "open_24_2_rx": .init(titleLine: "24.2 — RX", description: "Incluem:\n\nRow + Deadlift"),
        "open_24_2_scale": .init(titleLine: "24.2 — SCALE", description: "Incluem:\n\nRow + Deadlift"),
        "open_24_3_rx": .init(titleLine: "24.3 — RX", description: "Incluem:\n\nThruster / Bar MU Ladder"),
        "open_24_3_scale": .init(titleLine: "24.3 — SCALE", description: "Incluem:\n\nThruster / Bar MU Ladder"),

        "open_25_1_rx": .init(titleLine: "25.1 — RX", description: "Formato moderno:\n\nGymnastics + Heavy Barbell"),
        "open_25_1_scale": .init(titleLine: "25.1 — SCALE", description: "Formato moderno:\n\nGymnastics + Heavy Barbell"),
        "open_25_2_rx": .init(titleLine: "25.2 — RX", description: "Formato moderno:\n\nIntervalos com carga crescente"),
        "open_25_2_scale": .init(titleLine: "25.2 — SCALE", description: "Formato moderno:\n\nIntervalos com carga crescente"),
        "open_25_3_rx": .init(titleLine: "25.3 — RX", description: "Formato moderno:\n\nFinal com Lift Máximo"),
        "open_25_3_scale": .init(titleLine: "25.3 — SCALE", description: "Formato moderno:\n\nFinal com Lift Máximo")
    ]

    // Persistência simples (UserDefaults via AppStorage)
    @AppStorage("student_pr_open_values_v1")
    private var openValuesData: Data = Data()

    // ✅ Ajuste do modal: usar o próprio item como gatilho da sheet (igual Heroes)
    @State private var selectedItem: OpenItem? = nil
    @State private var inputValue: String = ""

    var body: some View {
        ZStack {

            Image("rdv_fundo")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {

                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)

                ScrollView(showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 0)

                        VStack(alignment: .leading, spacing: 14) {

                            Text("Adicione seu melhor resultado por item.")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.55))

                            tableContainer()

                            Color.clear.frame(height: Theme.Layout.footerHeight + 20)
                        }
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        Spacer(minLength: 0)
                    }
                }

                FooterBar(
                    path: $path,
                    kind: .agendaSobrePerfil(
                        isAgendaSelected: false,
                        isSobreSelected: true,
                        isPerfilSelected: false
                    )
                )
                .frame(height: Theme.Layout.footerHeight)
                .background(Theme.Colors.footerBackground)
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {

            ToolbarItem(placement: .navigationBarLeading) {
                Button { pop() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("Open")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(item: $selectedItem) { item in
            editSheet(for: item)
        }
    }

    private func tableContainer() -> some View {
        VStack(spacing: 0) {

            tableHeader()

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)

            let list = items

            ForEach(Array(list.enumerated()), id: \.element.id) { index, item in

                tableRow(item: item)

                if index != list.count - 1 {
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 1)
                        .padding(.leading, 14)
                }
            }
        }
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func tableHeader() -> some View {
        HStack(spacing: 10) {

            Color.clear
                .frame(width: 26, height: 1)

            Text("Open")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.55))

            Spacer()

            Text("PR")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.55))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func tableRow(item: OpenItem) -> some View {
        let displayValue = loadValue(for: item.storageKey)

        return Button {
            selectedItem = item
        } label: {
            HStack(spacing: 10) {

                Image(systemName: "trophy.fill")
                    .foregroundColor(.green.opacity(0.85))
                    .font(.system(size: 15))
                    .frame(width: 26)

                Text(item.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer()

                if let displayValue, !displayValue.isEmpty {
                    Text(displayValue)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.88))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                } else {
                    Text("-")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.45))
                }

                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.25))
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.leading, 6)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func editSheet(for item: OpenItem) -> some View {
        let wod: OpenWod? = {
            return wodsByKey[item.storageKey]
        }()

        return ZStack {
            Theme.Colors.headerBackground
                .ignoresSafeArea()

            VStack(spacing: 14) {

                Capsule()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 44, height: 5)
                    .padding(.top, 10)

                Text(item.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 4)

                Text("Informe seu melhor resultado. Para remover, deixe vazio.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.60))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                if let wod {
                    wodCard(wod)
                        .padding(.horizontal, 16)
                        .padding(.top, 2)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Resultado:")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))

                    TextField("Ex: 7:32 ou 210 reps ou 450 pts", text: $inputValue)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(Theme.Colors.cardBackground)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)

                HStack(spacing: 12) {

                    Button {
                        selectedItem = nil
                    } label: {
                        Text("Cancelar")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.10))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        saveCurrentInput(for: item)
                        selectedItem = nil
                    } label: {
                        Text("Salvar")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.black.opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.green.opacity(0.90))
                            .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)

                Spacer()
            }
        }
        .presentationDetents([.large])
        .onAppear {
            inputValue = loadValue(for: item.storageKey) ?? ""
        }
    }

    private func wodCard(_ wod: OpenWod) -> some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundColor(.green.opacity(0.90))

                VStack(alignment: .leading, spacing: 2) {
                    Text("WOD")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.60))

                    Text(wod.titleLine)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.92))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            ScrollView {
                Text(wod.description)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.78))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
            .frame(maxHeight: 140)
        }
        .padding(14)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func saveCurrentInput(for item: OpenItem) {
        let trimmed = inputValue
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            removeValue(for: item.storageKey)
            return
        }

        saveValue(trimmed, for: item.storageKey)
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

// MARK: - Persistência (JSON em Data)
private extension StudentOpenPersonalRecordsView {

    func loadMap() -> [String: String] {
        guard !openValuesData.isEmpty else { return [:] }
        do {
            return try JSONDecoder().decode([String: String].self, from: openValuesData)
        } catch {
            return [:]
        }
    }

    func saveMap(_ map: [String: String]) {
        do {
            openValuesData = try JSONEncoder().encode(map)
        } catch {
            openValuesData = Data()
        }
    }

    func loadValue(for key: String) -> String? {
        let map = loadMap()
        return map[key]
    }

    func saveValue(_ value: String, for key: String) {
        var map = loadMap()
        map[key] = value
        saveMap(map)
    }

    func removeValue(for key: String) {
        var map = loadMap()
        map.removeValue(forKey: key)
        saveMap(map)
    }
}

