import Foundation

enum MockWeeks {

    static let all: [TrainingWeek] = [
        TrainingWeek(
            weekTitle: "Semana 1 - Treino A",
            category: .crossfit,
            progress: 0.67,
            days: [
                TrainingDay(title: "Segunda (01)", summary: "WOD curto: 12min AMRAP • burpees + air squats."),
                TrainingDay(title: "Terça (02)", summary: "Técnica: levantamento • mobilidade + core."),
                TrainingDay(title: "Quarta (03)", summary: "Metcon: 5 rounds • corrida + kettlebell swing."),
                TrainingDay(title: "Quinta (04)", summary: "Força: agachamento • 5x5 progressivo."),
                TrainingDay(title: "Sexta (05)", summary: "Benchmark: tempo • 21-15-9 (thruster + pull-up)."),
                TrainingDay(title: "Sábado (06)", summary: "Cardio leve + alongamento guiado.")
            ]
        ),
        TrainingWeek(
            weekTitle: "Semana 2 - Treino B",
            category: .academia,
            progress: 0.42,
            days: [
                TrainingDay(title: "Segunda (01)", summary: "Peito + tríceps • 4 exercícios • 3 séries."),
                TrainingDay(title: "Terça (02)", summary: "Costas + bíceps • foco em puxada e remada."),
                TrainingDay(title: "Quarta (03)", summary: "Pernas • agacho + extensora + posterior."),
                TrainingDay(title: "Quinta (04)", summary: "Ombro + core • elevações + prancha."),
                TrainingDay(title: "Sexta (05)", summary: "Full body leve • circuito 30min."),
                TrainingDay(title: "Sábado (06)", summary: "Alongamento + caminhada 20–30min.")
            ]
        )
    ]
}
