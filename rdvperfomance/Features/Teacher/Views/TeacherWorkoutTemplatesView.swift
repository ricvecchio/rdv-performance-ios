import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct TeacherWorkoutTemplatesView: View {

    @Binding var path: [AppRoute]
    let category: TreinoTipo
    let sectionKey: String
    let sectionTitle: String

    @State private var templates: [WorkoutTemplateFS] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    private let contentMaxWidth: CGFloat = 380

    // ✅ Girls WODs = seção "benchmarks" (chave estável no Firestore)
    private var isGirlsWodsSection: Bool {
        sectionKey == CrossfitLibrarySection.benchmarks.firestoreKey
    }

    // ✅ Um sheet só (evita sheet em branco e conflito)
    @State private var activeSheet: ActiveSheet? = nil

    private enum ActiveSheet: Identifiable {
        case detail(WorkoutTemplateFS)
        case send(WorkoutTemplateFS)

        var id: String {
            switch self {
            case .detail(let t):
                return "detail-\(t.id ?? UUID().uuidString)"
            case .send(let t):
                return "send-\(t.id ?? UUID().uuidString)"
            }
        }
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

                        VStack(alignment: .leading, spacing: 14) {

                            Text("\(category.displayName) • \(sectionTitle)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.green.opacity(0.85))

                            Text("Cadastre e gerencie os WODs desta seção.")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.55))

                            if isGirlsWodsSection {
                                addWodButtonCard
                            }

                            contentCard

                            if let err = errorMessage {
                                messageCard(text: err, isError: true)
                            }

                            Color.clear.frame(height: Theme.Layout.footerHeight + 20)
                        }
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        Spacer(minLength: 0)
                    }
                }

                FooterBar(
                    path: $path,
                    kind: .teacherHomeAlunosSobrePerfil(
                        selectedCategory: category,
                        isHomeSelected: false,
                        isAlunosSelected: false,
                        isSobreSelected: false,
                        isPerfilSelected: false
                    )
                )
                .frame(height: Theme.Layout.footerHeight)
                .background(Theme.Colors.footerBackground)
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
                Text(sectionTitle)
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
                    .lineLimit(1)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { await loadTemplates() }
        .onAppear { Task { await loadTemplates() } }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .detail(let t):
                TeacherWorkoutTemplateDetailSheet(template: t)

            case .send(let t):
                TeacherSendWorkoutToStudentSheet(
                    template: t,
                    category: category
                )
            }
        }
    }

    private var addWodButtonCard: some View {
        Button {
            path.append(.createGirlsWOD(category: category, sectionKey: sectionKey, sectionTitle: sectionTitle))
        } label: {
            HStack {
                Image(systemName: "plus")
                Text("Adicionar WOD")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
            }
            .foregroundColor(.white.opacity(0.92))
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Capsule().fill(Color.green.opacity(0.16)))
        }
        .buttonStyle(.plain)
    }

    private var contentCard: some View {
        VStack(spacing: 0) {
            if isLoading {
                loadingView
            } else if templates.isEmpty {
                emptyView
            } else {
                templatesList
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var templatesList: some View {
        VStack(spacing: 0) {
            ForEach(templates.indices, id: \.self) { idx in
                let t = templates[idx]

                templateRow(template: t)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // ✅ abre detalhe do treino
                        activeSheet = .detail(t)
                    }

                if idx < templates.count - 1 {
                    innerDivider(leading: 14)
                }
            }
        }
    }

    private func templateRow(template t: WorkoutTemplateFS) -> some View {
        HStack(spacing: 12) {

            Image(systemName: "flame.fill")
                .foregroundColor(.green.opacity(0.85))
                .font(.system(size: 16))
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 4) {
                Text(t.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))

                let sub = t.description.trimmingCharacters(in: .whitespacesAndNewlines)
                if !sub.isEmpty {
                    Text(sub)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.55))
                        .lineLimit(2)
                }
            }

            Spacer()

            // ✅ 3 pontinhos: enviar para aluno
            Menu {
                Button {
                    activeSheet = .send(t)
                } label: {
                    Label("Enviar para aluno", systemImage: "paperplane.fill")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.55))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.35))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }

    private var loadingView: some View {
        VStack(spacing: 10) {
            ProgressView()
            Text("Carregando...")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private var emptyView: some View {
        VStack(spacing: 10) {
            Text("Nenhum WOD cadastrado")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))

            Text(isGirlsWodsSection ? "Toque em “Adicionar WOD” para começar." : "Cadastre templates para aparecerem aqui.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 10)
    }

    private func messageCard(text: String, isError: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundColor(isError ? .yellow.opacity(0.85) : .green.opacity(0.85))

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.75))

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.35))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func innerDivider(leading: CGFloat) -> some View {
        Divider()
            .background(Theme.Colors.divider)
            .padding(.leading, leading)
    }

    private func loadTemplates() async {
        errorMessage = nil

        let teacherId = (Auth.auth().currentUser?.uid ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !teacherId.isEmpty else {
            errorMessage = "Não foi possível identificar o professor logado."
            templates = []
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            templates = try await FirestoreRepository.shared.getWorkoutTemplates(
                teacherId: teacherId,
                categoryRaw: category.rawValue,
                sectionKey: sectionKey
            )
        } catch {
            errorMessage = error.localizedDescription
            templates = []
        }
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

// ============================================================
// MARK: - ✅ Sheet: Detalhe do treino (visualização completa)
// ============================================================

private struct TeacherWorkoutTemplateDetailSheet: View {

    let template: WorkoutTemplateFS
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.headerBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {

                        VStack(alignment: .leading, spacing: 8) {
                            Text(template.title)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white.opacity(0.92))

                            let desc = template.description.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !desc.isEmpty {
                                Text(desc)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.70))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        if let blocks = template.blocks, !blocks.isEmpty {
                            VStack(spacing: 12) {
                                ForEach(blocks.indices, id: \.self) { i in
                                    let b = blocks[i]
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(b.name.isEmpty ? "Bloco" : b.name)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.85))

                                        Text(b.details)
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.70))
                                            .frame(maxWidth: .infinity, alignment: .leading)
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
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Sem blocos cadastrados")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.92))

                                Text("Este WOD ainda não possui Aquecimento/Técnica/WOD/Blocos.")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.55))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                        }
                    }
                }
            }
            .navigationTitle("Treino")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
    }
}

