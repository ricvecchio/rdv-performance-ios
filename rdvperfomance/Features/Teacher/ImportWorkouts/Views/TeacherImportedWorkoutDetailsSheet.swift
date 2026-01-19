import SwiftUI
import FirebaseAuth

struct TeacherImportedWorkoutDetailsSheet: View {
    
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
            .navigationTitle("Treino")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fechar") { dismiss() }
                        .disabled(isSaving)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if isEditing {
                        HStack(spacing: 12) {
                            Button("Cancelar") {
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
                                    Text("Salvar")
                                }
                            }
                            .disabled(isSaving)
                        }
                    } else {
                        Button("Editar") {
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
            Text(workout.title.isEmpty ? "Treino" : workout.title)
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
            blockCard(title: "Descrição", value: workout.description)
            blockCard(title: "Aquecimento", value: workout.aquecimento)
            blockCard(title: "Técnica", value: workout.tecnica)
            blockCard(title: "WOD", value: workout.wod)
            blockCard(title: "Cargas / Movimentos", value: workout.cargasMovimentos)
        }
    }
    
    private var editableBlocksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            blockEditor(title: "Descrição", text: $draftDescription)
            
            Divider().background(Theme.Colors.divider)
            
            blockEditor(title: "Aquecimento", text: $draftAquecimento)
            
            Divider().background(Theme.Colors.divider)
            
            blockEditor(title: "Técnica", text: $draftTecnica)
            
            Divider().background(Theme.Colors.divider)
            
            blockEditor(title: "WOD", text: $draftWod)
            
            Divider().background(Theme.Colors.divider)
            
            blockEditor(title: "Cargas / Movimentos", text: $draftCargasMovimentos)
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
            errorMessage = "Não foi possível identificar o professor logado."
            return
        }
        
        let workoutId = workout.id.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !workoutId.isEmpty else {
            errorMessage = "Não foi possível salvar: id do treino inválido."
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
            
            successMessage = "Alterações salvas com sucesso!"
            isEditing = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
