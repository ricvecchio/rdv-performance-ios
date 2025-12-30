import Foundation

enum MockStudents {

    static let all: [Student] = [
        Student(
            name: "Ricardo Del Vecchio",
            program: .crossfit,
            periodText: "12/01 - 16/01 • Treino 3",
            progress: 0.67
        ),
        Student(
            name: "Mariana Souza",
            program: .academia,
            periodText: "12/01 - 16/01 • Treino A",
            progress: 0.42
        ),
        Student(
            name: "João Pedro",
            program: .emCasa,
            periodText: "12/01 - 16/01 • Semana 2",
            progress: 0.80
        ),
        Student(
            name: "Bianca Lima",
            program: .crossfit,
            periodText: "12/01 - 16/01 • WOD 5",
            progress: 0.25
        ),
        Student(
            name: "Felipe Costa",
            program: .academia,
            periodText: "12/01 - 16/01 • Hipertrofia",
            progress: 0.55
        )
    ]
}
