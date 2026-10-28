// Tela de cadastro para usuários do tipo aluno
import SwiftUI

struct RegisterStudentView: View {

    @Binding var path: [AppRoute]
    @StateObject private var vm = RegisterViewModel()
    @Environment(\.appTheme) private var appTheme

    @State private var showPassword: Bool = false

    private let textSecondary = Color.white.opacity(0.60)
    private let lineColor = Color.white.opacity(0.35)

    private let contentMaxWidth: CGFloat = 380

    // Tema Claro: mesmo fundo do card "Escolha o tema do app" (#DDEDDC)
    private let registrationCardLightSurface = Color(red: 0xDD / 255, green: 0xED / 255, blue: 0xDC / 255)

    private let studentFocusOptions: [FocusAreaDTO] = [.CROSSFIT, .GYM, .HOME]

    // Interface principal com formulário de cadastro de aluno
    var body: some View {
        ZStack {


            VStack(spacing: 0) {

                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)

                ScrollView(showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 0)

                        VStack(spacing: 18) {

                            formCardStudent()
                                .padding(.top, 24)

                            // Escolha do tema (preferência local, aplicada imediatamente)
                            RegisterThemeSelectionSection()

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
        // O fundo fica em `background` (não participa do layout): dentro do ZStack ele ignora a safe area
        // (inclusive a do teclado) e mantinha o ZStack com a altura total da tela, deslocando o formulário
        // para cima do cabeçalho quando o teclado abria.
        .background(AppThemeBackgroundImage())
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {

            ToolbarItem(placement: .topBarLeading) {
                Button { pop() } label: {
                    ZStack {
                        Color.clear
                            .frame(width: 44, height: 44)

                        Image(systemName: "chevron.left")
                            .foregroundStyle(Theme.Colors.systemAccentForeground())
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("auth.register_student.title")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundStyle(Theme.Colors.ink())
            }
        }
        // Cor explícita dependente de `appTheme` (mesmos valores de `headerBackground`): a barra acompanha a troca de tema imediatamente
        .toolbarBackground(Theme.Colors.headerBackgroundColor(for: appTheme), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .appThemeLightHeaderColorScheme()
        .onChange(of: vm.successMessage) { _, newValue in
            if newValue != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    path.removeAll()
                }
            }
        }
    }

    // Retorna card com formulário de campos para cadastro de aluno
    private func formCardStudent() -> some View {
        VStack(spacing: 18) {

            UnderlineTextField(
                title: "common.name",
                text: $vm.name,
                isSecure: false,
                showPassword: .constant(false),
                lineColor: lineColor,
                textColor: .white,
                placeholderColor: textSecondary
            )

            UnderlineTextField(
                title: "common.email",
                text: $vm.email,
                isSecure: false,
                showPassword: .constant(false),
                lineColor: lineColor,
                textColor: .white,
                placeholderColor: textSecondary,
                isEmail: true
            )

            UnderlineTextField(
                title: "common.password",
                text: $vm.password,
                isSecure: true,
                showPassword: $showPassword,
                lineColor: lineColor,
                textColor: .white,
                placeholderColor: textSecondary
            )

            // ✅ Campo de telefone com máscara brasileira centralizada
            PhoneTextField(
                title: "auth.fields.whatsapp_optional",
                digits: $vm.phone,
                lineColor: lineColor,
                textColor: .white,
                placeholderColor: textSecondary
            )

            pickerRow(
                title: "auth.fields.focus_area",
                selection: $vm.focusArea,
                options: studentFocusOptions,
                displayText: displayTextForFocusArea
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: registrationCardLightSurface))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: AuthLightPalette.indicator),
                    lineWidth: 1
                )
        )
    }

    // Retorna área com mensagens de erro/sucesso e botões de ação
    private func actionArea() -> some View {
        VStack(spacing: 12) {

            if let err = vm.errorMessage {
                Text(err)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.Colors.ink(0.95))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.25))
                    .cornerRadius(12)
            }

            if let ok = vm.successMessage {
                Text(ok)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.Colors.ink(0.95))
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
                            .tint(Theme.Colors.ink(0.9))
                    }

                    Text(
                        vm.isLoading
                            ? LocalizedStringKey("auth.registration.loading")
                            : LocalizedStringKey("auth.registration.submit")
                    )
                }
                .frame(maxWidth: .infinity)
                .authPrimaryActionButton(usesLogoutButtonBackground: true)
            }
            .buttonStyle(.plain)
            .disabled(vm.isLoading)

            Button {
                path.removeAll()
            } label: {
                Text("auth.registration.back_to_login")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.Colors.ink())
                    .underline()
                    .padding(.top, 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 12)
    }

    // Converte FocusAreaDTO em texto amigável para exibição
    private func displayTextForFocusArea(_ opt: FocusAreaDTO) -> String {
        let locale = Locale(
            identifier: UserDefaults.standard.string(forKey: "selectedAppLanguage")
                ?? AppLanguage.portugueseBrazil.rawValue
        )
        switch opt {
        case .CROSSFIT: return AppLocalization.string("auth.focus_area.crossfit", locale: locale)
        case .GYM: return AppLocalization.string("auth.focus_area.gym", locale: locale)
        case .HOME: return AppLocalization.string("auth.focus_area.home", locale: locale)
        }
    }

    // Retorna picker com menu dropdown estilizado
    private func pickerRow<T: RawRepresentable & CaseIterable>(
        title: LocalizedStringKey,
        selection: Binding<T>,
        options: [T],
        displayText: ((T) -> String)? = nil
    ) -> some View where T.RawValue == String {
        VStack(alignment: .leading, spacing: 8) {

            Text(title)
                .font(.system(size: 14))
                .foregroundStyle(AppThemeAdaptiveColor(textSecondary))

            Menu {
                ForEach(options, id: \.rawValue) { opt in
                    Button(displayText?(opt) ?? opt.rawValue) {
                        selection.wrappedValue = opt
                    }
                }
            } label: {
                HStack {
                    Text(displayText?(selection.wrappedValue) ?? selection.wrappedValue.rawValue)
                        .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: AuthLightPalette.primaryText))
                        .font(.system(size: 16))

                    Spacer()

                    Image(systemName: "chevron.down")
                        .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.55), light: AuthLightPalette.indicator))
                }
                .contentShape(Rectangle())
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(AppThemeAdaptiveColor(lineColor))
                .frame(height: 1)
        }
    }

    // Remove a última rota da pilha de navegação
    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
