import Foundation
import Combine
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

/// Estado compartilhado de Anotações, Lembretes e Aniversários do usuário autenticado.
///
/// - Dados em tempo real via Firestore (`users/{uid}/personal_*`), com cache offline do SDK.
/// - Reconcilia as notificações locais quando os registros, o idioma ou a permissão mudam,
///   e quando o app abre/volta ao primeiro plano (chamado por `StudentRootView`).
@MainActor
final class PersonalOrganizerStore: ObservableObject {

    @Published private(set) var notes: [PersonalNote] = []
    @Published private(set) var reminders: [PersonalReminder] = []
    @Published private(set) var birthdays: [PersonalBirthday] = []
    @Published private(set) var authorization: PersonalNotificationAuthorization = .unknown
    @Published private(set) var loadError: PersonalOrganizerErrorKind?
    var loadFailed: Bool { loadError != nil }

    private(set) var ownerUid: String?
    private var authHandle: AuthStateDidChangeListenerHandle?

    private let repository: PersonalOrganizerRepository
    private let scheduler: PersonalNotificationScheduler
    private var listeners = PersonalOrganizerListenerBag()
    private var loadedKinds: Set<PersonalOrganizerCollection> = []
    private var reconcileTask: Task<Void, Never>?

    init(
        repository: PersonalOrganizerRepository? = nil,
        scheduler: PersonalNotificationScheduler? = nil
    ) {
        self.repository = repository ?? PersonalOrganizerRepository.shared
        self.scheduler = scheduler ?? PersonalNotificationScheduler.shared
    }

    // MARK: - Ciclo de vida

    /// Inicia (ou reinicia, se o UID mudou) a escuta dos dados do usuário.
    func start(ownerUid uid: String, force: Bool = false) {
        let cleanUid = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanUid.isEmpty else { return }
        guard ownerUid != cleanUid || force else { return }

        stop()
        ownerUid = cleanUid
        loadError = nil

        #if DEBUG
        print("[PersonalOrganizer] start ownerUid=\(cleanUid) authUid=\(Auth.auth().currentUser?.uid ?? "nil") force=\(force)")
        #endif

        // Só escuta o Firestore quando o Firebase Auth já possui o mesmo UID (evita negação por sessão não pronta)
        if Auth.auth().currentUser?.uid == cleanUid {
            attachListeners(uid: cleanUid)
        } else {
            authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
                Task { @MainActor [weak self] in
                    guard let self, user?.uid == cleanUid, self.ownerUid == cleanUid else { return }
                    self.removeAuthHandle()
                    self.attachListeners(uid: cleanUid)
                }
            }
        }

