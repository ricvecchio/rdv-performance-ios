import Foundation

enum DefaultWorkoutsProvider {

    static func defaultsFor(category: TreinoTipo, sectionKey: String) -> [DefaultWorkoutSeed] {
        switch category {
        case .crossfit:
            return DefaultWorkoutsCrossfit.defaults(sectionKey: sectionKey)

        case .academia:
            return DefaultWorkoutsAcademia.defaults(sectionKey: sectionKey)

        case .emCasa:
            return DefaultWorkoutsEmCasa.defaults(sectionKey: sectionKey)
        }
    }
}
