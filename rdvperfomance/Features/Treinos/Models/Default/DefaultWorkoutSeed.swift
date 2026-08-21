import Foundation

struct DefaultWorkoutSeed {
    struct Block {
        let title: String
        let text: String
        let order: Int
    }

    let name: String
    let title: String
    let description: String
    let blocks: [Block]
}
