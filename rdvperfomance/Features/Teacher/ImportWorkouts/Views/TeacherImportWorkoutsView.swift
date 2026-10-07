import SwiftUI
import FirebaseAuth
import UniformTypeIdentifiers
import FirebaseFirestore

struct TeacherImportWorkoutsView: View {
    
    @Binding var path: [AppRoute]
    let category: TreinoTipo
    @Environment(\.locale) private var locale
    
    private let contentMaxWidth: CGFloat = 380
    
    @State private var workouts: [TeacherImportedWorkout] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    @State private var isAddSheetPresented: Bool = false
    @State private var templateShareItem: TemplateShareItem? = nil
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

    private struct TemplateShareItem: Identifiable {
        let id = UUID()
        let url: URL
    }
    
    private enum SendDestination: CaseIterable {
        case crossfit
        case academia
        case emCasa
        
        func title(locale: Locale) -> String {
            switch self {
            case .crossfit: return AppLocalization.string("ui.crossfit_workouts", locale: locale)
            case .academia: return AppLocalization.string("ui.gym_workouts", locale: locale)
            case .emCasa:   return AppLocalization.string("ui.home_workouts", locale: locale)
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
                                messageCard(
                                    text: AppLocalization.string("ui.importing_spreadsheet_please_wait", locale: locale),
                                    isError: false
                                )
                            }
                            
                            if isSendingToWorkouts {
                                messageCard(
                                    text: AppLocalization.string("ui.sending_workout_please_wait", locale: locale),
                                    isError: false
                                )
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { pop() } label: {
                    ZStack {
                        Color.clear
                            .frame(width: 44, height: 44)

                        Image(systemName: "chevron.left")
                            .foregroundColor(.green)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            
            ToolbarItem(placement: .principal) {
                Text("ui.import_workouts")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await loadWorkouts() }
        .sheet(isPresented: $isAddSheetPresented) {
            TeacherAddWorkoutSheet { title in
                Task { await addWorkout(title: title) }
            }
        }
        .sheet(item: $templateShareItem) { item in
            ActivityView(activityItems: [item.url])
                .ignoresSafeArea()
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
        .sheet(item: $activeSheet) { sheet in
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
            "ui.send_to_workouts",
            isPresented: $isSendToWorkoutsDialogPresented,
            titleVisibility: .visible
        ) {
            Button(SendDestination.crossfit.title(locale: locale)) {
                Task { await confirmSend(destination: .crossfit) }
            }
            Button(SendDestination.academia.title(locale: locale)) {
                Task { await confirmSend(destination: .academia) }
            }
            Button(SendDestination.emCasa.title(locale: locale)) {
                Task { await confirmSend(destination: .emCasa) }
            }
            Button("common.cancel", role: .cancel) { }
        } message: {
            let name = workoutPendingSend?.title.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if name.isEmpty {
                Text("ui.select_the_workout_destination")
            } else {
                Text(
                    String(
                        format: AppLocalization.string("ui.select_destination_for_value", locale: locale),
                        locale: locale,
                        arguments: [name]
                    )
                )
            }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ui.import_workouts_through_a_spreadsheet_to_add_them_automatically")
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
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                    Text("ui.import_excel")
                }
                .padding(.horizontal, 14)
                .compactPrimaryGreenActionButton()
            }
            .buttonStyle(.plain)
            .disabled(isImporting || isSendingToWorkouts)
            
            Spacer(minLength: 0)
            
            Button {
                errorMessage = nil
                successMessage = nil
                prepareTemplateShare()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.down.doc")
                    Text("ui.download_excel_spreadsheet")
                }
                .padding(.horizontal, 14)
                .compactPrimaryGreenActionButton()
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
        .background(Color.black.opacity(0.68))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.Colors.primaryGreen.opacity(0.28), lineWidth: 1)
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
                Text(w.title.isEmpty ? AppLocalization.string("ui.workout", locale: locale) : w.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(1)
                
                Text("ui.imported_via_excel")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(1)
            }
            
            Spacer()
            
            Menu {
                Button {
                    openSendToWorkoutsPicker(workout: w)
                } label: {
                    Label(LocalizedStringKey("ui.send_to_workouts"), systemImage: "paperplane.fill")
                }
                
                Button(role: .destructive) {
                    Task { await deleteWorkout(workoutId: w.id) }
                } label: {
                    Label(LocalizedStringKey("ui.remove"), systemImage: "trash.fill")
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
            Text("ui.loading")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }
    
    private var emptyView: some View {
        VStack(spacing: 10) {
            Text("ui.no_workout_registered")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))
            
            Text("ui.tap_import_excel_to_add_workouts")
                .font(.system(size: 14))
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
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.75))
            
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.68))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isError ? Color.white.opacity(0.10) : Theme.Colors.primaryGreen.opacity(0.28), lineWidth: 1)
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
            errorMessage = AppLocalization.string("ui.unable_to_send_invalid_workout", locale: locale)
            return
        }
        
        await sendImportedWorkoutToWorkouts(workout: workout, destination: destination)
    }
    
    private func sendImportedWorkoutToWorkouts(workout: TeacherImportedWorkout, destination: SendDestination) async {
        guard let teacherId = TeacherImportedWorkoutsRepository.getTeacherId() else {
            errorMessage = AppLocalization.string("ui.unable_to_identify_the_signed_in_trainer", locale: locale)
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
            
            let format = AppLocalization.string("ui.workout_sent_successfully_to_value", locale: locale)
            successMessage = String(
                format: format,
                locale: locale,
                arguments: [destination.title(locale: locale)]
            )
            NotificationCenter.default.post(name: .workoutTemplateUpdated, object: nil)
            
        } catch {
            let format = AppLocalization.string("ui.failed_to_send_the_workout_value", locale: locale)
            errorMessage = String(
                format: format,
                locale: locale,
                arguments: [error.localizedDescription]
            )
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
        templateShareItem = nil

        guard let sourceURL = resolveTemplateURL() else {
            errorMessage = AppLocalization.string("ui.unable_to_find_the_spreadsheet_template_in_the_app", locale: locale)
            return
        }

        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            errorMessage = AppLocalization.string("ui.unable_to_find_the_spreadsheet_template_in_the_app", locale: locale)
            return
        }

        do {
            let destinationURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(sourceURL.lastPathComponent)
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

            guard FileManager.default.fileExists(atPath: destinationURL.path) else {
                errorMessage = AppLocalization.string("ui.unable_to_prepare_the_spreadsheet_for_download_the_temporary_copy_was_not_found",
                    locale: locale
                )
                return
            }

            templateShareItem = TemplateShareItem(url: destinationURL)
        } catch {
            let format = AppLocalization.string("ui.unable_to_prepare_the_spreadsheet_for_download_value",
                locale: locale
            )
            errorMessage = String(
                format: format,
                locale: locale,
                arguments: [error.localizedDescription]
            )
        }
    }

    private func resolveTemplateURL() -> URL? {
        if let url = Bundle.main.url(
            forResource: templateResourceName,
            withExtension: templateResourceExtension
        ) {
            return url
        }

        return Bundle.main.url(
            forResource: templateResourceName,
            withExtension: templateResourceExtension,
            subdirectory: "Templates"
        )
    }
    
    private func handlePickedExcel(url: URL) async {
        errorMessage = nil
        
        let ext = url.pathExtension.lowercased()
        guard ext == "xlsx" else {
            errorMessage = AppLocalization.string("ui.the_selected_file_is_not_an_xlsx_if_you_edited_it_in_numbers_it_saves_as_numbers_do_this_export_excel_xlsx_then_select_the_exported_file",
                locale: locale
            )
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
                errorMessage = AppLocalization.string("ui.unable_to_identify_the_signed_in_trainer", locale: locale)
                return
            }
            
            let parsed = try ExcelWorkoutImporter.parseWorkouts(fromXLSX: url)
            
            guard !parsed.isEmpty else {
                errorMessage = AppLocalization.string("ui.no_valid_workout_was_found_in_the_spreadsheet", locale: locale)
                return
            }
            
            try await TeacherImportedWorkoutsRepository.saveImportedWorkoutsBatch(teacherId: teacherId, items: parsed)
            await loadWorkouts()
        } catch {
            let ns = error as NSError
            if ns.domain == FirestoreErrorDomain,
               ns.code == FirestoreErrorCode.permissionDenied.rawValue {
                errorMessage = AppLocalization.string("ui.you_do_not_have_permission_to_import_workouts_confirm_that_you_are_signed_in_and_that_your_user_type_is_trainer",
                    locale: locale
                )
                return
            }
            
            let msg = error.localizedDescription
            if msg.contains("Missing or insufficient permissions") {
                errorMessage = AppLocalization.string("ui.you_do_not_have_permission_to_import_workouts_confirm_that_you_are_signed_in_and_that_your_user_type_is_trainer",
                    locale: locale
                )
                return
            }
            
            if msg.contains("CoreXLSX") || msg.contains("CoreXLSXError") {
                let format = AppLocalization.string("ui.unable_to_read_the_xlsx_file_tip_if_you_opened_it_in_numbers_use_export_excel_xlsx_technical_detail_value",
                    locale: locale
                )
                errorMessage = String(
                    format: format,
                    locale: locale,
                    arguments: [msg]
                )
            } else {
                errorMessage = msg
            }
        }
    }
    
    private func sendImportedWorkoutToStudent(workout: TeacherImportedWorkout) {
        errorMessage = AppLocalization.string("ui.send_to_student_select_the_student_flow_you_already_use_tell_me_which_route_opens_the_list",
            locale: locale
        )
    }
    
    private func loadWorkouts() async {
        errorMessage = nil
        
        guard let teacherId = TeacherImportedWorkoutsRepository.getTeacherId() else {
            workouts = []
            errorMessage = AppLocalization.string("ui.unable_to_identify_the_signed_in_trainer", locale: locale)
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
                errorMessage = AppLocalization.string("ui.you_do_not_have_permission_to_access_import_workouts_confirm_that_you_are_signed_in_and_that_your_user_type_is_trainer",
                    locale: locale
                )
            } else {
                let msg = error.localizedDescription
                if msg.contains("Missing or insufficient permissions") {
                    errorMessage = AppLocalization.string("ui.you_do_not_have_permission_to_access_import_workouts_confirm_that_you_are_signed_in_and_that_your_user_type_is_trainer",
                        locale: locale
                    )
                } else {
                    errorMessage = msg
                }
            }
        }
    }
    
    private func addWorkout(title: String) async {
        errorMessage = nil
        
        guard let teacherId = TeacherImportedWorkoutsRepository.getTeacherId() else {
            errorMessage = AppLocalization.string("ui.unable_to_identify_the_signed_in_trainer", locale: locale)
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await TeacherImportedWorkoutsRepository.addWorkout(
                teacherId: teacherId,
                title: title,
                locale: locale
            )
            await loadWorkouts()
        } catch {
            let ns = error as NSError
            if ns.domain == FirestoreErrorDomain,
               ns.code == FirestoreErrorCode.permissionDenied.rawValue {
                errorMessage = AppLocalization.string("ui.you_do_not_have_permission_to_save_imported_workouts_confirm_that_you_are_signed_in_and_that_your_user_type_is_trainer",
                    locale: locale
                )
            } else {
                let msg = error.localizedDescription
                if msg.contains("Missing or insufficient permissions") {
                    errorMessage = AppLocalization.string("ui.you_do_not_have_permission_to_save_imported_workouts_confirm_that_you_are_signed_in_and_that_your_user_type_is_trainer",
                        locale: locale
                    )
                } else {
                    errorMessage = msg
                }
            }
        }
    }
    
    private func deleteWorkout(workoutId: String) async {
        errorMessage = nil
        
        guard let teacherId = TeacherImportedWorkoutsRepository.getTeacherId() else {
            errorMessage = AppLocalization.string("ui.unable_to_identify_the_signed_in_trainer", locale: locale)
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
                errorMessage = AppLocalization.string("ui.you_do_not_have_permission_to_remove_imported_workouts_confirm_that_you_are_signed_in_and_that_your_user_type_is_trainer",
                    locale: locale
                )
            } else {
                let msg = error.localizedDescription
                if msg.contains("Missing or insufficient permissions") {
                    errorMessage = AppLocalization.string("ui.you_do_not_have_permission_to_remove_imported_workouts_confirm_that_you_are_signed_in_and_that_your_user_type_is_trainer",
                        locale: locale
                    )
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
