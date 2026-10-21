import SwiftUI

struct AdminProfileSelectionView: View {
    @EnvironmentObject private var session: AppSession

    @State private var isTeacherAuthorizationSheetPresented = false

    private let textSecondary = Color.white.opacity(0.60)

    // Tema Claro: contorno verde-escuro (#294A2F), mesmo tom do card "Acesso rápido" da TeacherDashboardView
    private let lightDarkGreenBorder = Color(red: 0x29 / 255, green: 0x4A / 255, blue: 0x2F / 255)

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
                        icon: "person.crop.circle.badge.checkmark"
                    ) {
                        session.selectAdminProfile(.administrator)
                    }

                    selectionButton(
                        title: "admin.profile_selection.student.title",
                        subtitle: "admin.profile_selection.student.subtitle",
                        icon: "person.crop.circle"
                    ) {
                        session.selectAdminProfile(.student)
                    }

                    selectionButton(
                        title: "admin.profile_selection.trainer.title",
                        subtitle: "admin.profile_selection.trainer.subtitle",
                        icon: "person.2.circle"
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
                        HStack(spacing: 6) {
                            Image(systemName: "key.fill")
                                .appThemeIconForeground()
                            Text("teacher_authorization.admin.entry")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.Colors.accentForeground)
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
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink(0.92))
                    .frame(width: 22)

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
            .padding(.horizontal, 14)
            .frame(width: 300, height: 74)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.Colors.glass(0.68))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppThemeColor(dark: Theme.Colors.cardBorder.dark, light: lightDarkGreenBorder), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.25), radius: 10, y: 6)
        }
        .buttonStyle(.plain)
    }
}
