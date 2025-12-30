import SwiftUI

struct TeacherStudentsListView: View {

    @Binding var path: [AppRoute]
    let selectedCategory: TreinoTipo

    @State private var filter: TreinoTipo? = nil // nil = todos

    private let contentMaxWidth: CGFloat = 380

    private var students: [Student] {
        let base = MockStudents.all
        guard let filter else { return base }
        return base.filter { $0.program == filter }
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

                            VStack(spacing: 10) {
                                ForEach(students) { s in
                                    studentRow(student: s)
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
                        isAlunosSelected: true,   // ✅ selecionado aqui
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
        }
    }

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

