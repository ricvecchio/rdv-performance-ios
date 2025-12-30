import SwiftUI

@main
struct rdvperfomanceApp: App {

    @StateObject private var session = AppSession()

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environmentObject(session)
        }
    }
}

