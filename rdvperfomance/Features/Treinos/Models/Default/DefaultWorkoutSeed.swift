import Foundation

struct DefaultWorkoutSeed {
    struct Block {
        let title: String
        let text: String
        let order: Int
    }

    let name: String
    let localizationKey: String
    let title: String
    let description: String
    let blocks: [Block]

    init(name: String, category: TreinoTipo, sectionKey: String, blockOrders: [Int]) {
        let key = DefaultWorkoutLocalization.defaultKey(
            name: name, sectionKey: sectionKey, category: category
        )
        self.name = name
        localizationKey = key
        title = DefaultWorkoutLocalization.seedText(for: "\(key).title")
        description = DefaultWorkoutLocalization.seedText(for: "\(key).description")
        blocks = blockOrders.map { order in
            Block(
                title: DefaultWorkoutLocalization.seedText(for: "\(key).block.\(order).name"),
                text: DefaultWorkoutLocalization.seedText(for: "\(key).block.\(order).details"),
                order: order
            )
        }
    }
}
