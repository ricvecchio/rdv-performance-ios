import SwiftUI
import FirebaseAuth
import UniformTypeIdentifiers
import FirebaseFirestore

struct TeacherImportWorkoutsView: View {
    
    @Binding var path: [AppRoute]
    let category: TreinoTipo
    
    private let contentMaxWidth: CGFloat = 380
    
    @State private var workouts: [TeacherImportedWorkout] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    @State private var isAddSheetPresented: Bool = false
    @State private var isTemplateSharePresented: Bool = false
    @State private var templateFileURL: URL? = nil
    @State private var isImportPickerPresented: Bool = false
    @State private var isImporting: Bool = false
    @State private var activeSheet: ActiveSheet? = nil
    
    // ✅ Envio para treinos (Crossfit / Academia / Em Casa)
    @State private var isSendToWorkoutsDialogPresented: Bool = false
    @State private var workoutPendingSend: TeacherImportedWorkout? = nil
    @State private var isSendingToWorkouts: Bool = false
    @State private var successMessage: String? = nil
    
    private enum ActiveSheet: Identifiable {
        case detail(TeacherImportedWorkout)
        
        var id: String {
            switch self {
            case .detail(let w):
                return "detail-\(w.id)"
            }
        }
    }
    
    private enum SendDestination: CaseIterable {
        case crossfit
        case academia
        case emCasa
        
        var title: String {
            switch self {
            case .crossfit: return "Treinos Crossfit"
            case .academia: return "Treinos Academia"
            case .emCasa:   return "Treinos em Casa"
            }
        }
        
        var targetCategory: TreinoTipo {
            switch self {
            case .crossfit: return .crossfit
            case .academia: return .academia
            case .emCasa:   return .emCasa
            }
        }
        
        var targetSectionKey: String {
            switch self {
            case .crossfit:
                return CrossfitLibrarySection.meusTreinos.firestoreKey
            case .academia, .emCasa:
                return "meusTreinos"
            }
        }
    }
    
    private let templateResourceName: String = "rdv_import_treinos_template_pt_crossfit"
    private let templateResourceExtension: String = "xlsx"
    private var xlsxUTType: UTType { UTType(filenameExtension: "xlsx") ?? .data }
    
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
                            header
                            actionsRow
                            contentCard
                            
                            if isImporting {
                                messageCard(text: "Importando planilha... aguarde.", isError: false)
                            }
                            
                            if isSendingToWorkouts {
                                messageCard(text: "Enviando treino... aguarde.", isError: false)
                            }
                            
