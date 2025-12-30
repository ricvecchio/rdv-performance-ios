import Foundation
import SwiftUI
import Combine // ✅ IMPORTANTE (resolve a maioria dos casos)

@MainActor
final class AppSession: ObservableObject {

    // Persistência simples
    @AppStorage("auth_token") private var storedToken: String = ""
    @AppStorage("auth_userType") private var storedUserTypeRaw: String = ""
    @AppStorage("auth_userName") private var storedUserName: String = ""

    // Estado em memória
    @Published var token: String? = nil
    @Published var userType: UserTypeDTO? = nil
    @Published var userName: String? = nil

    init() {
        self.token = storedToken.isEmpty ? nil : storedToken
        self.userType = UserTypeDTO(rawValue: storedUserTypeRaw)
        self.userName = storedUserName.isEmpty ? nil : storedUserName
    }

    var isLoggedIn: Bool {
        token != nil && userType != nil
    }

    func start(token: String, userType: UserTypeDTO, userName: String?) {
        self.token = token
        self.userType = userType
        self.userName = userName

        storedToken = token
        storedUserTypeRaw = userType.rawValue
        storedUserName = userName ?? ""
    }

    func logout() {
        token = nil
        userType = nil
        userName = nil

        storedToken = ""
        storedUserTypeRaw = ""
        storedUserName = ""
    }
}

