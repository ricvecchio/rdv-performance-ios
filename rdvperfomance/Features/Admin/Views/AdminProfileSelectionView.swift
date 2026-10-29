import SwiftUI

struct AdminProfileSelectionView: View {
    @EnvironmentObject private var session: AppSession
    @Environment(\.appTheme) private var appTheme

    @State private var isTeacherAuthorizationSheetPresented = false

    private let textSecondary = Color.white.opacity(0.60)

    // Tema Claro: contorno verde-escuro (#294A2F), mesmo tom do card "Acesso rápido" da TeacherDashboardView
    private let lightDarkGreenBorder = Color(red: 0x29 / 255, green: 0x4A / 255, blue: 0x2F / 255)

    // Tema Claro: fundo (#85C995) e ícone (#25482B) dos ícones de perfil
    private let iconSurfaceLight = Color(red: 0x85 / 255, green: 0xC9 / 255, blue: 0x95 / 255)
    private let iconInkLight = Color(red: 0x25 / 255, green: 0x48 / 255, blue: 0x2B / 255)

    var body: some View {
        ZStack {
            AppThemeBackgroundImage()

            VStack(spacing: 0) {
                Image("rdv_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 260)
                    .opacity(0.9)
                    .shadow(color: .black.opacity(0.5), radius: 10, y: 6)
                    .padding(.top, 20)

                Text("admin.profile_selection.prompt")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Theme.Colors.ink())
                    .padding(.top, 10)
                    .padding(.bottom, 22)

                VStack(spacing: 14) {
                    selectionButton(
                        title: "admin.profile_selection.administrator.title",
                        subtitle: "admin.profile_selection.administrator.subtitle",
                        icon: "gearshape.fill"
                    ) {
                        session.selectAdminProfile(.administrator)
                    }

                    selectionButton(
                        title: "admin.profile_selection.student.title",
                        subtitle: "admin.profile_selection.student.subtitle",
                        icon: "person.fill"
                    ) {
                        session.selectAdminProfile(.student)
                    }

                    selectionButton(
                        title: "admin.profile_selection.trainer.title",
                        subtitle: "admin.profile_selection.trainer.subtitle",
                        icon: "graduationcap.fill"
                    ) {
                        session.selectAdminProfile(.trainer)
                    }
                }
                .frame(width: 300)

                Text("admin.profile_selection.change_note")
                    .font(.system(size: 13))
                    .foregroundStyle(AppThemeAdaptiveColor(textSecondary))
                    .padding(.top, 18)

                if session.isAdmin {
                    Button {
                        isTeacherAuthorizationSheetPresented = true
                    } label: {
                        Group {
                            if appTheme == .light {
                                // Tema Claro: chave e texto maiores, em verde-escuro (#294A2F)
                                HStack(spacing: 6) {
                                    Image(systemName: "key.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                    Text("teacher_authorization.admin.entry")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundStyle(lightDarkGreenBorder)
                            } else {
                                HStack(spacing: 6) {
                                    Image(systemName: "key.fill")
                                        .appThemeIconForeground()
                                    Text("teacher_authorization.admin.entry")
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Theme.Colors.accentForeground)
                            }
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 14)
                }

                Spacer()
            }
        }
        // Desfoca somente a tela de origem; o conteúdo do sheet é renderizado em outra camada e permanece nítido
        .blur(radius: isTeacherAuthorizationSheetPresented ? 8 : 0)
        .animation(.easeInOut(duration: 0.20), value: isTeacherAuthorizationSheetPresented)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $isTeacherAuthorizationSheetPresented) {
            TeacherAuthorizationCodeView()
                .presentationDetents([.fraction(0.55)])
        }
    }

    private func selectionButton(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            // Ícone à esquerda, centralizado verticalmente em relação ao conjunto título + subtítulo
            HStack(alignment: .center, spacing: 6) {
                // Mesmo padrão dos ícones de perfil da AdminUsersView
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(
                            AppThemeColor(
                                dark: Color.green.opacity(0.14),
                                light: iconSurfaceLight,
                                followsBarColorScheme: false
                            )
                        )
                        .frame(width: 34, height: 34)

                    Image(systemName: icon)
                        .foregroundStyle(
                            AppThemeColor(
                                dark: Color.green.opacity(0.85),
                                light: iconInkLight,
                                followsBarColorScheme: false
                            )
                        )
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(width: 34, height: 34)

                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink(0.92))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Theme.Colors.ink(0.65))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 12)
            .frame(width: 300, height: 74)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    // Tema Claro: mesmo verde militar a 80% do botão "Sou Aluno"; Tema Escuro inalterado
                    .fill(
                        AppThemeColor(
                            dark: Theme.Colors.glass(0.68).dark,
                            light: AppThemePalette.lightBar.opacity(0.80),
                            followsBarColorScheme: false
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                AppThemeColor(
                                    dark: Theme.Colors.cardBorder.dark,
                                    light: lightDarkGreenBorder,
                                    followsBarColorScheme: false
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: .black.opacity(0.25), radius: 10, y: 6)
            // Conteúdo claro sobre o verde militar no Tema Claro (igual ao "Sou Aluno")
            .authLightOnMilitaryGreen()
        }
        .buttonStyle(.plain)
    }
}
