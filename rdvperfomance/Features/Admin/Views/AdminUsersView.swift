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
                        // 1ª linha: nome + status (mesmo badge do detalhe do usuário)
                        HStack(alignment: .center, spacing: 8) {
                            Text(user.name)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white.opacity(0.92))
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .layoutPriority(1)

                            Spacer(minLength: 4)

                            AdminStatusBadge(isActive: user.isAccountActive)
                        }
                        Text(user.email)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.55))
                        Text(user.roleTitleKey)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.55))
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
                    // Ações da lixeira (mesmo padrão de Menu de "Cancelar convite"):
                    // desativar/reativar, excluir definitivamente, cancelar
                    Menu {
                        Section("admin.users.manage.title") {
                            if !user.isAdministratorProfile {
                                if user.isAccountActive {
                                    Button(role: .destructive) {
                                        managedUser = user
                                        showStatusConfirmation = true
                                    } label: {
                                        Label(LocalizedStringKey("admin.users.deactivate"), systemImage: "person.crop.circle.badge.xmark")
                                    }
                                } else {
                                    Button {
                                        managedUser = user
                                        showStatusConfirmation = true
                                    } label: {
                                        Label(LocalizedStringKey("admin.users.reactivate"), systemImage: "person.crop.circle.badge.checkmark")
                                    }
                                }
                            }
                            Button(role: .destructive) {
                                managedUser = user
                                pendingDeletion = user
                                showDeletionUnavailable = true
                            } label: {
                                Label(LocalizedStringKey("admin.users.delete.permanent"), systemImage: "trash")
                            }
                        }
                        Section {
                            Button(role: .cancel) {
                                managedUser = nil
                            } label: {
                                Label(LocalizedStringKey("common.cancel"), systemImage: "xmark.circle")
                            }
                        }
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
        if user.isAdministratorProfile { return "gearshape.fill" }
        if user.isStudentProfile { return "person.fill" }
        return "graduationcap.fill"
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

            AdminCardSection(title: "admin.student.linked_trainers", systemImage: "person.2.fill") {
                if viewModel.teachers.isEmpty {
                    AdminEmptyRow(title: "admin.student.no_linked_trainers")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .adminInnerListStyle()
                } else {
                    VStack(spacing: 8) {
                        ForEach(viewModel.teachers) { teacher in
                            AdminLinkedUserCard(user: teacher)
                        }
                    }
                }
            }

            AdminCardSection(title: "admin.student.workouts", systemImage: "calendar") {
                if viewModel.weeks.isEmpty {
                    AdminEmptyRow(title: "admin.student.no_workouts")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .adminInnerListStyle()
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.weeks.enumerated()), id: \.element.id) { index, week in
                            HStack(spacing: 12) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Theme.Colors.primaryGreen.opacity(0.9))
                                    .frame(width: 22)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(week.weekTitle)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.92))
                                    Text(weekRange(for: week))
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.55))
                                }

                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)

                            if index < viewModel.weeks.count - 1 {
                                Divider()
                                    .background(Theme.Colors.divider)
                                    .padding(.leading, 46)
                            }
                        }
                    }
                    .adminInnerListStyle()
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
                    AdminModeNotice()
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