// ============================================================
// MARK: - ✅ Sheet: Enviar treino para Aluno (FIX: selectionCard)
// ============================================================

private struct TeacherSendWorkoutToStudentSheet: View {

    let template: WorkoutTemplateFS
    let category: TreinoTipo

    @Environment(\.dismiss) private var dismiss

    @State private var students: [AppUser] = []
    @State private var weeks: [TrainingWeekFS] = []
    @State private var dayOptions: [Int] = Array(0...6)

    @State private var selectedStudent: AppUser? = nil
    @State private var selectedWeek: TrainingWeekFS? = nil
    @State private var selectedDayIndex: Int = 0

    @State private var isLoading: Bool = false
    @State private var isSending: Bool = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.headerBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {

                        header

                        // ✅ FIX: selectionCard quebrado em partes menores
                        selectionCard

                        sendButtonCard

                        if let err = errorMessage {
                            messageCard(text: err, isError: true)
                        }

                        if let ok = successMessage {
                            messageCard(text: ok, isError: false)
                        }

                        Color.clear.frame(height: 18)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Enviar treino")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fechar") { dismiss() }
                }
            }
            .task { await bootstrap() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(template.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))

            Text("Escolha o aluno, a semana e o dia onde este treino será aplicado.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // ============================================================
    // MARK: - ✅ Selection Card (FIX: quebra em sub-expressões)
    // ============================================================

    private var selectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isLoading {
                loadingInline
            } else {
                studentPickerSection
                Divider().background(Theme.Colors.divider)
                weekPickerSection
                Divider().background(Theme.Colors.divider)
                dayPickerSection
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var loadingInline: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text("Carregando...")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
        }
        .padding(.vertical, 10)
    }

    private var studentPickerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Aluno")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))

            studentMenu
        }
    }

    private var studentMenu: some View {
        let label = selectedStudent?.name ?? "Selecionar aluno"

        // ✅ reduz carga do compilador: trabalha com tuplas simples e id estável
        let items: [(id: String, name: String)] = students.compactMap { s in
            guard let id = s.id, !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            return (id: id, name: s.name)
        }

        return Menu {
            ForEach(items, id: \.id) { item in
                Button(item.name) {
                    if let s = students.first(where: { $0.id == item.id }) {
                        selectedStudent = s
                        selectedWeek = nil
                        weeks = []
                        Task { await loadWeeksForSelectedStudent() }
                    }
                }
            }
        } label: {
            HStack {
                Text(label)
                    .foregroundColor(.white.opacity(0.92))
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(.white.opacity(0.55))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.10))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var weekPickerSection: some View {
        let hasStudent = (selectedStudent != nil)

        return VStack(alignment: .leading, spacing: 6) {
            Text("Semana")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))

            weekMenu(hasStudent: hasStudent)
                .disabled(!hasStudent)
        }
    }

    private func weekMenu(hasStudent: Bool) -> some View {
        let labelText: String = {
            if !hasStudent { return "Selecione um aluno primeiro" }
            return selectedWeek?.weekTitle ?? "Selecionar semana"
        }()

        let textOpacity: Double = hasStudent ? 0.92 : 0.35
        let chevronOpacity: Double = hasStudent ? 0.55 : 0.25

        let items: [(id: String, title: String)] = weeks.compactMap { w in
            guard let id = w.id, !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            return (id: id, title: w.weekTitle)
        }

        return Menu {
            ForEach(items, id: \.id) { item in
                Button(item.title) {
                    if let w = weeks.first(where: { $0.id == item.id }) {
                        selectedWeek = w
                        selectedDayIndex = 0
                    }
                }
            }
        } label: {
            HStack {
                Text(labelText)
                    .foregroundColor(.white.opacity(textOpacity))
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(.white.opacity(chevronOpacity))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.10))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var dayPickerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Dia")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))

            Picker("Dia", selection: $selectedDayIndex) {
                ForEach(dayOptions, id: \.self) { i in
                    Text("Dia \(i + 1)").tag(i)
                }
            }
            .pickerStyle(.segmented)
            .disabled(selectedWeek == nil)
        }
    }

    // ============================================================
    // MARK: - Enviar
    // ============================================================

    private var sendButtonCard: some View {
        Button {
            Task { await sendTemplateToSelectedDay() }
        } label: {
            HStack {
                Spacer()
                if isSending {
                    ProgressView().tint(.white)
                } else {
                    Text("Enviar")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                }
                Spacer()
            }
            .padding(.vertical, 14)
            .background(Color.green.opacity(0.16))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isSending || selectedStudent == nil || selectedWeek?.id == nil)
    }

    private func messageCard(text: String, isError: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundColor(isError ? .yellow.opacity(0.85) : .green.opacity(0.85))

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.75))

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.35))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    // MARK: - Data

    private func bootstrap() async {
        errorMessage = nil
        successMessage = nil

        let teacherId = (Auth.auth().currentUser?.uid ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !teacherId.isEmpty else {
            errorMessage = "Não foi possível identificar o professor logado."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            students = try await FirestoreRepository.shared.getStudentsForTeacher(
                teacherId: teacherId,
                category: category.rawValue
            )
        } catch {
            errorMessage = error.localizedDescription
            students = []
        }
    }

    private func loadWeeksForSelectedStudent() async {
        errorMessage = nil
        successMessage = nil

        guard let student = selectedStudent, let sid = student.id, !sid.isEmpty else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            weeks = try await FirestoreRepository.shared.getWeeksForStudent(studentId: sid, onlyPublished: false)
        } catch {
            errorMessage = error.localizedDescription
            weeks = []
        }
    }

    private func sendTemplateToSelectedDay() async {
        errorMessage = nil
        successMessage = nil

        guard let weekId = selectedWeek?.id, !weekId.isEmpty else {
            errorMessage = "Selecione uma semana válida."
            return
        }

        let base = weekStartDate(selectedWeek) ?? Date()
        let date = Calendar.current.date(byAdding: .day, value: selectedDayIndex, to: base) ?? base
        let dayName = "Dia \(selectedDayIndex + 1)"

        isSending = true
        defer { isSending = false }

        do {
            let blocks = template.blocks ?? []
            _ = try await FirestoreRepository.shared.upsertDay(
                weekId: weekId,
                dayId: nil,
                dayIndex: selectedDayIndex,
                dayName: dayName,
                date: date,
                title: template.title,
                description: template.description,
                blocks: blocks
            )

            successMessage = "Treino enviado com sucesso!"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // ✅ Mantém compatível com seu modelo atual (sem assumir o tipo de startDate)
    private func weekStartDate(_ week: TrainingWeekFS?) -> Date? {
        guard let week else { return nil }

        let mirror = Mirror(reflecting: week as Any)
        for child in mirror.children {
            if child.label == "startDate" {
                if let ts = child.value as? Timestamp { return ts.dateValue() }
                if let d = child.value as? Date { return d }
            }
        }
        return nil
    }
}

