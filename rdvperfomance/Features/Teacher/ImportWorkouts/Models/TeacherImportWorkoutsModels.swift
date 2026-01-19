import Foundation

struct TeacherImportedWorkout: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let aquecimento: String
    let tecnica: String
    let wod: String
    let cargasMovimentos: String
}

struct ImportedWorkoutPayload: Equatable {
    let title: String
    let description: String
    let aquecimento: String
    let tecnica: String
    let wod: String
    let cargasMovimentos: String
}