// Aviso exclusivamente informativo do modo administrador
private struct AdminModeNotice: View {
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.red.opacity(0.95))

            VStack(alignment: .leading, spacing: 4) {
                Text("admin.mode_indicator")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.red.opacity(0.95))
                Text("admin.detail.mode_description")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            ZStack {
                Color.black.opacity(0.68)
                Color.red.opacity(0.12)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.red.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct AdminUserSummary: View {
    let user: AppUser
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(spacing: 16) {
            mainCard
            AdminDeviceCard(user: user)
        }
    }

    private var mainCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Identificação (sem navegação: não há ação existente ao tocar no card)
            HStack(alignment: .center, spacing: 14) {
                UserAvatarView(base64: user.photoBase64, size: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                        .lineLimit(2)
                    Text(user.email)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.55))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    HStack(spacing: 6) {
                        Image(systemName: user.roleIconName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.Colors.primaryGreen.opacity(0.9))
                        Text(user.roleTitleKey)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.65))
                    }
                }

                Spacer(minLength: 8)

                AdminStatusBadge(isActive: user.isAccountActive)
            }

            Divider()
                .background(Theme.Colors.divider)

            HStack(spacing: 10) {
                AdminInfoTile(
                    systemImage: "cube.fill",
                    title: "admin.detail.app_version",
                    value: installedVersionText.map { Text(verbatim: $0) }
                        ?? Text("admin.detail.not_informed_female")
                )
                // users/{uid}.lastAccessAt, gravado pelo próprio usuário (ausente em registros antigos)
                AdminInfoTile(
                    systemImage: "clock.fill",
                    title: "admin.detail.last_access",
                    value: lastAccessText.map { Text(verbatim: $0) }
                        ?? Text("admin.detail.not_informed")
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .adminCardStyle()
    }

    private var installedVersionText: String? {
        let version = (user.appVersion ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return version.isEmpty ? nil : version
    }

    // Data e horário do último acesso, conforme a localização do app
    private var lastAccessText: String? {
        guard let date = user.lastAccessAt else { return nil }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("ddMMyyjjmm")
        return formatter.string(from: date)
    }
}

// Badge de status da conta: users/{uid}.active (nil em registros legados = ativo)
private struct AdminStatusBadge: View {
    let isActive: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isActive ? Color.green.opacity(0.85) : Color.red.opacity(0.55))
                .frame(width: 7, height: 7)
            Text(
                isActive
                    ? LocalizedStringKey("admin.users.status.active")
                    : LocalizedStringKey("admin.users.status.inactive")
            )
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white.opacity(0.85))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(isActive ? Color.green.opacity(0.14) : Color.red.opacity(0.14))
        )
        .overlay(
            Capsule()
                .stroke(isActive ? Color.green.opacity(0.30) : Color.red.opacity(0.30), lineWidth: 1)
        )
        .fixedSize()
    }
}

private struct AdminInfoTile: View {
    let systemImage: String
    let title: LocalizedStringKey
    let value: Text

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.Colors.primaryGreen.opacity(0.9))
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                value
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// Apenas dados persistidos do próprio usuário consultado; nunca dados do aparelho do administrador
private struct AdminDeviceCard: View {
    let user: AppUser

    var body: some View {
        AdminCardSection(title: "admin.detail.device.title", systemImage: "iphone") {
            VStack(spacing: 0) {
                row(systemImage: "iphone.gen3", title: "admin.detail.device.model", value: storedText(displayModel(user.deviceModel)))
                rowDivider
                row(systemImage: "gearshape.fill", title: "admin.detail.device.system", value: storedText(user.deviceSystem))
                rowDivider
                row(systemImage: "number", title: "admin.detail.device.identifier", value: storedText(user.deviceIdentifier))
                rowDivider
                row(
                    systemImage: "cube.fill",
                    title: "admin.detail.device.app_version",
                    value: versionAndBuildText.map { Text(verbatim: $0) }
                        ?? Text("admin.detail.not_informed_female")
                )
            }
            .adminInnerListStyle()
        }
    }

    private var rowDivider: some View {
        Divider()
            .background(Theme.Colors.divider)
            .padding(.leading, 46)
    }

