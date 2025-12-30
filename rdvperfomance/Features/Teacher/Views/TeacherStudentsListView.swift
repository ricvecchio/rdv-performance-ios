import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct TeacherStudentsListView: View {

    @Binding var path: [AppRoute]
    let selectedCategory: TreinoTipo

    @State private var filter: TreinoTipo? = nil // nil = todos
    @State private var students: [Student] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    private let contentMaxWidth: CGFloat = 380
    private let service = TeacherStudentsService()

    // Computed: aplica filtro no array carregado do Firestore
    private var filteredStudents: [Student] {
        guard let filter else { return students }
        return students.filter { $0.program == filter }
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
                    HStack {
                        Spacer(minLength: 0)

                        VStack(spacing: 14) {

                            filterCard()

                            // ✅ Estados: loading / erro / vazio / lista
                            if isLoading {
                                loadingCard()
                            } else if let errorMessage {
                                errorCard(errorMessage)
                            } else if filteredStudents.isEmpty {
                                emptyStateCard()
                            } else {
                                VStack(spacing: 10) {
                                    ForEach(filteredStudents) { s in
                                        studentRow(student: s)
                                    }
                                }
                            }

                            Color.clear.frame(height: Theme.Layout.footerHeight + 20)
                        }
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        Spacer(minLength: 0)
                    }
                }

                // ✅ PROFESSOR: Home | Alunos | Sobre | Perfil
                FooterBar(
                    path: $path,
                    kind: .teacherHomeAlunosSobrePerfil(
                        selectedCategory: selectedCategory,
                        isHomeSelected: false,
                        isAlunosSelected: true,
                        isSobreSelected: false,
                        isPerfilSelected: false
                    )
                )
                .frame(height: Theme.Layout.footerHeight)
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {

            ToolbarItem(placement: .navigationBarLeading) {
                Button { pop() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("Lista de Alunos")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                MiniProfileHeader(imageName: "rdv_eu", size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            if filter == nil { filter = selectedCategory } // abre filtrado pela categoria
            Task { await loadStudents() }
        }
        .refreshable {
            await loadStudents()
        }
    }

    // MARK: - Firestore Load

    private func loadStudents() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let fetched = try await service.fetchStudentsForLoggedTeacher()
            self.students = fetched
        } catch {
            self.students = []
            self.errorMessage = error.localizedDescription
        }
    }

    // MARK: - UI

    private func filterCard() -> some View {
        VStack(alignment: .leading, spacing: 10) {

            Text("Filtro")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.55))

            Menu {
                Button("Todos") { filter = nil }
                Divider()
                Button("Crossfit") { filter = .crossfit }
                Button("Academia") { filter = .academia }
                Button("Treinos em Casa") { filter = .emCasa }
            } label: {
                HStack {
                    Text(filterTitle())
                        .foregroundColor(.white.opacity(0.92))
                        .font(.system(size: 16, weight: .medium))

                    Spacer()

                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(.green.opacity(0.85))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(14)
            }
            .buttonStyle(.plain)
        }
    }

    private func loadingCard() -> some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(.white)
            Text("Carregando alunos...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func errorCard(_ msg: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Falha ao carregar")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.95))
            Text(msg)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.18))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func emptyStateCard() -> some View {
        VStack(spacing: 10) {
            Text("Nenhum aluno encontrado")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))

            Text("Vincule alunos ao seu perfil para que apareçam aqui.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.65))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func studentRow(student: Student) -> some View {
        Button {
            path.append(.teacherStudentDetail(student: student, category: selectedCategory))
        } label: {
            VStack(alignment: .leading, spacing: 10) {

                HStack {
                    Text("Programa: \(student.program.tituloOverlayImagem)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green.opacity(0.85))

                    Spacer()

                    Text("\(Int(student.progress * 100))%")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                }

                Text("Nome: \(student.name)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.95))

                Text("Período: \(student.periodText)")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.65))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func filterTitle() -> String {
        switch filter {
        case .none: return "Todos os alunos"
        case .some(let v): return v.tituloOverlayImagem
        }
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

// ============================================================
// MARK: - Service (Firestore) — simples e direto (educacional)
// ============================================================

private final class TeacherStudentsService {

    private let db = Firestore.firestore()

    /// Busca alunos vinculados ao professor logado:
    /// - teacher_students: teacherId == currentUser.uid
    /// - para cada relação, busca o doc em users/{studentId}
    func fetchStudentsForLoggedTeacher() async throws -> [Student] {

        guard let teacherUID = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "TeacherStudents",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Você precisa estar logado como professor."]
            )
        }

        // 1) pega relações teacher_students do professor
        let relSnapshot = try await db.collection("teacher_students")
            .whereField("teacherId", isEqualTo: teacherUID)
            .getDocuments()

        let relations = relSnapshot.documents.compactMap { doc -> (studentId: String, categories: [String])? in
            let data = doc.data()
            let studentId = data["studentId"] as? String ?? ""
            let categories = data["categories"] as? [String] ?? []
            guard !studentId.isEmpty else { return nil }
            return (studentId: studentId, categories: categories)
        }

        if relations.isEmpty { return [] }

        // 2) busca cada aluno em users/{uid}
        var result: [Student] = []
        result.reserveCapacity(relations.count)

        for rel in relations {
            let userDoc = try await db.collection("users").document(rel.studentId).getDocument()
            guard let data = userDoc.data() else { continue }

            let name = (data["name"] as? String) ?? "Aluno"
            // Para o app: o "program" vem da categoria vinculada (primeira) ou fallback
            let programRaw = rel.categories.first ?? TreinoTipo.crossfit.rawValue
            let program = TreinoTipo(rawValue: programRaw) ?? .crossfit

            // Valores educacionais (até você plugar progress real)
            let progress = 0.0
            let periodText = "Semana atual • (Firebase)"

            result.append(
                Student(
                    name: name,
                    program: program,
                    periodText: periodText,
                    progress: progress
                )
            )
        }

        // 3) ordena por nome para ficar bonito
        return result.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

