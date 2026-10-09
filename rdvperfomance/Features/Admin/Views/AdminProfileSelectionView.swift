import SwiftUI

struct AdminProfileSelectionView: View {
    @EnvironmentObject private var session: AppSession

    @State private var isTeacherAuthorizationSheetPresented = false

    private let textSecondary = Color.white.opacity(0.60)

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
                    .frame(width: 260)
                    .opacity(0.9)
                    .shadow(color: .black.opacity(0.5), radius: 10, y: 6)
                    .padding(.top, 20)

                Text("admin.profile_selection.prompt")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.top, 10)
                    .padding(.bottom, 22)

                VStack(spacing: 14) {
                    selectionButton(
                        title: "admin.profile_selection.administrator.title",
                        subtitle: "admin.profile_selection.administrator.subtitle"
                    ) {
                        session.selectAdminProfile(.administrator)
                    }

                    selectionButton(
                        title: "admin.profile_selection.student.title",
                        subtitle: "admin.profile_selection.student.subtitle"
                    ) {
                        session.selectAdminProfile(.student)
                    }

                    selectionButton(
                        title: "admin.profile_selection.trainer.title",
                        subtitle: "admin.profile_selection.trainer.subtitle"
                    ) {
                        session.selectAdminProfile(.trainer)
                    }
                }
                .frame(width: 300)

                Text("admin.profile_selection.change_note")
                    .font(.system(size: 13))
                    .foregroundColor(textSecondary)
                    .padding(.top, 18)

                if session.isAdmin {
                    Button {
                        isTeacherAuthorizationSheetPresented = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "key.fill")
                            Text("teacher_authorization.admin.entry")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.primaryGreen)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 14)
                }

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $isTeacherAuthorizationSheetPresented) {
            TeacherAuthorizationCodeView()
                .presentationDetents([.fraction(0.55)])
        }
    }

    private func selectionButton(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))

                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
            }
            .frame(width: 300, height: 74)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.68))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Theme.Colors.primaryGreen.opacity(0.28), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.25), radius: 10, y: 6)
        }
        .buttonStyle(.plain)
    }
}
