import Foundation
import SwiftUI

@MainActor
final class AthletesViewModel: ObservableObject {

    @Published var query = ""
    @Published private(set) var results: [PublicAthlete] = []
    @Published private(set) var favorites: [PublicAthlete] = []
    @Published private(set) var favoriteIds: Set<String> = []
    @Published private(set) var isSearching = false
    @Published private(set) var isLoadingFavorites = false
    @Published private(set) var hasSearched = false
    @Published private(set) var errorKey: String?

    private let service = AthletesService.shared
    private var searchTask: Task<Void, Never>?

    var trimmedQuery: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }

    // MARK: - Favoritos

    func loadFavorites(uid: String?) async {
        guard let uid, !uid.isEmpty else { return }

        isLoadingFavorites = true
        defer { isLoadingFavorites = false }

        do {
            let ids = try await service.favoriteIds(uid: uid)
            let athletes = await service.athletes(ids: ids)
            let byId = Dictionary(uniqueKeysWithValues: athletes.map { ($0.id, $0) })

            favoriteIds = Set(ids)
            // Atletas removidos deixam de aparecer; o documento de favorito permanece sem efeito visual.
            favorites = ids.compactMap { byId[$0] }
            errorKey = nil
        } catch {
            errorKey = "athletes.error.generic"
        }
    }

    func toggleFavorite(_ athlete: PublicAthlete, uid: String?) async {
        guard let uid, !uid.isEmpty else { return }

        let willFavorite = !favoriteIds.contains(athlete.id)

        // Atualização otimista; revertida em caso de falha.
        apply(favorite: willFavorite, athlete: athlete)

        do {
            try await service.setFavorite(uid: uid, athleteId: athlete.id, isFavorite: willFavorite)
            errorKey = nil
        } catch {
            apply(favorite: !willFavorite, athlete: athlete)
            errorKey = "athletes.error.favorite"
        }
    }

    private func apply(favorite: Bool, athlete: PublicAthlete) {
        if favorite {
            favoriteIds.insert(athlete.id)
            if !favorites.contains(where: { $0.id == athlete.id }) {
                favorites.insert(athlete, at: 0)
            }
        } else {
            favoriteIds.remove(athlete.id)
            favorites.removeAll { $0.id == athlete.id }
        }
    }

    // MARK: - Busca

    /// Debounce de 400 ms; cada nova digitação cancela a consulta anterior.
    func queryChanged(currentUid: String?) {
        searchTask?.cancel()

        guard !trimmedQuery.isEmpty else {
            results = []
            hasSearched = false
            isSearching = false
            return
        }

        isSearching = true
        let text = trimmedQuery

        searchTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(400))
            } catch {
                return
            }

            guard let self, !Task.isCancelled else { return }
            await self.performSearch(text, currentUid: currentUid)
        }
    }

    private func performSearch(_ text: String, currentUid: String?) async {
        do {
            let found = try await service.searchAthletes(query: text, excluding: currentUid)
            guard !Task.isCancelled, text == trimmedQuery else { return }

            results = found
            hasSearched = true
            isSearching = false
            errorKey = nil
        } catch {
            guard !Task.isCancelled, text == trimmedQuery else { return }

            results = []
            hasSearched = true
            isSearching = false
            errorKey = "athletes.error.generic"
        }
    }

    func cancelSearch() {
        searchTask?.cancel()
    }
}

@MainActor
final class AthleteProfileViewModel: ObservableObject {

    enum LoadState {
        case loading
        case loaded
        case unavailable
        case failed
    }

    @Published private(set) var athlete: PublicAthlete?
    @Published private(set) var state: LoadState = .loading
    @Published private(set) var isFavorite = false
    @Published private(set) var categories: [AthleteRecordCategory] = []
    @Published private(set) var recordsAccessDenied = false
    @Published private(set) var isLoadingRecords = false
    @Published private(set) var errorKey: String?

    private let service = AthletesService.shared

    func load(athleteId: String, currentUid: String?) async {
        state = .loading

        do {
            guard let loaded = try await service.athlete(id: athleteId) else {
                state = .unavailable
                return
            }

            athlete = loaded
            if let currentUid, !currentUid.isEmpty {
                isFavorite = ((try? await service.favoriteIds(uid: currentUid)) ?? []).contains(athleteId)
            }
            state = .loaded

            if loaded.privacy == .public {
                await loadRecords(athleteId: athleteId)
            } else {
                categories = []
                recordsAccessDenied = false
            }
        } catch {
            state = .failed
        }
    }

    /// Releitura dos recordes. Se a privacidade mudou para privado, a regra do Firestore nega a leitura.
    func loadRecords(athleteId: String) async {
        isLoadingRecords = true
        defer { isLoadingRecords = false }

        do {
            categories = try await service.records(athleteId: athleteId)
            recordsAccessDenied = false
        } catch {
            categories = []
            recordsAccessDenied = true
        }
    }

    func toggleFavorite(currentUid: String?) async {
        guard let athlete, let currentUid, !currentUid.isEmpty else { return }

        let willFavorite = !isFavorite
        isFavorite = willFavorite

        do {
            try await service.setFavorite(uid: currentUid, athleteId: athlete.id, isFavorite: willFavorite)
            errorKey = nil
        } catch {
            isFavorite = !willFavorite
            errorKey = "athletes.error.favorite"
        }
    }
}

