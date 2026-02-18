import Foundation

final class WorkoutTemplateDefaultsSeeder {

    static let shared = WorkoutTemplateDefaultsSeeder()

    private init() {}

    func seedMissingDefaultsIfNeeded(
        teacherId: String,
        category: TreinoTipo,
        sectionKey: String,
        sectionTitle: String,
        existingTemplates: [WorkoutTemplateFS]
    ) async throws -> Bool {

        let t = teacherId.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return false }

        // ✅ Somente categorias suportadas para defaults
        if category != .crossfit && category != .academia && category != .emCasa { return false }

        // ✅ "Meus Treinos" não recebe defaults
        if sectionKey == "meusTreinos" { return false }

        // ✅ Evita duplicar em aberturas futuras (persistente por professor/seção)
        let flagKey = buildFlagKey(
            teacherId: t,
            categoryRaw: category.rawValue,
            sectionKey: sectionKey
        )
        if UserDefaults.standard.bool(forKey: flagKey) {
            return false
        }

        let seeds = defaultsFor(category: category, sectionKey: sectionKey)
        if seeds.isEmpty { return false }

        // ✅ Detecta títulos já existentes (case-insensitive)
        var existingTitles = Set(
            existingTemplates
                .map { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .filter { !$0.isEmpty }
        )

        var didInsertAny = false

        for seed in seeds {

            let templateTitle = seed.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let titleKey = templateTitle.lowercased()

            // ✅ Se já existe, não duplica
            if existingTitles.contains(titleKey) {
                continue
            }

            let blocksFS: [BlockFS] = seed.blocks
                .sorted(by: { $0.order < $1.order })
                .map { b in
                    BlockFS(
                        id: UUID().uuidString,
                        name: b.title,
                        details: b.text
                    )
                }

            let templateDescription = buildTemplateDescription(seed: seed)

            _ = try await FirestoreRepository.shared.createWorkoutTemplate(
                teacherId: t,
                categoryRaw: category.rawValue,
                sectionKey: sectionKey,
                title: templateTitle,
                description: templateDescription,
                blocks: blocksFS
            )

            didInsertAny = true
            existingTitles.insert(titleKey)
        }

        // ✅ Se após o processo TODOS os defaults existem, travamos para não tentar novamente
        let allDefaultsExist = seeds.allSatisfy { seed in
            let key = seed.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return !key.isEmpty && existingTitles.contains(key)
        }

        if allDefaultsExist {
            UserDefaults.standard.set(true, forKey: flagKey)
        }

        return didInsertAny
    }

    private func defaultsFor(category: TreinoTipo, sectionKey: String) -> [DefaultWorkoutSeed] {
        switch category {
        case .crossfit:
            return DefaultWorkoutsProvider.defaultsFor(category: category, sectionKey: sectionKey)

        case .academia:
            return DefaultWorkoutsAcademia.defaults(sectionKey: sectionKey)

        case .emCasa:
            return DefaultWorkoutsEmCasa.defaults(sectionKey: sectionKey)
        }
    }

    private func buildTemplateDescription(seed: DefaultWorkoutSeed) -> String {
        let header = seed.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let desc = seed.description.trimmingCharacters(in: .whitespacesAndNewlines)

        if header.isEmpty { return desc }
        if desc.isEmpty { return header }
        return "\(header)\n\(desc)"
    }

    private func buildFlagKey(teacherId: String, categoryRaw: String, sectionKey: String) -> String {
        let safeTeacherId = teacherId.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeCategory = categoryRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeSection = sectionKey.trimmingCharacters(in: .whitespacesAndNewlines)

        // ✅ v5 para não conflitar com flags antigas
        return "seeded_defaults_v5_\(safeTeacherId)_\(safeCategory)_\(safeSection)"
    }
}

