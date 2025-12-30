import SwiftUI

// MARK: - Tela: Cadastro Aluno (STUDENT)
struct RegisterStudentView: View {

    @Binding var path: [AppRoute]
    @StateObject private var vm = RegisterViewModel()

    @State private var showPassword: Bool = false

    // Mantém coerência com o app
    private let textSecondary = Color.white.opacity(0.60)
    private let lineColor = Color.white.opacity(0.35)

    // Largura máxima do conteúdo central (igual Settings/Profile)
    private let contentMaxWidth: CGFloat = 380

    var body: some View {
        ZStack {

            // FUNDO
            Image("rdv_fundo")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // Separador entre NavigationBar e corpo
                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)

                // Scroll com conteúdo centralizado
                ScrollView(showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 0)

                        VStack(spacing: 18) {

                            formCardStudent()
                                .padding(.top, 24)

                            actionArea()

                            Color.clear
                                .frame(height: Theme.Layout.footerHeight + 24)
                        }
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        Spacer(minLength: 0)
                    }
                }
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {

            ToolbarItem(placement: .navigationBarLeading) {
                Button { pop() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("Cadastro Aluno")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onChange(of: vm.successMessage) { _, newValue in
            // MVP: ao cadastrar com sucesso, volta pro login
            if newValue != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    path.removeAll()
                }
            }
        }
    }

    // MARK: - Card do formulário (Aluno)
    private func formCardStudent() -> some View {
        VStack(spacing: 18) {

            UnderlineTextField(
                title: "Nome",
                text: $vm.name,
                isSecure: false,
                showPassword: .constant(false),
                lineColor: lineColor,
                textColor: .white,
                placeholderColor: textSecondary
            )

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

            UnderlineTextField(
                title: "WhatsApp (opcional)",
                text: $vm.phone,
                isSecure: false,
                showPassword: .constant(false),
                lineColor: lineColor,
                textColor: .white,
                placeholderColor: textSecondary
            )

            pickerRow(
                title: "Área de foco",
                selection: $vm.focusArea,
                options: FocusAreaDTO.allCases
            )

            pickerRow(
                title: "Plano",
                selection: $vm.planType,
                options: PlanTypeDTO.allCases
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    // MARK: - Ações / Mensagens / Botões
    private func actionArea() -> some View {
        VStack(spacing: 12) {

            if let err = vm.errorMessage {
                Text(err)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.95))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.25))
                    .cornerRadius(12)
            }

            if let ok = vm.successMessage {
                Text(ok)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.95))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.20))
                    .cornerRadius(12)
            }

            Button {
                Task { await vm.submit(userType: .STUDENT) }
            } label: {
                HStack(spacing: 10) {
                    if vm.isLoading {
                        ProgressView()
                            .tint(.white.opacity(0.9))
                    }

                    Text(vm.isLoading ? "Criando..." : "Criar Conta")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(
                    Capsule()
                        .fill(Color.green.opacity(0.28))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                )
                .shadow(color: Color.green.opacity(0.10), radius: 10, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .disabled(vm.isLoading)

            Button {
                path.removeAll()
            } label: {
                Text("Já tenho conta — Voltar ao Login")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .underline()
                    .padding(.top, 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 12)
    }

    // MARK: - Picker (padrão underline)
    private func pickerRow<T: RawRepresentable & CaseIterable>(
        title: String,
        selection: Binding<T>,
        options: [T]
    ) -> some View where T.RawValue == String {
        VStack(alignment: .leading, spacing: 8) {

            Text(title)
                .font(.system(size: 14))
                .foregroundColor(textSecondary)

            Menu {
                ForEach(options, id: \.rawValue) { opt in
                    Button(opt.rawValue) { selection.wrappedValue = opt }
                }
            } label: {
                HStack {
                    Text(selection.wrappedValue.rawValue)
                        .foregroundColor(.white.opacity(0.92))
                        .font(.system(size: 16))

                    Spacer()

                    Image(systemName: "chevron.down")
                        .foregroundColor(.white.opacity(0.55))
                }
                .contentShape(Rectangle())
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(lineColor)
                .frame(height: 1)
        }
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

