import Foundation
import os.log

final class WorkoutTemplateDefaultsSeeder {

    static let shared = WorkoutTemplateDefaultsSeeder()

    private init() {}

    private static let debugLog = OSLog(subsystem: "com.rdvperformance.app", category: "WorkoutTemplateDefaultsSeeder")

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

        #if DEBUG
        let debugStart = Date()
        os_log("seed START teacherId=%{public}@ category=%{public}@ section=%{public}@", log: Self.debugLog, type: .debug, t, category.rawValue, sectionKey)
        #endif

        let seeds = defaultsFor(category: category, sectionKey: sectionKey)
        if seeds.isEmpty {
            // Nada a semear nesta seção: já podemos travar a flag para não checar de novo.
            UserDefaults.standard.set(true, forKey: flagKey)
            return false
        }

        // ✅ Detecta títulos já existentes (case-insensitive)
        var existingTitles = Set(
            existingTemplates
                .map { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .filter { !$0.isEmpty }
        )

        var itemsToInsert: [(title: String, description: String, blocks: [BlockFS])] = []

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
            itemsToInsert.append((title: templateTitle, description: templateDescription, blocks: blocksFS))
            existingTitles.insert(titleKey)
        }

        let didInsertAny = !itemsToInsert.isEmpty

        if didInsertAny {
            // ✅ Uma única viagem de rede (WriteBatch) em vez de N `createWorkoutTemplate`
            // sequenciais awaited um a um — isso evitava que a tela ficasse "carregando"
            // por vários segundos ao abrir uma seção pela primeira vez em um novo device.
            try await FirestoreRepository.shared.createWorkoutTemplatesBatch(
                teacherId: t,
                categoryRaw: category.rawValue,
                sectionKey: sectionKey,
                items: itemsToInsert
            )
        }

        // ✅ IDEMPOTENTE E BARATO: uma vez que o seed foi tentado para este professor/seção,
        // travamos a flag independentemente de "todos os títulos baterem exatamente" — isso
        // evitava que pequenas divergências de grafia entre defaults e títulos existentes
        // fizessem o app tentar semear (e escrever) tudo de novo a cada abertura da tela.
        UserDefaults.standard.set(true, forKey: flagKey)

        #if DEBUG
        let elapsedMs = Date().timeIntervalSince(debugStart) * 1000
        os_log("seed END inserted=%d durationMs=%.0f", log: Self.debugLog, type: .debug, itemsToInsert.count, elapsedMs)
        #endif

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

        // ✅ v6: nova lógica de idempotência (trava a flag após a 1ª tentativa, mesmo que
        // nem todos os títulos batam exatamente) — evita reseed infinito em devices antigos.
        return "seeded_defaults_v6_\(safeTeacherId)_\(safeCategory)_\(safeSection)"
    }
}

