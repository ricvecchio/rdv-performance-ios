import SwiftUI

struct AdminUsersView: View {
    private enum UserFilter: CaseIterable {
        case all
        case students
        case trainers

        var title: String {
            switch self {
            case .all: return "Todos"
            case .students: return "Alunos"
            case .trainers: return "Professores"
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
            .navigationTitle("Usuários")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Administração")
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
        .alert("Excluir usuário?", isPresented: $showDeletionConfirmation) {
            Button("Cancelar", role: .cancel) {
                pendingDeletion = nil
            }
            Button("Excluir", role: .destructive) {
                showDeletionUnavailable = true
            }
        } message: {
            Text("Esta ação removerá permanentemente o usuário e seus dados relacionados. Esta operação não poderá ser desfeita.")
        }
        .alert("Exclusão indisponível", isPresented: $showDeletionUnavailable) {
            Button("OK", role: .cancel) {
                pendingDeletion = nil
            }
        } message: {
            Text("A exclusão de outra conta exige uma operação administrativa segura no servidor para também remover o usuário do Firebase Authentication.")
        }
    }

    private var administratorIndicator: some View {
        Label("MODO ADMINISTRADOR", systemImage: "exclamationmark.shield.fill")
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
            ForEach(UserFilter.allCases, id: \.title) { filter in
                Button {
                    selectedFilter = filter
                } label: {
                    Text(filter.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            selectedFilter.title == filter.title
                                ? Theme.Colors.primaryGreen.opacity(0.18)
                                : Color.white.opacity(0.10)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    selectedFilter.title == filter.title
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
            Text("Nenhum usuário encontrado.")
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
                        Text(user.isStudentProfile ? "Aluno" : "Professor")
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

    @StateObject private var viewModel = AdminStudentDetailViewModel()

    var body: some View {
        AdminDetailContainer(title: "Aluno") {
            AdminUserSummary(user: user)

            AdminSection(title: "Professores vinculados") {
                if viewModel.teachers.isEmpty {
                    AdminEmptyRow(title: "Nenhum professor vinculado.")
                } else {
                    ForEach(viewModel.teachers) { teacher in
                        AdminUserListRow(user: teacher)
                    }
                }
            }

            AdminSection(title: "Treinos do aluno") {
                if viewModel.weeks.isEmpty {
                    AdminEmptyRow(title: "Nenhum treino cadastrado.")
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
        .alert("Erro", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func weekRange(for week: TrainingWeekFS) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "dd/MM/yyyy"
        guard let start = week.startDate, let end = week.endDate else {
            return week.categoryRaw
        }
        return "\(formatter.string(from: start)) a \(formatter.string(from: end))"
    }
}

private struct AdminTeacherDetailView: View {
    let user: AppUser

    @StateObject private var viewModel = AdminTeacherDetailViewModel()

    var body: some View {
        AdminDetailContainer(title: "Professor") {
            AdminUserSummary(user: user)

            AdminSection(title: "Alunos vinculados") {
                if viewModel.students.isEmpty {
                    AdminEmptyRow(title: "Nenhum aluno vinculado.")
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
        .alert("Erro", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

private struct AdminDetailContainer<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            Image("rdv_fundo")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    Label("MODO ADMINISTRADOR", systemImage: "exclamationmark.shield.fill")
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
            Text(user.isStudentProfile ? "Aluno" : "Professor")
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
    let title: String
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
    let title: String

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
