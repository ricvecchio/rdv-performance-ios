import SwiftUI

struct LoginView: View {

    @Binding var path: [AppRoute]
    @EnvironmentObject private var session: AppSession

    @StateObject private var vm = LoginViewModel()

    @State private var showPassword: Bool = false

    private let textSecondary = Color.white.opacity(0.60)
    private let lineColor = Color.white.opacity(0.35)

    var body: some View {
        ZStack {

            Image("rdv_fundo")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {

                Image("rdv_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300)
                    .opacity(0.9)
                    .shadow(color: .black.opacity(0.5), radius: 10, y: 6)
                    .padding(.top, 20)

                Text("Entre com sua conta")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.top, 10)
                    .padding(.bottom, 18)

                VStack(spacing: 22) {

                    UnderlineTextField(
                        title: "E-mail",
                        text: $vm.email,
                        isSecure: false,
                        showPassword: .constant(false),
                        lineColor: lineColor,
                        textColor: .white,
                        placeholderColor: textSecondary
                    )

                    UnderlineTextField(
                        title: "Senha",
                        text: $vm.password,
                        isSecure: true,
                        showPassword: $showPassword,
                        lineColor: lineColor,
                        textColor: .white,
                        placeholderColor: textSecondary
                    )
                }
                .frame(width: 260)

                if let errorMessage = vm.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.95))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(width: 260)
                        .background(Color.red.opacity(0.25))
                        .cornerRadius(12)
                        .padding(.top, 14)
                }

                Button { } label: {
                    Text("Esqueceu a senha?")
                        .font(.system(size: 14))
                        .foregroundColor(textSecondary)
                        .padding(.top, 14)
                }
                .buttonStyle(.plain)

                Button {
                    Task { await doLogin() }
                } label: {
                    HStack(spacing: 10) {
                        if vm.isLoading {
                            ProgressView().tint(.white.opacity(0.9))
                        }
                        Text(vm.isLoading ? "Entrando..." : "Acessar")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .frame(width: 260, height: 44)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.28))
                            .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
                    )
                    .shadow(color: Color.green.opacity(0.10), radius: 10, x: 0, y: 6)
                }
                .buttonStyle(.plain)
                .padding(.top, 22)
                .disabled(vm.isLoading)

                Button {
                    path.append(.accountTypeSelection)
                } label: {
                    Text("Inscreva-se gratuitamente")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .underline()
                        .padding(.top, 18)
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { vm.errorMessage = nil }
    }

    private func doLogin() async {
        let ok = await vm.submitLogin()
        guard ok else { return }

        // ✅ aguarda o AppSession buscar o userType no Firestore
        for _ in 0..<20 {
            if session.userType != nil { break }
            try? await Task.sleep(nanoseconds: 120_000_000) // 0.12s
        }

        guard let type = session.userType else {
            vm.errorMessage = "Seu perfil não foi encontrado no Firestore (users/{uid})."
            return
        }

        path.removeAll()

        if type == .STUDENT {
            guard let uid = session.uid else {
                vm.errorMessage = "Não foi possível identificar o usuário logado."
                return
            }
            let name = session.userName ?? "Aluno"
            path.append(.studentAgenda(studentId: uid, studentName: name))
        } else {
            path.append(.home)
        }
    }
}