    private func row(systemImage: String, title: LocalizedStringKey, value: Text) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.Colors.primaryGreen.opacity(0.9))
                .frame(width: 22)

            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.65))
                .lineLimit(1)

            Spacer(minLength: 8)

            value
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }

    // Valor persistido em users/{uid} pelo próprio usuário; ausente = "Não informado"
    private func storedText(_ raw: String?) -> Text {
        let value = (raw ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? Text("admin.detail.not_informed") : Text(verbatim: value)
    }

    // Nome comercial somente para identificadores técnicos conhecidos; caso contrário, o identificador real
    private func displayModel(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let identifier = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return Self.commercialModelNames[identifier] ?? identifier
    }

    private static let commercialModelNames: [String: String] = [
        "iPhone10,1": "iPhone 8", "iPhone10,4": "iPhone 8",
        "iPhone10,2": "iPhone 8 Plus", "iPhone10,5": "iPhone 8 Plus",
        "iPhone10,3": "iPhone X", "iPhone10,6": "iPhone X",
        "iPhone11,2": "iPhone XS", "iPhone11,4": "iPhone XS Max", "iPhone11,6": "iPhone XS Max",
        "iPhone11,8": "iPhone XR",
        "iPhone12,1": "iPhone 11", "iPhone12,3": "iPhone 11 Pro", "iPhone12,5": "iPhone 11 Pro Max",
        "iPhone12,8": "iPhone SE (2nd generation)",
        "iPhone13,1": "iPhone 12 mini", "iPhone13,2": "iPhone 12",
        "iPhone13,3": "iPhone 12 Pro", "iPhone13,4": "iPhone 12 Pro Max",
        "iPhone14,4": "iPhone 13 mini", "iPhone14,5": "iPhone 13",
        "iPhone14,2": "iPhone 13 Pro", "iPhone14,3": "iPhone 13 Pro Max",
        "iPhone14,6": "iPhone SE (3rd generation)",
        "iPhone14,7": "iPhone 14", "iPhone14,8": "iPhone 14 Plus",
        "iPhone15,2": "iPhone 14 Pro", "iPhone15,3": "iPhone 14 Pro Max",
        "iPhone15,4": "iPhone 15", "iPhone15,5": "iPhone 15 Plus",
        "iPhone16,1": "iPhone 15 Pro", "iPhone16,2": "iPhone 15 Pro Max",
        "iPhone17,1": "iPhone 16 Pro", "iPhone17,2": "iPhone 16 Pro Max",
        "iPhone17,3": "iPhone 16", "iPhone17,4": "iPhone 16 Plus", "iPhone17,5": "iPhone 16e",
        "iPhone18,1": "iPhone 17 Pro", "iPhone18,2": "iPhone 17 Pro Max",
        "iPhone18,3": "iPhone 17", "iPhone18,4": "iPhone Air"
    ]

    // Versão e build informados pelo dispositivo do próprio usuário
    private var versionAndBuildText: String? {
        let version = (user.appVersion ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let build = (user.appBuild ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !version.isEmpty else { return nil }
        return build.isEmpty ? version : "\(version) (\(build))"
    }
}

// Card de seção com título e ícone verdes, no padrão visual da tela de detalhes
private struct AdminCardSection<Content: View>: View {
    let title: LocalizedStringKey
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Theme.Colors.primaryGreen.opacity(0.95))
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
            }

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .adminCardStyle()
    }
}

// Professor vinculado em card interno (sem navegação: não há ação existente)
private struct AdminLinkedUserCard: View {
    let user: AppUser

    var body: some View {
        HStack(spacing: 12) {
            UserAvatarView(base64: user.photoBase64, size: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(user.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(1)
                Text(user.email)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .adminInnerListStyle()
    }
}

private extension View {
    func adminCardStyle() -> some View {
        self
            .background(Color.black.opacity(0.68))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.Colors.primaryGreen.opacity(0.28), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    func adminInnerListStyle() -> some View {
        self
            .background(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
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

    // Mesmo mapeamento de ícones por perfil usado na lista de usuários
    var roleIconName: String {
        if isAdministratorProfile { return "person.crop.circle.badge.checkmark" }
        if isStudentProfile { return "person.fill" }
        return "person.fill.checkmark"
    }
}
