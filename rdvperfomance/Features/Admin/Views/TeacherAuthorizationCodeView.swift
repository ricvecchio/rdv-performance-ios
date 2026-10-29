// Modal administrativo para consultar, copiar e substituir o código de autorização de professores
import SwiftUI

struct TeacherAuthorizationCodeView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = TeacherAuthorizationCodeViewModel()

    @State private var isRotateConfirmationPresented = false

    // Tema Claro: contorno verde-escuro (#294A2F), mesmo tom do card "Acesso rápido" da TeacherDashboardView
    private let lightDarkGreenBorder = Color(red: 0x29 / 255, green: 0x4A / 255, blue: 0x2F / 255)

    // Tema Claro: superfície interna (#F0F7EF), mesma do card Adicionar Vídeo
    private let lightInnerSurface = Color(red: 0xF0 / 255, green: 0xF7 / 255, blue: 0xEF / 255)

    var body: some View {
        ZStack {
            Theme.Colors.sheetBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        Capsule()
                            .fill(Theme.Colors.ink(0.18))
                            .frame(width: 44, height: 5)
                            .padding(.top, 10)

                        Text("teacher_authorization.admin.title")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Theme.Colors.ink())
                            .padding(.top, 4)

                        VStack(alignment: .leading, spacing: 14) {
                            Text("teacher_authorization.admin.description")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.Colors.ink(0.75))
                                .fixedSize(horizontal: false, vertical: true)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("teacher_authorization.admin.current_code")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Theme.Colors.ink(0.75))

                                HStack(spacing: 10) {
                                    if vm.isLoading {
                                        ProgressView()
                                            .tint(Theme.Colors.ink(0.9))
                                        Spacer(minLength: 0)
                                    } else if let code = vm.currentCode?.code {
                                        Text(verbatim: code)
                                            .font(.system(size: 17, weight: .bold, design: .monospaced))
                                            .foregroundStyle(Theme.Colors.ink(0.92))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                            .textSelection(.enabled)

                                        Spacer(minLength: 0)

                                        Button {
                                            vm.copyCode()
                                        } label: {
                                            Label {
                                                Text("teacher_authorization.admin.copy")
                                            } icon: {
                                                Image(systemName: "doc.on.doc")
                                                    .appThemeIconForeground()
                                            }
                                                .padding(.horizontal, 12)
                                                .modifier(AuthorizationLightBarButtonModifier(compact: true))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(AppThemeColor(dark: Color.clear, light: lightDarkGreenBorder), lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(vm.isBusy)
                                    } else {
                                        Text(verbatim: "—")
                                            .font(.system(size: 17, weight: .bold, design: .monospaced))
                                            .foregroundStyle(Theme.Colors.ink(0.55))
                                        Spacer(minLength: 0)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .frame(minHeight: 52)
                                .background(Theme.Colors.ink(0.10))
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(AppThemeColor(dark: Theme.Colors.ink(0.10).dark, light: lightDarkGreenBorder), lineWidth: 1)
                                )
                            }

                            if let error = vm.errorMessage {
                                Text(error)
                                    .font(.system(size: 13))
                                    .foregroundColor(.yellow.opacity(0.95))
                            }

                            if let success = vm.successMessage {
                                Text(success)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Theme.Colors.accentForeground)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: lightInnerSurface))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppThemeColor(dark: Theme.Colors.ink(0.08).dark, light: lightDarkGreenBorder), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Text("common.close")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Theme.Colors.ink(0.85))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.Colors.ink(0.10))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(AppThemeColor(dark: Theme.Colors.ink(0.10).dark, light: lightDarkGreenBorder), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.isRotating)

                    Button {
                        isRotateConfirmationPresented = true
                    } label: {
                        HStack(spacing: 10) {
                            Text("teacher_authorization.admin.generate")

                            if vm.isRotating {
                                ProgressView()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .modifier(AuthorizationLightBarButtonModifier(compact: false))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppThemeColor(dark: Color.clear, light: lightDarkGreenBorder), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.isBusy)
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 16)
            }
        }
        .interactiveDismissDisabled(vm.isRotating)
        .alert("teacher_authorization.admin.confirm_title", isPresented: $isRotateConfirmationPresented) {
            Button("common.cancel", role: .cancel) {}
            Button("teacher_authorization.admin.confirm_action", role: .destructive) {
                Task { await vm.rotate() }
            }
        } message: {
            Text("teacher_authorization.admin.confirm_message")
        }
        .task {
            await vm.load()
        }
        .onDisappear {
            vm.clear()
        }
    }
}

// Botões "Copiar" e "Gerar novo código".
// Tema Claro (habilitado): fundo do botão "Sair" da ProfileView — verde militar #29452C a 80% — com texto e
// ícone brancos, mantendo as medidas/tipografia do estilo original. O contorno #294A2F continua sendo o overlay
// já aplicado em cada botão (sem borda duplicada).
// Tema Escuro e estado desabilitado: exatamente o estilo original (`primaryGreenActionButton()` /
// `compactPrimaryGreenActionButton()`).
private struct AuthorizationLightBarButtonModifier: ViewModifier {
    @Environment(\.appTheme) private var appTheme
    @Environment(\.isEnabled) private var isEnabled

    /// `true`: medidas do `compactPrimaryGreenActionButton()`; `false`: do `primaryGreenActionButton()`.
    let compact: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if appTheme == .light && isEnabled {
            content
                .font(.system(size: compact ? 15 : 16, weight: .semibold))
                .foregroundStyle(Color.white)
                .padding(.vertical, compact ? 9 : 14)
                .background(AppThemePalette.lightBar.opacity(0.80))
                .cornerRadius(12)
                // Ícone e indicadores sobre o verde militar usam os valores claros (brancos)
                .environment(\.colorScheme, .dark)
        } else if compact {
            content.compactPrimaryGreenActionButton()
        } else {
            content.primaryGreenActionButton()
        }
    }
}

