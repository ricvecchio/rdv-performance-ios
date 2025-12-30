import SwiftUI
import Combine

struct StudentWeekDetailView: View {

    @Binding var path: [AppRoute]

    let studentId: String
    let weekId: String
    let weekTitle: String

    @StateObject private var vm: StudentWeekDetailViewModel
    private let contentMaxWidth: CGFloat = 380

    init(
        path: Binding<[AppRoute]>,
        studentId: String,
        weekId: String,
        weekTitle: String,
        repository: FirestoreRepository = .shared
    ) {
        self._path = path
        self.studentId = studentId
        self.weekId = weekId
        self.weekTitle = weekTitle
        _vm = StateObject(wrappedValue: StudentWeekDetailViewModel(weekId: weekId, repository: repository))
    }

    var body: some View {
        ZStack {

            Image("rdv_fundo")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {

                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {

                        header

                        contentCard
                    }
                    .frame(maxWidth: contentMaxWidth)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                    .frame(maxWidth: .infinity)
                }

                FooterBar(
                    path: $path,
                    kind: .agendaSobrePerfil(
                        isAgendaSelected: true,
                        isSobreSelected: false,
                        isPerfilSelected: false
                    )
                )
                .frame(height: Theme.Layout.footerHeight)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.footerBackground)
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task { await vm.loadDays() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Semana")
                .font(.system(size: 26, weight: .bold))

            Text(weekTitle)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)

            Text("Dias de treino")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var contentCard: some View {
        VStack(spacing: 12) {
            if vm.isLoading {
                loadingView
            } else if let errorMessage = vm.errorMessage {
                errorView(message: errorMessage)
            } else if vm.days.isEmpty {
                emptyView
            } else {
                daysList
            }
        }
        .padding(14)
        .background(Theme.Colors.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 8)
    }

    private var daysList: some View {
        VStack(spacing: 10) {
            ForEach(Array(vm.days.enumerated()), id: \.offset) { _, day in
                HStack(spacing: 12) {

                    Circle()
                        .fill(Theme.Colors.selected.opacity(0.20))
                        .frame(width: 42, height: 42)
                        .overlay(
                            Image(systemName: "flame.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Theme.Colors.selected.opacity(0.9))
                        )

                    VStack(alignment: .leading, spacing: 3) {
                        Text(day.titleFallback)
                            .font(.system(size: 15, weight: .semibold))

                        Text(day.subtitleFallback)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 10) {
            ProgressView()
            Text("Carregando dias...")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 10) {
            Text("Ops! Não foi possível carregar.")
                .font(.system(size: 15, weight: .semibold))
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task { await vm.loadDays() }
            } label: {
                Text("Tentar novamente")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Theme.Colors.selected.opacity(0.22))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private var emptyView: some View {
        VStack(spacing: 10) {
            Text("Nenhum dia cadastrado")
                .font(.system(size: 15, weight: .semibold))
            Text("O professor ainda não adicionou dias para esta semana.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }
}

@MainActor
final class StudentWeekDetailViewModel: ObservableObject {

    @Published private(set) var days: [TrainingDayFS] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let weekId: String
    private let repository: FirestoreRepository

    init(weekId: String, repository: FirestoreRepository) {
        self.weekId = weekId
        self.repository = repository
    }

    func loadDays() async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await repository.getDaysForWeek(weekId: weekId)
            self.days = result
        } catch {
            self.errorMessage = (error as NSError).localizedDescription
        }

        isLoading = false
    }
}

private extension TrainingDayFS {

    var titleFallback: String {
        if let title = (Mirror(reflecting: self).children.first { $0.label == "title" }?.value as? String),
           !title.isEmpty { return title }
        if let name = (Mirror(reflecting: self).children.first { $0.label == "name" }?.value as? String),
           !name.isEmpty { return name }
        if let dayTitle = (Mirror(reflecting: self).children.first { $0.label == "dayTitle" }?.value as? String),
           !dayTitle.isEmpty { return dayTitle }
        return "Treino"
    }

    var subtitleFallback: String {
        if let order = (Mirror(reflecting: self).children.first { $0.label == "order" }?.value as? Int) {
            return "Ordem: \(order)"
        }
        return "Dia de treino"
    }
}

