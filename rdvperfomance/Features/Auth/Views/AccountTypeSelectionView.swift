// Tela de seleção de tipo de conta (aluno ou professor)
import SwiftUI

struct AccountTypeSelectionView: View {

    @Binding var path: [AppRoute]

    @State private var isTeacherCodeSheetPresented = false
    @State private var teacherCodeInput = ""
    @State private var teacherCodeError: String?
    @State private var isValidatingTeacherCode = false
    @State private var shouldOpenTeacherRegistration = false

    private let teacherAuthorizationService = TeacherAuthorizationService()

    private let textSecondary = Color.white.opacity(0.60)

    // Interface principal com logo e botões de seleção
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

                Text("auth.account_type.prompt")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.top, 10)
                    .padding(.bottom, 22)

                VStack(spacing: 14) {

                    selectionButton(
                        title: "auth.account_type.student.title",
                        subtitle: "auth.account_type.student.subtitle"
                    ) {
                        path.append(.registerStudent)
                    }

                    selectionButton(
                        title: "auth.account_type.trainer.title",
                        subtitle: "auth.account_type.trainer.subtitle"
                    ) {
                        presentTeacherCodeSheet()
                    }
                }
                .frame(width: 300)

                Text("auth.account_type.change_note")
                    .font(.system(size: 13))
                    .foregroundColor(textSecondary)
                    .padding(.top, 18)

                Spacer()
            }
        }
        .blur(radius: isTeacherCodeSheetPresented ? 8 : 0)
        .animation(.easeInOut(duration: 0.20), value: isTeacherCodeSheetPresented)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { pop() } label: {
                    ZStack {
                        Color.clear
                            .frame(width: 44, height: 44)

                        Image(systemName: "chevron.left")
                            .foregroundColor(.green)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("auth.registration.title")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $isTeacherCodeSheetPresented, onDismiss: handleTeacherCodeSheetDismiss) {
            teacherCodeSheet
                .presentationDetents([.fraction(0.50)])
                .interactiveDismissDisabled(isValidatingTeacherCode)
        }
    }

    // Modal para informar o código de autorização de professor
    private var teacherCodeSheet: some View {
        ZStack {
            Theme.Colors.headerBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        Capsule()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 44, height: 5)
                            .padding(.top, 10)

                        Text("teacher_authorization.title")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 4)

                        VStack(alignment: .leading, spacing: 14) {
                            Text("teacher_authorization.prompt")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.75))
                                .fixedSize(horizontal: false, vertical: true)

                            TextField("teacher_authorization.placeholder", text: $teacherCodeInput)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled(true)
                                .textContentType(.oneTimeCode)
                                .font(.system(size: 16, weight: .semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.10))
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                                )
                                .foregroundColor(.white.opacity(0.92))
                                .disabled(isValidatingTeacherCode)
                                .onSubmit { validateTeacherCode() }

                            if let teacherCodeError {
                                Text(teacherCodeError)
                                    .font(.system(size: 13))
                                    .foregroundColor(.yellow.opacity(0.95))
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.Colors.cardBackground)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        isTeacherCodeSheetPresented = false
                    } label: {
                        Text("common.cancel")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.10))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(isValidatingTeacherCode)

                    Button {
                        validateTeacherCode()
                    } label: {
                        HStack(spacing: 10) {
                            Text("teacher_authorization.continue")

                            if isValidatingTeacherCode {
                                ProgressView()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .primaryGreenActionButton()
                    }
                    .buttonStyle(.plain)
                    .disabled(
                        isValidatingTeacherCode
                            || teacherCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 16)
            }
        }
    }

    // Abre o modal de autorização, descartando qualquer autorização anterior
    private func presentTeacherCodeSheet() {
        TeacherSignupAuthorizationStore.shared.clear()
        teacherCodeInput = ""
        teacherCodeError = nil
        shouldOpenTeacherRegistration = false
        isTeacherCodeSheetPresented = true
    }

    // Valida o código no backend; a navegação só é liberada com autorização emitida pelo servidor
    private func validateTeacherCode() {
        let code = teacherCodeInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty, !isValidatingTeacherCode else { return }

        teacherCodeError = nil
        isValidatingTeacherCode = true

        Task {
            defer { isValidatingTeacherCode = false }

            do {
                let ticket = try await teacherAuthorizationService.validateCode(code)
                TeacherSignupAuthorizationStore.shared.store(ticket: ticket)
                teacherCodeInput = ""
                shouldOpenTeacherRegistration = true
                isTeacherCodeSheetPresented = false
            } catch let error as TeacherAuthorizationError {
                teacherCodeError = error.localizedDescription
            } catch {
                teacherCodeError = TeacherAuthorizationError.unknown.localizedDescription
            }
        }
    }

    // Navega para o cadastro somente após autorização válida
    private func handleTeacherCodeSheetDismiss() {
        teacherCodeInput = ""
        teacherCodeError = nil

        guard shouldOpenTeacherRegistration else { return }
        shouldOpenTeacherRegistration = false
        path.append(.registerTrainer)
    }

    // Retorna botão estilizado para seleção de tipo de usuário
    private func selectionButton(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))

                Text(subtitle)
                    .font(.system(size: 14, weight: .regular))
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

    // Remove a última rota da pilha de navegação
    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