                            if let ok = successMessage {
                                messageCard(text: ok, isError: false)
                            }
                            
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
                Text("Importar Treinos")
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
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await loadWorkouts() }
        .onAppear { Task { await loadWorkouts() } }
        .sheet(isPresented: $isAddSheetPresented) {
            TeacherAddWorkoutSheet { title in
                Task { await addWorkout(title: title) }
            }
        }
        .sheet(isPresented: $isTemplateSharePresented) {
            if let url = templateFileURL {
                ActivityView(activityItems: [url])
                    .ignoresSafeArea()
            } else {
                ZStack {
                    Color.black.opacity(0.95).ignoresSafeArea()
                    VStack(spacing: 12) {
                        Text("Falha ao localizar a planilha no Bundle")
                            .foregroundColor(.white.opacity(0.90))
                            .font(.system(size: 16, weight: .semibold))
                            .multilineTextAlignment(.center)
                        
                        Text(errorMessage ?? "Sem detalhes.")
                            .foregroundColor(.white.opacity(0.70))
                            .font(.system(size: 13))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 18)
                        
                        Button("Fechar") { isTemplateSharePresented = false }
                            .foregroundColor(.green)
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $isImportPickerPresented) {
            DocumentPicker(
                allowedContentTypes: [xlsxUTType],
                onPick: { pickedURL in
                    Task { await handlePickedExcel(url: pickedURL) }
                },
                onCancel: { }
            )
            .ignoresSafeArea()
        }
        .sheet(item: $activeSheet, onDismiss: {
            Task { await loadWorkouts() }
        }) { sheet in
            switch sheet {
            case .detail(let w):
                TeacherImportedWorkoutDetailsSheet(
                    workout: w,
                    onSendToStudent: {
                        sendImportedWorkoutToStudent(workout: w)
                    }
                )
            }
        }
        .confirmationDialog(
            "Enviar para Treinos",
            isPresented: $isSendToWorkoutsDialogPresented,
            titleVisibility: .visible
        ) {
            Button(SendDestination.crossfit.title) {
                Task { await confirmSend(destination: .crossfit) }
            }
            Button(SendDestination.academia.title) {
                Task { await confirmSend(destination: .academia) }
            }
            Button(SendDestination.emCasa.title) {
                Task { await confirmSend(destination: .emCasa) }
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            let name = workoutPendingSend?.title.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if name.isEmpty {
                Text("Selecione o destino do treino.")
            } else {
                Text("Selecione o destino para: \(name)")
            }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Importe treinos via planilha para cadastrar automaticamente.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var actionsRow: some View {
        HStack(spacing: 10) {
            Button {
                errorMessage = nil
                successMessage = nil
                isImportPickerPresented = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Importar Excel")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.green.opacity(0.16)))
            }
            .buttonStyle(.plain)
            .disabled(isImporting || isSendingToWorkouts)
            
            Spacer(minLength: 0)
            
            Button {
                errorMessage = nil
                successMessage = nil
                prepareTemplateShare()
            } label: {
                HStack {
                    Image(systemName: "arrow.down.doc")
                    Text("Baixar Planilha Excel")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.green.opacity(0.16)))
            }
            .buttonStyle(.plain)
            .disabled(isSendingToWorkouts)
        }
    }
    
    private var contentCard: some View {
        VStack(spacing: 0) {
            if isLoading {
                loadingView
            } else if workouts.isEmpty {
                emptyView
            } else {
                workoutsList
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
    
    private var workoutsList: some View {
        VStack(spacing: 0) {
            ForEach(workouts.indices, id: \.self) { idx in
                let w = workouts[idx]
                
                importedWorkoutRow(workout: w)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        openDetails(for: w)
                    }
                
                if idx < workouts.count - 1 {
                    innerDivider(leading: 14)
                }
            }
        }
    }
    
    private func importedWorkoutRow(workout w: TeacherImportedWorkout) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "dumbbell.fill")
                .foregroundColor(.green.opacity(0.85))
                .font(.system(size: 16))
                .frame(width: 26)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(w.title.isEmpty ? "Treino" : w.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(1)
                
                Text("Importado via Excel")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(1)
            }
            
            Spacer()
            
            Menu {
                Button {
                    openSendToWorkoutsPicker(workout: w)
                } label: {
                    Label("Enviar para Treinos", systemImage: "paperplane.fill")
                }
                
                Button(role: .destructive) {
                    Task { await deleteWorkout(workoutId: w.id) }
                } label: {
                    Label("Remover", systemImage: "trash.fill")
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
            Text("Nenhum treino cadastrado")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))
            
            Text("Toque em \"Importar Excel\" para cadastrar treinos via planilha.")
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
    
    private func openDetails(for workout: TeacherImportedWorkout) {
        activeSheet = .detail(workout)
    }
    
    private func openSendToWorkoutsPicker(workout: TeacherImportedWorkout) {
        errorMessage = nil
        successMessage = nil
        workoutPendingSend = workout
        isSendToWorkoutsDialogPresented = true
    }
    
    private func confirmSend(destination: SendDestination) async {
        errorMessage = nil
        successMessage = nil
        
        guard let workout = workoutPendingSend else {
            errorMessage = "Não foi possível enviar: treino inválido."
            return
        }
        
        await sendImportedWorkoutToWorkouts(workout: workout, destination: destination)
    }
    
    private func sendImportedWorkoutToWorkouts(workout: TeacherImportedWorkout, destination: SendDestination) async {
        guard let teacherId = TeacherImportedWorkoutsRepository.getTeacherId() else {
            errorMessage = "Não foi possível identificar o professor logado."
            return
        }
        
        let title = workout.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeTitle = title.isEmpty ? "Treino" : title
        
        let descOnly = workout.description.trimmingCharacters(in: .whitespacesAndNewlines)
        let blocks = buildBlocks(from: workout)
        
        let templateDescription: String = {
            if !descOnly.isEmpty { return descOnly }
            if !blocks.isEmpty { return "" }
            return "-"
        }()
        
        isSendingToWorkouts = true
        defer { isSendingToWorkouts = false }
        
        do {
            _ = try await FirestoreRepository.shared.createWorkoutTemplate(
                teacherId: teacherId,
                categoryRaw: destination.targetCategory.rawValue,
                sectionKey: destination.targetSectionKey,
                title: safeTitle,
                description: templateDescription,
                blocks: blocks
            )
            
            successMessage = "Treino enviado com sucesso para \(destination.title)!"
            NotificationCenter.default.post(name: .workoutTemplateUpdated, object: nil)
            
        } catch {
            errorMessage = "Falha ao enviar o treino: \(error.localizedDescription)"
        }
    }
    
    private func buildBlocks(from workout: TeacherImportedWorkout) -> [BlockFS] {
        func cleaned(_ s: String) -> String {
            s.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        var list: [BlockFS] = []
        
        let aquecimento = cleaned(workout.aquecimento)
        if !aquecimento.isEmpty {
            list.append(BlockFS(id: "aquecimento", name: "Aquecimento", details: aquecimento))
        }
        
        let tecnica = cleaned(workout.tecnica)
        if !tecnica.isEmpty {
            list.append(BlockFS(id: "tecnica", name: "Técnica", details: tecnica))
        }
        
        let wod = cleaned(workout.wod)
        if !wod.isEmpty {
            list.append(BlockFS(id: "wod", name: "WOD", details: wod))
        }
        
        let cargas = cleaned(workout.cargasMovimentos)
        if !cargas.isEmpty {
            list.append(BlockFS(id: "cargasMovimentos", name: "Cargas / Movimentos", details: cargas))
        }
        
        return list
    }
    
    private func prepareTemplateShare() {
        errorMessage = nil
        
        let expectedFileName = "\(templateResourceName).\(templateResourceExtension)"
        
        guard let bundleURL = Bundle.main.resourceURL else {
            templateFileURL = nil
            errorMessage = "DEBUG: Bundle.main.resourceURL é nil."
            isTemplateSharePresented = true
            return
        }
        
        var foundURL: URL? = nil
        if let en = FileManager.default.enumerator(at: bundleURL, includingPropertiesForKeys: nil) {
            for case let u as URL in en {
                if u.lastPathComponent == expectedFileName {
                    foundURL = u
                    break
                }
            }
        }
        
        if let foundURL {
            do {
                let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(expectedFileName)
                if FileManager.default.fileExists(atPath: tmp.path) {
                    try FileManager.default.removeItem(at: tmp)
                }
                try FileManager.default.copyItem(at: foundURL, to: tmp)
                
                templateFileURL = tmp
                errorMessage = nil
                isTemplateSharePresented = true
                return
            } catch {
                templateFileURL = nil
                errorMessage = "DEBUG: encontrei o arquivo, mas falhei ao copiar para /tmp: \(error.localizedDescription)"
                isTemplateSharePresented = true
                return
            }
        }
        
        templateFileURL = nil
        errorMessage = "Arquivo da planilha não encontrado no bundle."
        isTemplateSharePresented = true
    }
    
    private func handlePickedExcel(url: URL) async {
        errorMessage = nil
        
        let ext = url.pathExtension.lowercased()
        guard ext == "xlsx" else {
            errorMessage = """
            O arquivo selecionado não é um .xlsx.

            Se você editou no Numbers, ele salva como .numbers.
            Faça: ••• → Exportar → Excel (.xlsx) e selecione o arquivo exportado.
            """
            return
        }
        
        isImporting = true
        defer { isImporting = false }
        
        let didStart = url.startAccessingSecurityScopedResource()
        defer {
            if didStart { url.stopAccessingSecurityScopedResource() }
        }
        
        do {
            guard let teacherId = TeacherImportedWorkoutsRepository.getTeacherId() else {
                errorMessage = "Não foi possível identificar o professor logado."
                return
            }
            
            let parsed = try ExcelWorkoutImporter.parseWorkouts(fromXLSX: url)
            
            guard !parsed.isEmpty else {
                errorMessage = "Não foi encontrado nenhum treino válido na planilha."
                return
            }
            
            try await TeacherImportedWorkoutsRepository.saveImportedWorkoutsBatch(teacherId: teacherId, items: parsed)
            await loadWorkouts()
        } catch {
            let ns = error as NSError
            if ns.domain == FirestoreErrorDomain,
               ns.code == FirestoreErrorCode.permissionDenied.rawValue {
                errorMessage = "Sem permissão para importar treinos. Verifique se você está logado e se seu usuário é do tipo PROFESSOR (TRAINER)."
                return
            }
            
            let msg = error.localizedDescription
            if msg.contains("Missing or insufficient permissions") {
                errorMessage = "Sem permissão para importar treinos. Verifique se você está logado e se seu usuário é do tipo PROFESSOR (TRAINER)."
                return
            }
            
            if msg.contains("CoreXLSX") || msg.contains("CoreXLSXError") {
                errorMessage = """
                Não foi possível ler o arquivo .xlsx.

                Dica: se você abriu no Numbers, use:
                ••• → Exportar → Excel (.xlsx)

                Detalhe técnico:
                \(msg)
                """
            } else {
                errorMessage = msg
            }
        }
    }
    
    private func sendImportedWorkoutToStudent(workout: TeacherImportedWorkout) {
        errorMessage = "Enviar para aluno: selecione o fluxo de alunos que você já usa (me diga a rota que abre a lista)."
    }
    
    private func loadWorkouts() async {
        errorMessage = nil
        
        guard let teacherId = TeacherImportedWorkoutsRepository.getTeacherId() else {
            workouts = []
            errorMessage = "Não foi possível identificar o professor logado."
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            workouts = try await TeacherImportedWorkoutsRepository.loadWorkouts(teacherId: teacherId)
        } catch {
            workouts = []
            let ns = error as NSError
            if ns.domain == FirestoreErrorDomain,
               ns.code == FirestoreErrorCode.permissionDenied.rawValue {
                errorMessage = "Sem permissão para acessar/importar treinos. Verifique se você está logado e se seu usuário é do tipo PROFESSOR (TRAINER)."
            } else {
                let msg = error.localizedDescription
                if msg.contains("Missing or insufficient permissions") {
                    errorMessage = "Sem permissão para acessar/importar treinos. Verifique se você está logado e se seu usuário é do tipo PROFESSOR (TRAINER)."
                } else {
                    errorMessage = msg
                }
            }
        }
    }
    
    private func addWorkout(title: String) async {
        errorMessage = nil
        
        guard let teacherId = TeacherImportedWorkoutsRepository.getTeacherId() else {
            errorMessage = "Não foi possível identificar o professor logado."
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await TeacherImportedWorkoutsRepository.addWorkout(teacherId: teacherId, title: title)
            await loadWorkouts()
        } catch {
            let ns = error as NSError
            if ns.domain == FirestoreErrorDomain,
               ns.code == FirestoreErrorCode.permissionDenied.rawValue {
                errorMessage = "Sem permissão para salvar treinos importados. Verifique se você está logado e se seu usuário é do tipo PROFESSOR (TRAINER)."
            } else {
                let msg = error.localizedDescription
                if msg.contains("Missing or insufficient permissions") {
                    errorMessage = "Sem permissão para salvar treinos importados. Verifique se você está logado e se seu usuário é do tipo PROFESSOR (TRAINER)."
                } else {
                    errorMessage = msg
                }
            }
        }
    }
    
    private func deleteWorkout(workoutId: String) async {
        errorMessage = nil
        
        guard let teacherId = TeacherImportedWorkoutsRepository.getTeacherId() else {
            errorMessage = "Não foi possível identificar o professor logado."
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await TeacherImportedWorkoutsRepository.deleteWorkout(teacherId: teacherId, workoutId: workoutId)
            await loadWorkouts()
        } catch {
            let ns = error as NSError
            if ns.domain == FirestoreErrorDomain,
               ns.code == FirestoreErrorCode.permissionDenied.rawValue {
                errorMessage = "Sem permissão para remover treinos importados. Verifique se você está logado e se seu usuário é do tipo PROFESSOR (TRAINER)."
            } else {
                let msg = error.localizedDescription
                if msg.contains("Missing or insufficient permissions") {
                    errorMessage = "Sem permissão para remover treinos importados. Verifique se você está logado e se seu usuário é do tipo PROFESSOR (TRAINER)."
                } else {
                    errorMessage = msg
                }
            }
        }
    }
    
    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

