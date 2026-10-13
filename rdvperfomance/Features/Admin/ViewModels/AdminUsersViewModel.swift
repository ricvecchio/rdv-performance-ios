import Foundation
import Combine

@MainActor
final class AdminUsersViewModel: ObservableObject {
    @Published private(set) var users: [AppUser] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    /// Configuração de referência (app_config/ios) para classificar as versões; `nil` = sem referência
    @Published private(set) var versionReference: AppVersionConfig?
    @Published private(set) var updatingUserId: String?
    @Published var actionErrorMessage: String?

    private let repository: FirestoreRepository
    private let versionService = AppVersionService()

    init(repository: FirestoreRepository = .shared) {
        self.repository = repository
    }

    func loadUsers() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            users = try await repository.getAllUsers()
        } catch {
            errorMessage = error.localizedDescription
        }

        // Uma única leitura de app_config/ios por carregamento da lista
        versionReference = await versionService.referenceConfig()
    }

    /// Ativa/desativa a conta. A autorização efetiva é validada pelas regras do Firestore;
    /// a lista só é atualizada após a confirmação da gravação.
    func setAccountActive(_ user: AppUser, active: Bool, adminUid: String?) async {
        guard
            updatingUserId == nil,
            let userId = user.id, !userId.isEmpty,
            let adminUid, !adminUid.isEmpty,
            userId != adminUid,
            !user.isAdministratorProfile
        else { return }

        updatingUserId = userId
        actionErrorMessage = nil
        defer { updatingUserId = nil }

        do {
            try await repository.setUserAccountActive(uid: userId, active: active, adminUid: adminUid)
            if let index = users.firstIndex(where: { $0.id == userId }) {
                users[index].active = active
            }
        } catch {
            actionErrorMessage = error.localizedDescription
        }
    }
}

extension AppUser {
    var isAdministratorProfile: Bool {
        userType.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == UserTypeDTO.ADMIN.rawValue
    }
}

@MainActor
final class AdminStudentDetailViewModel: ObservableObject {
    @Published private(set) var teachers: [AppUser] = []
    @Published private(set) var weeks: [TrainingWeekFS] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let repository: FirestoreRepository

    init(repository: FirestoreRepository = .shared) {
        self.repository = repository
    }

    func load(studentId: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let relations = repository.getTeacherLinksForStudent(studentId: studentId)
            async let weeks = repository.getWeeksForStudent(
                studentId: studentId,
                onlyPublished: false
            )

            let (loadedRelations, loadedWeeks) = try await (relations, weeks)
            let linkedTeacherIds = Array(Set(loadedRelations.map(\.teacherId)))
            let teachersById = try await repository.getUsers(byIds: linkedTeacherIds)

            teachers = linkedTeacherIds.compactMap { teachersById[$0] }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            self.weeks = loadedWeeks
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
final class AdminTeacherDetailViewModel: ObservableObject {
    @Published private(set) var students: [AppUser] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let repository: FirestoreRepository

    init(repository: FirestoreRepository = .shared) {
        self.repository = repository
    }

    func load(teacherId: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            students = try await repository.getAllStudentsForTeacher(teacherId: teacherId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
