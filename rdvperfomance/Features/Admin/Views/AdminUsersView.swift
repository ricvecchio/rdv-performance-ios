import SwiftUI
import UIKit

struct AdminUsersView: View {
    private enum UserFilter: CaseIterable {
        case all
        case students
        case trainers

        var title: LocalizedStringKey {
            switch self {
            case .all: return "common.all"
            case .students: return "common.students"
            case .trainers: return "common.trainers"
            }
        }
    }

    @EnvironmentObject private var session: AppSession
    @Environment(\.locale) private var locale
    @StateObject private var viewModel = AdminUsersViewModel()
    @State private var selectedFilter: UserFilter = .all
    @State private var pendingDeletion: AppUser?
    @State private var showDeletionUnavailable = false
    @State private var managedUser: AppUser?
    @State private var showManageOptions = false
    @State private var showStatusConfirmation = false

    private let contentMaxWidth: CGFloat = 380

    var body: some View {
        NavigationStack {
            ZStack {
                Image("rdv_fundo")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        administratorIndicator
                        filterRow
                        content
                    }
                    .frame(maxWidth: contentMaxWidth)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("admin.users.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("admin.users.toolbar_title")
                        .font(Theme.Fonts.headerTitle())
                        .foregroundColor(.white)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        session.clearAdminProfileMode()
                    } label: {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(.red.opacity(0.9))
                    }
                    .buttonStyle(.plain)
                }
            }
            .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .task {
            await viewModel.loadUsers()
        }
        // Ações da lixeira: desativar/reativar, excluir definitivamente, cancelar
        .confirmationDialog(
            "admin.users.manage.title",
            isPresented: $showManageOptions,
            titleVisibility: .visible,
            presenting: managedUser
        ) { user in
            if !user.isAdministratorProfile {
                if user.isAccountActive {
                    Button("admin.users.deactivate", role: .destructive) {
                        showStatusConfirmation = true
                    }
                } else {
                    Button("admin.users.reactivate") {
                        showStatusConfirmation = true
                    }
                }
            }
            Button("admin.users.delete.permanent", role: .destructive) {
                pendingDeletion = user
                showDeletionUnavailable = true
            }
            Button("common.cancel", role: .cancel) {
                managedUser = nil
            }
        }
        .alert(
            (managedUser?.isAccountActive ?? true)
                ? LocalizedStringKey("admin.users.deactivate.confirmation_title")
                : LocalizedStringKey("admin.users.reactivate.confirmation_title"),
            isPresented: $showStatusConfirmation,
            presenting: managedUser
        ) { user in
            Button("common.cancel", role: .cancel) {
                managedUser = nil
            }
            Button(
                user.isAccountActive
                    ? LocalizedStringKey("admin.users.deactivate.confirm")
                    : LocalizedStringKey("admin.users.reactivate.confirm"),
                role: user.isAccountActive ? .destructive : nil
            ) {
                let activate = !user.isAccountActive
                managedUser = nil
                Task {
                    await viewModel.setAccountActive(user, active: activate, adminUid: session.currentUid)
                }
            }
        } message: { user in
            Text(
                user.isAccountActive
                    ? LocalizedStringKey("admin.users.deactivate.confirmation_message")
                    : LocalizedStringKey("admin.users.reactivate.confirmation_message")
            )
        }
        // Exclusão definitiva exige operação administrativa no servidor (Admin SDK):
        // não é executada pelo app (ver firebase/admin-tools/delete-user.js)
        .alert("admin.users.delete.unavailable_title", isPresented: $showDeletionUnavailable) {
            if let uid = pendingDeletion?.id, !uid.isEmpty {
                Button("admin.users.copy_uid") {
                    UIPasteboard.general.string = uid
                    pendingDeletion = nil
                    managedUser = nil
                }
            }
            Button("common.ok", role: .cancel) {
                pendingDeletion = nil
                managedUser = nil
            }
        } message: {
            Text("admin.users.delete.unavailable_message")
                + Text(verbatim: "\n\nUID: \(pendingDeletion?.id ?? "")")
        }
        .alert("common.error", isPresented: Binding(
            get: { viewModel.actionErrorMessage != nil },
            set: { if !$0 { viewModel.actionErrorMessage = nil } }
        )) {
            Button("common.ok", role: .cancel) { viewModel.actionErrorMessage = nil }
        } message: {
            Text(viewModel.actionErrorMessage ?? "")
        }
    }

    private var administratorIndicator: some View {
        Label(LocalizedStringKey("admin.mode_indicator"), systemImage: "exclamationmark.shield.fill")
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(.red.opacity(0.95))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.red.opacity(0.14))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.red.opacity(0.35), lineWidth: 1)
            )
            .cornerRadius(12)
    }

    private var filterRow: some View {
        HStack(spacing: 8) {
            ForEach(UserFilter.allCases, id: \.self) { filter in
                Button {
                    selectedFilter = filter
                } label: {
                    Text(filter.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            selectedFilter == filter
                                ? Theme.Colors.primaryGreen.opacity(0.18)
                                : Color.white.opacity(0.10)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    selectedFilter == filter
                                        ? Theme.Colors.primaryGreen.opacity(0.30)
                                        : Color.white.opacity(0.12),
                                    lineWidth: 1
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView()
                .tint(.white)
                .padding(.vertical, 32)
        } else if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.65))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(14)
        } else if filteredUsers.isEmpty {
            Text("admin.users.empty")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(14)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(filteredUsers.enumerated()), id: \.element.id) { index, user in
                    userRow(user)

                    if index < filteredUsers.count - 1 {
                        Divider()
                            .background(Theme.Colors.divider)
                            .padding(.leading, 64)
                    }
                }
            }
            .background(Color.black.opacity(0.68))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.Colors.primaryGreen.opacity(0.28), lineWidth: 1)
            )
        }
    }

    private var filteredUsers: [AppUser] {
        switch selectedFilter {
        case .all:
            return viewModel.users
        case .students:
            return viewModel.users.filter(\.isStudentProfile)
        case .trainers:
            // ADMIN não é professor: aparece somente em "Todos"
            return viewModel.users.filter { !$0.isStudentProfile && !$0.isAdministratorProfile }
        }
    }

    private func userRow(_ user: AppUser) -> some View {
        HStack(spacing: 14) {
            NavigationLink {
                if user.isStudentProfile {
                    AdminStudentDetailView(user: user)
                } else if user.isAdministratorProfile {
                    // ADMIN não é professor: exibe somente o resumo com os componentes existentes
                    AdminDetailContainer(title: "common.administrator") {
                        AdminUserSummary(user: user)
                    }
                } else {
                    AdminTeacherDetailView(user: user)
                }
            } label: {
                HStack(spacing: 14) {
                    // Mesmo padrão do ícone de BarbellPersonalRecordsView (tableRow)
                    ZStack {
                        RoundedRectangle(cornerRadius: 9)
                            .fill(Color.green.opacity(0.14))
                            .frame(width: 34, height: 34)

                        Image(systemName: profileIconName(for: user))
                            .foregroundColor(.green.opacity(0.85))
                            .font(.system(size: 16, weight: .semibold))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(user.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white.opacity(0.92))
                        Text(user.email)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.55))
                        Text(user.roleTitleKey)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.55))
                        accountStatusLine(user)
                        versionLine(user)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.35))
                }
            }
            .buttonStyle(.plain)

            if user.id != session.currentUid {
                if viewModel.updatingUserId != nil && viewModel.updatingUserId == user.id {
                    ProgressView()
                        .tint(.white)
                } else {
                    Button {
                        managedUser = user
                        showManageOptions = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 15))
                            .foregroundColor(.red.opacity(0.9))
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.updatingUserId != nil)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    // Ícone por perfil: ADMIN primeiro, para não ser classificado como professor
    private func profileIconName(for user: AppUser) -> String {
        if user.isAdministratorProfile { return "person.crop.circle.badge.checkmark" }
        if user.isStudentProfile { return "person.fill" }
        return "person.fill.checkmark"
    }

    // Status persistido em users/{uid}.active (nil em registros legados = ativo)
    private func accountStatusLine(_ user: AppUser) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(user.isAccountActive ? Color.green.opacity(0.85) : Color.red.opacity(0.55))
                .frame(width: 7, height: 7)
            Text(
                user.isAccountActive
                    ? LocalizedStringKey("admin.users.status.active")
                    : LocalizedStringKey("admin.users.status.inactive")
            )
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white.opacity(0.55))
        }
    }

    // Versão informada pelo dispositivo do usuário, comparada com latestVersion de app_config/ios
    private func versionLine(_ user: AppUser) -> some View {
        let installedRaw = (user.appVersion ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        guard let installed = AppVersion(installedRaw) else {
            return Text("admin.users.version.not_informed")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.45))
        }

        let format = AppLocalization.string("admin.users.version.value", locale: locale)
        let versionText = Text(verbatim: String(format: format, locale: locale, arguments: [installedRaw]))
            .foregroundColor(.white.opacity(0.55))
        let separator = Text(verbatim: " — ").foregroundColor(.white.opacity(0.55))

        let statusText: Text
        if let reference = viewModel.versionReference {
            statusText = installed < reference.latestVersion
                ? Text("admin.users.version.outdated").foregroundColor(Color.yellow.opacity(0.9))
                : Text("admin.users.version.up_to_date").foregroundColor(Color.green.opacity(0.85))
        } else {
            statusText = Text("admin.users.version.no_reference").foregroundColor(.white.opacity(0.45))
        }

        return (versionText + separator + statusText)
            .font(.system(size: 12))
    }
}

