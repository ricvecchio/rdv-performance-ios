import SwiftUI

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
    @StateObject private var viewModel = AdminUsersViewModel()
    @State private var selectedFilter: UserFilter = .all
    @State private var pendingDeletion: AppUser?
    @State private var showDeletionConfirmation = false
    @State private var showDeletionUnavailable = false

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
        .alert("admin.users.delete.confirmation_title", isPresented: $showDeletionConfirmation) {
            Button("common.cancel", role: .cancel) {
                pendingDeletion = nil
            }
            Button("common.delete", role: .destructive) {
                showDeletionUnavailable = true
            }
        } message: {
            Text("admin.users.delete.confirmation_message")
        }
        .alert("admin.users.delete.unavailable_title", isPresented: $showDeletionUnavailable) {
            Button("common.ok", role: .cancel) {
                pendingDeletion = nil
            }
        } message: {
            Text("admin.users.delete.unavailable_message")
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
                            .padding(.leading, 56)
                    }
                }
            }
            .background(Theme.Colors.cardBackground)
            .cornerRadius(14)
        }
    }

    private var filteredUsers: [AppUser] {
        switch selectedFilter {
        case .all:
            return viewModel.users
        case .students:
            return viewModel.users.filter(\.isStudentProfile)
        case .trainers:
            return viewModel.users.filter { !$0.isStudentProfile }
        }
    }

    private func userRow(_ user: AppUser) -> some View {
        HStack(spacing: 14) {
            NavigationLink {
                if user.isStudentProfile {
                    AdminStudentDetailView(user: user)
                } else {
                    AdminTeacherDetailView(user: user)
                }
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: user.isStudentProfile ? "person.fill" : "person.fill.checkmark")
                        .font(.system(size: 17))
                        .foregroundColor(.green.opacity(0.85))
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(user.name)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.92))
                        Text(user.email)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.55))
                        Text(
                            user.isStudentProfile
                                ? LocalizedStringKey("common.student")
                                : LocalizedStringKey("common.trainer")
                        )
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.55))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.35))
                }
            }
            .buttonStyle(.plain)

            if user.id != session.currentUid {
                Button {
                    pendingDeletion = user
                    showDeletionConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 15))
                        .foregroundColor(.red.opacity(0.9))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
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
}
