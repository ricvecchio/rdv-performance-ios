import SwiftUI
import FirebaseAuth

struct TeacherImportedWorkoutDetailsSheet: View {
    @Environment(\.locale) private var locale
    
    let workout: TeacherImportedWorkout
    let onSendToStudent: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    private let contentMaxWidth: CGFloat = 380
    
    @State private var isEditing: Bool = false
    @State private var draftDescription: String = ""
    @State private var draftAquecimento: String = ""
    @State private var draftTecnica: String = ""
    @State private var draftWod: String = ""
    @State private var draftCargasMovimentos: String = ""
    
    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil
    
    var body: some View {
        NavigationStack {
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
                                
                                if isEditing {
                                    editableBlocksCard
                                } else {
                                    readOnlyBlocks
                                }
                                
                                if let err = errorMessage {
                                    messageCard(text: err, isError: true)
                                }
                                
                                if let ok = successMessage {
                                    messageCard(text: ok, isError: false)
                                }
                                
                                Color.clear.frame(height: 18)
                            }
                            .frame(maxWidth: contentMaxWidth)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            
                            Spacer(minLength: 0)
                        }
                    }
                }
                .ignoresSafeArea(.container, edges: [.bottom])
            }
            .navigationTitle("ui.workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.close") { dismiss() }
                        .disabled(isSaving)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if isEditing {
                        HStack(spacing: 12) {
                            Button("common.cancel") {
                                errorMessage = nil
                                successMessage = nil
                                isEditing = false
                                resetDraftFromWorkout()
                            }
                            .disabled(isSaving)
                            
                            Button {
                                Task { await saveEdits() }
                            } label: {
                                if isSaving {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("common.save")
                                }
                            }
                            .disabled(isSaving)
                        }
                    } else {
                        Button("ui.edit") {
                            errorMessage = nil
                            successMessage = nil
                            isEditing = true
                            resetDraftFromWorkout()
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    EmptyView()
                }
            }
            .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .background(NavigationBarNoHairline())
            .onAppear {
                resetDraftFromWorkout()
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.20), lineWidth: 1.25)
                    .allowsHitTesting(false)
            )
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(workout.title.isEmpty ? AppLocalization.string("ui.workout", locale: locale) : workout.title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))
                .lineLimit(2)
            
            let desc = workout.description.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if !desc.isEmpty {
                Text(desc)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.70))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var readOnlyBlocks: some View {
        VStack(spacing: 12) {
            blockCard(title: AppLocalization.string("ui.description", locale: locale), value: workout.description)
            blockCard(title: DefaultWorkoutBlock.warmup.localizedName(locale: locale), value: workout.aquecimento)
            blockCard(title: DefaultWorkoutBlock.technique.localizedName(locale: locale), value: workout.tecnica)
            blockCard(title: DefaultWorkoutBlock.wod.localizedName(locale: locale), value: workout.wod)
            blockCard(title: DefaultWorkoutBlock.loadsAndMovements.localizedName(locale: locale), value: workout.cargasMovimentos)
        }
    }
    
    private var editableBlocksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            blockEditor(title: AppLocalization.string("ui.description", locale: locale), text: $draftDescription)
            
            Divider().background(Theme.Colors.divider)
            
            blockEditor(title: DefaultWorkoutBlock.warmup.localizedName(locale: locale), text: $draftAquecimento)
            
            Divider().background(Theme.Colors.divider)
            
            blockEditor(title: DefaultWorkoutBlock.technique.localizedName(locale: locale), text: $draftTecnica)
            
            Divider().background(Theme.Colors.divider)
            
            blockEditor(title: DefaultWorkoutBlock.wod.localizedName(locale: locale), text: $draftWod)
            
            Divider().background(Theme.Colors.divider)
            
            blockEditor(title: DefaultWorkoutBlock.loadsAndMovements.localizedName(locale: locale), text: $draftCargasMovimentos)
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
    
    private func blockEditor(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))
            
            TextEditor(text: text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.92))
                .frame(minHeight: 110)
                .scrollContentBackground(.hidden)
                .background(Color.white.opacity(0.06))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func blockCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))
            
            Text(value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty ? "-" : value)
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
    
    private func resetDraftFromWorkout() {
        draftDescription = workout.description
        draftAquecimento = workout.aquecimento
        draftTecnica = workout.tecnica
        draftWod = workout.wod
        draftCargasMovimentos = workout.cargasMovimentos
    }
    
    private func saveEdits() async {
        errorMessage = nil
        successMessage = nil
        
        guard let teacherId = TeacherImportedWorkoutsRepository.getTeacherId() else {
            errorMessage = AppLocalization.string("ui.unable_to_identify_the_signed_in_trainer", locale: locale)
            return
        }
        
        let workoutId = workout.id.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !workoutId.isEmpty else {
            errorMessage = AppLocalization.string("ui.unable_to_save_invalid_workout_id", locale: locale)
            return
        }
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            try await TeacherImportedWorkoutsRepository.updateWorkout(
                teacherId: teacherId,
                workoutId: workoutId,
                updates: [
                    "description": draftDescription,
                    "aquecimento": draftAquecimento,
                    "tecnica": draftTecnica,
                    "wod": draftWod,
                    "cargasMovimentos": draftCargasMovimentos
                ]
            )
            
            successMessage = AppLocalization.string("ui.changes_saved_successfully", locale: locale)
            isEditing = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