        Task { await refreshAuthorization() }
    }

    /// Reinicia a escuta quando houve falha de carregamento (sessão ainda não pronta ou sem conexão).
    func retryIfNeeded() {
        guard loadError != nil, let uid = ownerUid else { return }
        start(ownerUid: uid, force: true)
    }

    private func attachListeners(uid: String) {
        for kind in PersonalOrganizerCollection.allCases {
            let registration = repository.listen(uid: uid, kind: kind) { [weak self] snapshot, error in
                Task { @MainActor [weak self] in
                    self?.handle(snapshot: snapshot, error: error, kind: kind, uid: uid)
                }
            }
            listeners.add(registration)
        }
    }

    private func removeAuthHandle() {
        if let authHandle { Auth.auth().removeStateDidChangeListener(authHandle) }
        authHandle = nil
    }

    /// Interrompe a escuta e limpa os dados em memória (impede exibir dados de outra conta).
    func stop() {
        removeAuthHandle()
        listeners.removeAll()
        loadedKinds.removeAll()
        notes = []
        reminders = []
        birthdays = []
        ownerUid = nil
    }

    private func handle(snapshot: QuerySnapshot?, error: Error?, kind: PersonalOrganizerCollection, uid: String) {
        guard uid == ownerUid else { return }

        guard let snapshot else {
            if let error { loadError = PersonalOrganizerErrorKind(error) }
            return
        }
        loadError = nil

        // Um cache vazio inicial não é prova de ausência de dados: aguarda o servidor antes de reconciliar.
        let wasLoaded = loadedKinds.contains(kind)
        if !(snapshot.metadata.isFromCache && snapshot.documents.isEmpty) {
            loadedKinds.insert(kind)
        }
        var didChange = !wasLoaded && loadedKinds.contains(kind)

        switch kind {
        case .notes:
            let items = snapshot.documents
                .compactMap { PersonalNote(id: $0.documentID, data: $0.data()) }
                .filter { $0.ownerUid == uid }
                .sorted { $0.updatedAt > $1.updatedAt }
            if items != notes { notes = items }

        case .reminders:
            let items = snapshot.documents
                .compactMap { PersonalReminder(id: $0.documentID, data: $0.data()) }
                .filter { $0.ownerUid == uid }
                .sorted { $0.remindAt < $1.remindAt }
            if items != reminders { reminders = items; didChange = true }

        case .birthdays:
            let items = snapshot.documents
                .compactMap { PersonalBirthday(id: $0.documentID, data: $0.data()) }
                .filter { $0.ownerUid == uid }
            if items != birthdays { birthdays = items; didChange = true }
        }

        if kind != .notes && didChange {
            reconcileNotifications()
        }
    }

    /// Aniversários ordenados pelo próximo acontecimento (dia e mês).
    func upcomingBirthdays(now: Date = Date()) -> [PersonalBirthday] {
        birthdays.sorted {
            let lhs = $0.nextOccurrenceDay(from: now)
            let rhs = $1.nextOccurrenceDay(from: now)
            if lhs != rhs { return lhs < rhs }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    // MARK: - Notificações

    private var notificationLocale: Locale {
        Locale(
            identifier: UserDefaults.standard.string(forKey: "selectedAppLanguage")
                ?? AppLanguage.portugueseBrazil.rawValue
        )
    }

    func refreshAuthorization() async {
        authorization = await scheduler.authorizationStatus()
    }

    /// Pede autorização somente se ainda não decidida (primeira ativação). Reconcilia ao concluir.
    @discardableResult
    func requestNotificationAuthorizationIfNeeded() async -> PersonalNotificationAuthorization {
        let status = await scheduler.requestAuthorizationIfNeeded()
        authorization = status
        if status == .authorized { reconcileNotifications() }
        return status
    }

    /// Reconcilia as notificações locais com os registros atuais. Execuções são serializadas.
    func reconcileNotifications() {
        guard let uid = ownerUid,
              loadedKinds.contains(.reminders),
              loadedKinds.contains(.birthdays) else { return }

        let plans = PersonalNotificationPlanner.plans(
            ownerUid: uid,
            reminders: reminders,
            birthdays: birthdays,
            locale: notificationLocale
        )

        let previous = reconcileTask
        reconcileTask = Task { [scheduler] in
            await previous?.value
            await scheduler.reconcile(plans: plans)
        }
        Task { await refreshAuthorization() }
    }

    // MARK: - Anotações

    func saveNote(id: String?, title: String, details: String) async throws {
        guard let uid = ownerUid else { throw PersonalOrganizerError.notSignedIn }
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Date()

        var note: PersonalNote
        if let id, let existing = notes.first(where: { $0.id == id }) {
            note = existing
            note.title = cleanTitle
            note.details = cleanDetails
            guard !note.hasSameContent(as: existing) else { return }
            note.updatedAt = now
        } else {
            note = PersonalNote(
                id: UUID().uuidString,
                ownerUid: uid,
                title: cleanTitle,
                details: cleanDetails,
                createdAt: now,
                updatedAt: now
            )
        }
        try await repository.save(uid: uid, kind: .notes, id: note.id, data: note.firestoreData)
    }

    func deleteNote(_ note: PersonalNote) async throws {
        guard let uid = ownerUid else { throw PersonalOrganizerError.notSignedIn }
        try await repository.delete(uid: uid, kind: .notes, id: note.id)
    }

    // MARK: - Lembretes

    func saveReminder(
        id: String?,
        title: String,
        details: String,
        remindAt: Date,
        notificationsEnabled: Bool
    ) async throws {
        guard let uid = ownerUid else { throw PersonalOrganizerError.notSignedIn }
        let now = Date()

        var reminder: PersonalReminder
        if let id, let existing = reminders.first(where: { $0.id == id }) {
            reminder = existing
            reminder.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            reminder.details = details.trimmingCharacters(in: .whitespacesAndNewlines)
            reminder.remindAt = remindAt
            reminder.notificationsEnabled = notificationsEnabled
            guard !reminder.hasSameContent(as: existing) else { return }
            reminder.updatedAt = now
        } else {
            reminder = PersonalReminder(
                id: UUID().uuidString,
                ownerUid: uid,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                details: details.trimmingCharacters(in: .whitespacesAndNewlines),
                remindAt: remindAt,
                notificationsEnabled: notificationsEnabled,
                repeatsDaily: repeatsDaily,
                createdAt: now,
                updatedAt: now
            )
        }
        try await repository.save(uid: uid, kind: .reminders, id: reminder.id, data: reminder.firestoreData)
    }

    func deleteReminder(_ reminder: PersonalReminder) async throws {
        guard let uid = ownerUid else { throw PersonalOrganizerError.notSignedIn }
        await scheduler.cancelReminder(ownerUid: uid, id: reminder.id)
        try await repository.delete(uid: uid, kind: .reminders, id: reminder.id)
    }

    // MARK: - Aniversários

    func saveBirthday(
        id: String?,
        name: String,
        day: Int,
        month: Int,
        birthYear: Int?,
        remindersEnabled: Bool,
        notifyOneMonthBefore: Bool,
        notifyOneWeekBefore: Bool
    ) async throws {
        guard let uid = ownerUid else { throw PersonalOrganizerError.notSignedIn }
        let now = Date()
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        var birthday: PersonalBirthday
        if let id, let existing = birthdays.first(where: { $0.id == id }) {
            birthday = existing
            birthday.name = cleanName
            birthday.day = day
            birthday.month = month
            birthday.birthYear = birthYear
            birthday.remindersEnabled = remindersEnabled
            birthday.notifyOneMonthBefore = notifyOneMonthBefore
            birthday.notifyOneWeekBefore = notifyOneWeekBefore
            guard !birthday.hasSameContent(as: existing) else { return }
            birthday.updatedAt = now
        } else {
            birthday = PersonalBirthday(
                id: UUID().uuidString,
                ownerUid: uid,
                name: cleanName,
                day: day,
                month: month,
                birthYear: birthYear,
                remindersEnabled: remindersEnabled,
                notifyOneMonthBefore: notifyOneMonthBefore,
                notifyOneWeekBefore: notifyOneWeekBefore,
                createdAt: now,
                updatedAt: now
            )
        }
        try await repository.save(uid: uid, kind: .birthdays, id: birthday.id, data: birthday.firestoreData)
        // A escuta do Firestore dispara a reconciliação: cancela agendamentos antigos deste
        // aniversário, recalcula as datas e cria os novos (sem duplicar, por identificadores estáveis).
    }

    func deleteBirthday(_ birthday: PersonalBirthday) async throws {
        guard let uid = ownerUid else { throw PersonalOrganizerError.notSignedIn }
        await scheduler.cancelBirthday(ownerUid: uid, id: birthday.id)
        try await repository.delete(uid: uid, kind: .birthdays, id: birthday.id)
    }
}

