import Foundation

enum DefaultWorkoutsCrossfit {

    static func defaults(sectionKey: String) -> [DefaultWorkoutSeed] {

        if sectionKey == "girlsWods" {
            return girlsWodsDefaults()
        }

        if sectionKey == "heroTributeWorkouts" {
            return heroTributeWorkoutsDefaults()
        }

        if sectionKey == "openWods" {
            return openWodsDefaults()
        }

        if sectionKey == "wodsNomeados" {
            return wodsNomeadosDefaults()
        }

        if sectionKey == "qualifiersCompeticoes" {
            return qualifiersCompeticoesDefaults()
        }

        return []
    }
}