private struct AdminStudentDetailView: View {
    let user: AppUser
    @Environment(\.locale) private var locale

    @StateObject private var viewModel = AdminStudentDetailViewModel()

    var body: some View {
        AdminDetailContainer(title: "common.student") {
            AdminUserSummary(user: user)

            AdminSection(title: "admin.student.linked_trainers") {
                if viewModel.teachers.isEmpty {
                    AdminEmptyRow(title: "admin.student.no_linked_trainers")
                } else {
                    ForEach(viewModel.teachers) { teacher in
                        AdminUserListRow(user: teacher)
                    }
                }
            }

            AdminSection(title: "admin.student.workouts") {
                if viewModel.weeks.isEmpty {
                    AdminEmptyRow(title: "admin.student.no_workouts")
                } else {
                    ForEach(viewModel.weeks) { week in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(week.weekTitle)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.92))
                            Text(weekRange(for: week))
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 10)
                    }
                }
            }
        }
        .task {
            guard let userId = user.id, !userId.isEmpty else { return }
            await viewModel.load(studentId: userId)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView().tint(.white)
            }
        }
        .alert("common.error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("common.ok", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func weekRange(for week: TrainingWeekFS) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("ddMMyyyy")
        guard let start = week.startDate, let end = week.endDate else {
            return week.categoryRaw
        }
        let format = AppLocalization.string("common.date_range", locale: locale)
        return String(
            format: format,
            locale: locale,
            arguments: [formatter.string(from: start), formatter.string(from: end)]
        )
    }
}

