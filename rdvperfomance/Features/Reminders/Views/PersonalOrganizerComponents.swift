import SwiftUI
import UIKit

// Componentes visuais locais da seção Lembretes (não alteram o Theme global).

enum PersonalOrganizerLightColors {
    static let innerSurface = Color(red: 0xF0 / 255, green: 0xF7 / 255, blue: 0xEF / 255)  // #F0F7EF
    static let iconInk = Color(red: 0x25 / 255, green: 0x48 / 255, blue: 0x2B / 255)       // #25482B
    static let primaryText = Color(red: 0x17 / 255, green: 0x1C / 255, blue: 0x17 / 255)   // #171C17
    static let border = Color(red: 0xC9 / 255, green: 0xDF / 255, blue: 0xC9 / 255)        // #C9DFC9
    static let chevron = Color(red: 0x29 / 255, green: 0x4A / 255, blue: 0x2F / 255)       // #294A2F
}

/// Card no estilo das telas do aluno (Tema Escuro/Claro).
struct PersonalCardModifier: ViewModifier {
    @Environment(\.appTheme) private var appTheme

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppThemeColor(dark: Color.black.opacity(0.68), light: PersonalOrganizerLightColors.innerSurface))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        AppThemeColor(
                            dark: Theme.Colors.primaryGreen.opacity(0.28),
                            light: PersonalOrganizerLightColors.chevron
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: appTheme == .light ? .black.opacity(0.25) : .clear,
                radius: appTheme == .light ? 10 : 0,
                y: appTheme == .light ? 6 : 0
            )
    }
}

extension View {
    func personalCard() -> some View { modifier(PersonalCardModifier()) }
}

/// Texto principal de itens (mesmas cores usadas nas listas do aluno).
struct PersonalPrimaryTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.foregroundStyle(
            AppThemeColor(dark: Color.white.opacity(0.92), light: PersonalOrganizerLightColors.primaryText)
        )
    }
}

/// Botão de ação principal (verde) com os mesmos acabamentos do botão "Enviar solicitação".
struct PersonalPrimaryButtonModifier: ViewModifier {
    @Environment(\.appTheme) private var appTheme
    @Environment(\.isEnabled) private var isEnabled

    func body(content: Content) -> some View {
        if appTheme == .light {
            content
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.white.opacity(isEnabled ? 1 : 0.55))
                .padding(.vertical, 14)
                .background(AppThemePalette.lightBar.opacity(0.80))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(PersonalOrganizerLightColors.chevron, lineWidth: 1)
                )
                .shadow(color: .black.opacity(isEnabled ? 0.25 : 0.12), radius: 10, y: 6)
                .environment(\.colorScheme, .dark)
        } else {
            content.primaryGreenActionButton()
        }
    }
}

/// Campo de texto com o estilo dos campos do aluno.
struct PersonalFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 16, weight: .semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Theme.Colors.ink(0.10))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.Colors.ink(0.10), lineWidth: 1)
            )
            .foregroundStyle(Theme.Colors.ink(0.92))
    }
}

/// Estrutura comum dos formulários em sheet (título, conteúdo rolável e botões Cancelar/Salvar).
struct PersonalEditorSheet<Content: View>: View {
    let titleKey: LocalizedStringKey
    let canSave: Bool
    let isSaving: Bool
    let onCancel: () -> Void
    let onSave: () -> Void
    @ViewBuilder let content: Content

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

                        Text(titleKey)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Theme.Colors.ink())
                            .padding(.top, 4)

                        VStack(alignment: .leading, spacing: 14) {
                            content
                        }
                        .personalCard()
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                    }
                    .padding(.bottom, 16)
                }
                .scrollDismissesKeyboard(.interactively)

                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        Text("common.cancel")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Theme.Colors.ink(0.85))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.Colors.ink(0.10))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Theme.Colors.ink(0.10), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)

                    Button(action: onSave) {
                        HStack(spacing: 10) {
                            Text("common.save")
                            if isSaving { ProgressView() }
                        }
                        .frame(maxWidth: .infinity)
                        .modifier(PersonalPrimaryButtonModifier())
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSave || isSaving)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
    }
}

/// Rótulo + conteúdo de um campo de formulário.
struct PersonalLabeledField<Content: View>: View {
    let titleKey: LocalizedStringKey
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(titleKey)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.Colors.ink(0.75))
            content
        }
    }
}

/// Aviso exibido quando as notificações estão desativadas nos Ajustes do iPhone.
struct PersonalNotificationsDisabledBanner: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "bell.slash.fill")
                    .foregroundColor(.yellow.opacity(0.9))
                Text("personal.notifications_disabled_message")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.Colors.ink(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("personal.open_settings")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.Colors.systemAccentForeground())
            }
            .buttonStyle(.plain)
        }
    }
}

/// Seção (anotações/lembretes/aniversários) escolhida na tela Lembretes.
enum PersonalOrganizerSection: Hashable {
    case notes
    case reminders
    case birthdays
}
