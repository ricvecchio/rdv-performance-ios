import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

/// Gerencia o estado de autenticação e perfil do usuário no app
@MainActor
final class AppSession: ObservableObject {

    @AppStorage("auth_uid") private var storedUid: String = ""
    @AppStorage("auth_userType") private var storedUserTypeRaw: String = ""
    @AppStorage("auth_userName") private var storedUserName: String = ""

    @AppStorage("auth_planType") private var storedPlanTypeRaw: String = ""
    @AppStorage("auth_trialStartedAt") private var storedTrialStartedAt: Double = 0

    @Published var uid: String? = nil
    @Published var userType: UserTypeDTO? = nil
    @Published var userName: String? = nil

    @Published var planTypeRaw: String? = nil
    @Published var trialStartedAt: Date? = nil

    @Published var shouldPresentPlanModal: Bool = false

    private var authListener: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()

    /// Inicializa a sessão e restaura estado persistido ou limpa em modo DEBUG
    init() {
        #if DEBUG
        self.storedUid = ""
        self.storedUserTypeRaw = ""
        self.storedUserName = ""
        self.storedPlanTypeRaw = ""
        self.storedTrialStartedAt = 0

        self.uid = nil
        self.userType = nil
        self.userName = nil
        self.planTypeRaw = nil
        self.trialStartedAt = nil
        self.shouldPresentPlanModal = false

        do {
            try Auth.auth().signOut()
        } catch {
        }
        #else
        self.uid = storedUid.isEmpty ? nil : storedUid
        self.userType = storedUserTypeRaw.isEmpty ? nil : UserTypeDTO(rawValue: storedUserTypeRaw)
        self.userName = storedUserName.isEmpty ? nil : storedUserName

        self.planTypeRaw = storedPlanTypeRaw.isEmpty ? nil : storedPlanTypeRaw
        self.trialStartedAt = storedTrialStartedAt > 0 ? Date(timeIntervalSince1970: storedTrialStartedAt) : nil
        self.shouldPresentPlanModal = false
        #endif

        observeAuthState()
    }

    /// Remove o listener de autenticação ao destruir o objeto
    deinit {
        if let authListener {
            Auth.auth().removeStateDidChangeListener(authListener)
        }
    }

    // Retorna verdadeiro se existe um usuário autenticado
    var isLoggedIn: Bool {
        uid != nil && userType != nil
    }

    // Retorna o identificador único do usuário autenticado
    var currentUid: String? { uid }

    // Retorna o tipo de usuário em formato string
    var currentUserTypeRaw: String? { userType?.rawValue }

    // Retorna verdadeiro se o usuário é um aluno
    var isStudent: Bool {
        userType?.rawValue.lowercased() == "student"
    }

    // Retorna verdadeiro se o usuário é um professor
    var isTrainer: Bool {
        userType?.rawValue.lowercased() == "trainer"
    }

    var canUseTrainerProFeatures: Bool {
        guard isLoggedIn, isTrainer else { return false }

        let plan = (planTypeRaw ?? "FREE").uppercased()
        if plan == "PRO" { return true }

        guard let start = trialStartedAt else { return false }

        let trialSeconds: TimeInterval = 30 * 24 * 60 * 60
        let endsAt = start.addingTimeInterval(trialSeconds)
        return Date() <= endsAt
    }

    func upgradeTrainerToProSimulated() async throws {
        guard isLoggedIn, isTrainer else { return }
        guard let uid, !uid.isEmpty else { return }

        let updates: [String: Any] = [
            "planType": "PRO",
            "updatedAt": FieldValue.serverTimestamp()
        ]

        try await db.collection("users").document(uid).setData(updates, merge: true)

        self.planTypeRaw = "PRO"
        self.storedPlanTypeRaw = "PRO"
    }

    func cancelTrainerProAndExpireTrial() async throws {
        guard isLoggedIn, isTrainer else { return }
        guard let uid, !uid.isEmpty else { return }

        let expiredDate = Date().addingTimeInterval(-(31 * 24 * 60 * 60))
        let updates: [String: Any] = [
            "planType": "FREE",
            "trialStartedAt": Timestamp(date: expiredDate),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        try await db.collection("users").document(uid).setData(updates, merge: true)

        self.planTypeRaw = "FREE"
        self.storedPlanTypeRaw = "FREE"

        self.trialStartedAt = expiredDate
        self.storedTrialStartedAt = expiredDate.timeIntervalSince1970
    }

    // Observa mudanças no estado de autenticação do Firebase
    private func observeAuthState() {
        if let authListener {
            Auth.auth().removeStateDidChangeListener(authListener)
        }

        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }

            Task { @MainActor in
                if let user {
                    self.uid = user.uid
                    self.storedUid = user.uid
                    await self.loadUserProfile(uid: user.uid)
                } else {
                    self.clearSession()
                }
            }
        }
    }

    // Recarrega o perfil do usuário atual do Firestore
    func refreshProfile() async {
        guard let uid else { return }
        await loadUserProfile(uid: uid)
    }

    // Carrega nome e tipo de usuário do documento Firestore
    func loadUserProfile(uid: String) async {
        do {
            let snap = try await db.collection("users").document(uid).getDocument()

            guard let data = snap.data() else {
                self.userType = nil
                self.userName = nil
                self.planTypeRaw = nil
                self.trialStartedAt = nil

                self.storedUserTypeRaw = ""
                self.storedUserName = ""
                self.storedPlanTypeRaw = ""
                self.storedTrialStartedAt = 0
                return
            }

            let name = data["name"] as? String
            let typeRaw = data["userType"] as? String

            self.userName = name
            self.userType = typeRaw.flatMap { UserTypeDTO(rawValue: $0) }

            self.storedUserName = name ?? ""
            self.storedUserTypeRaw = self.userType?.rawValue ?? ""

            let plan = (data["planType"] as? String)?.uppercased()
            self.planTypeRaw = plan ?? (storedPlanTypeRaw.isEmpty ? nil : storedPlanTypeRaw)

            if let ts = data["trialStartedAt"] as? Timestamp {
                let date = ts.dateValue()
                self.trialStartedAt = date
                self.storedTrialStartedAt = date.timeIntervalSince1970
            } else if let date = data["trialStartedAt"] as? Date {
                self.trialStartedAt = date
                self.storedTrialStartedAt = date.timeIntervalSince1970
            } else {
                let restored = storedTrialStartedAt > 0 ? Date(timeIntervalSince1970: storedTrialStartedAt) : nil
                self.trialStartedAt = restored
            }

            if self.isTrainer {
                if self.planTypeRaw == nil {
                    self.planTypeRaw = "FREE"
                    self.storedPlanTypeRaw = "FREE"
                } else {
                    self.storedPlanTypeRaw = self.planTypeRaw ?? ""
                }

                if self.trialStartedAt == nil {
                    let now = Date()
                    self.trialStartedAt = now
                    self.storedTrialStartedAt = now.timeIntervalSince1970
                }
            }

        } catch {
        }
    }

    // Desconecta o usuário do Firebase e limpa a sessão
    func logout() {
        do {
            try Auth.auth().signOut()
            clearSession()
        } catch {
            clearSession()
        }
    }

    // Limpa todos os dados da sessão local e persistida
    private func clearSession() {
        uid = nil
        userType = nil
        userName = nil
        planTypeRaw = nil
        trialStartedAt = nil
        shouldPresentPlanModal = false

        storedUid = ""
        storedUserTypeRaw = ""
        storedUserName = ""
        storedPlanTypeRaw = ""
        storedTrialStartedAt = 0
    }
}