private struct AdminTeacherDetailView: View {
    let user: AppUser

    @StateObject private var viewModel = AdminTeacherDetailViewModel()

    var body: some View {
        AdminDetailContainer(title: "common.trainer") {
            AdminUserSummary(user: user)

            AdminSection(title: "admin.trainer.linked_students") {
                if viewModel.students.isEmpty {
                    AdminEmptyRow(title: "admin.trainer.no_linked_students")
                } else {
                    ForEach(viewModel.students) { student in
                        AdminUserListRow(user: student)
                    }
                }
            }
        }
        .task {
            guard let userId = user.id, !userId.isEmpty else { return }
            await viewModel.load(teacherId: userId)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView().tint(.white)
            }
        }
        .alert("common.error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("common.ok", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

private struct AdminDetailContainer<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            Image("rdv_fundo")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    Label(LocalizedStringKey("admin.mode_indicator"), systemImage: "exclamationmark.shield.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.red.opacity(0.95))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    content
                }
                .frame(maxWidth: 380)
                .padding(16)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

private struct AdminUserSummary: View {
    let user: AppUser

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(user.name)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))
            Text(user.email)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
            Text(
                user.isStudentProfile
                    ? LocalizedStringKey("common.student")
                    : LocalizedStringKey("common.trainer")
            )
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }
}

private struct AdminSection<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.55))
            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .padding(.horizontal, 16)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AdminUserListRow: View {
    let user: AppUser

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(user.name)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.92))
            Text(user.email)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
    }
}

private struct AdminEmptyRow: View {
    let title: LocalizedStringKey

    var body: some View {
        Text(title)
            .font(.system(size: 14))
            .foregroundColor(.white.opacity(0.55))
            .padding(.vertical, 14)
    }
}

private extension AppUser {
    var isStudentProfile: Bool {
        userType.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "STUDENT"
    }

    var roleTitleKey: LocalizedStringKey {
        if isStudentProfile { return "common.student" }
        if isAdministratorProfile { return "common.administrator" }
        return "common.trainer"
    }
}
