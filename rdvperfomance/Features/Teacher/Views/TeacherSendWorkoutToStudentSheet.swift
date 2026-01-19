import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct TeacherSendWorkoutToStudentSheet: View {

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

                        selectionCard

                        sendButtonCard

                        if let err = errorMessage {
                            TeacherWorkoutTemplatesMessageCard(text: err, isError: true)
                        }

                        if let ok = successMessage {
                            TeacherWorkoutTemplatesMessageCard(text: ok, isError: false)
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
                        errorMessage = nil
                        successMessage = nil
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

            if !hasStudent {
                weekMenuDisabledPlaceholder(text: "Selecione um aluno primeiro")
                    .disabled(true)
            } else if isLoading {
                weekMenuDisabledPlaceholder(text: "Carregando semanas...")
                    .disabled(true)
            } else if weeks.isEmpty {
                weekMenuEmptyButton
            } else {
                weekMenuWithItems
            }
        }
    }

    private func weekMenuDisabledPlaceholder(text: String) -> some View {
        HStack {
            Text(text)
                .foregroundColor(.white.opacity(0.35))
            Spacer()
            Image(systemName: "chevron.down")
                .foregroundColor(.white.opacity(0.25))
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

    private var weekMenuEmptyButton: some View {
        Button {
            errorMessage = "O aluno deve ter uma semana cadastrada."
            successMessage = nil
        } label: {
            HStack {
                Text("Selecionar semana")
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

    private var weekMenuWithItems: some View {
        let labelText = selectedWeek?.weekTitle ?? "Selecionar semana"

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
                        errorMessage = nil
                        successMessage = nil
                    }
                }
            }
        } label: {
            HStack {
                Text(labelText)
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
