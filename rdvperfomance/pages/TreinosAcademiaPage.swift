import SwiftUI

// MARK: - WRAPPERS DE TREINOS (opcionais)
// Estas telas são “atalhos” que reaproveitam a TreinosPage com tipo fixo.
// Útil caso você queira registrar rotas diretas no futuro ou separar arquivos por tela.

struct TreinosAcademiaPage: View {
    @Binding var path: [AppRoute]

    var body: some View {
        TreinosPage(path: $path, tipo: .academia)
    }
}
