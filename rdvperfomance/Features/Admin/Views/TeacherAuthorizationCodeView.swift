// Modal administrativo para consultar, copiar e substituir o código de autorização de professores
import SwiftUI

struct TeacherAuthorizationCodeView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = TeacherAuthorizationCodeViewModel()

    @State private var isRotateConfirmationPresented = false

    var body: some View {
        ZStack {
            Theme.Colors.headerBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        Capsule()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 44, height: 5)
                            .padding(.top, 10)

                        Text("teacher_authorization.admin.title")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 4)

                        VStack(alignment: .leading, spacing: 14) {
                            Text("teacher_authorization.admin.description")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.75))
                                .fixedSize(horizontal: false, vertical: true)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("teacher_authorization.admin.current_code")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.75))

                                HStack(spacing: 10) {
                                    if vm.isLoading {
                                        ProgressView()
                                            .tint(.white.opacity(0.9))
                                        Spacer(minLength: 0)
                                    } else if let code = vm.currentCode?.code {
                                        Text(verbatim: code)
                                            .font(.system(size: 17, weight: .bold, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.92))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                            .textSelection(.enabled)

                                        Spacer(minLength: 0)

                                        Button {
                                            vm.copyCode()
                                        } label: {
                                            Label("teacher_authorization.admin.copy", systemImage: "doc.on.doc")
                                                .padding(.horizontal, 12)
                                                .compactPrimaryGreenActionButton()
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(vm.isBusy)
                                    } else {
                                        Text(verbatim: "—")
                                            .font(.system(size: 17, weight: .bold, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.55))
                                        Spacer(minLength: 0)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .frame(minHeight: 52)
                                .background(Color.white.opacity(0.10))
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
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
                                    .foregroundColor(Theme.Colors.primaryGreen)
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
                        dismiss()
                    } label: {
                        Text("common.close")
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
                        .primaryGreenActionButton()
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

