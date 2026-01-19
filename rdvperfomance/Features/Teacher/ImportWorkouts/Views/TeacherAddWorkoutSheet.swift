import SwiftUI

struct TeacherAddWorkoutSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var sheetMessage: String? = nil
    @State private var sheetMessageIsError: Bool = false
    
    let onSave: (_ title: String) -> Void
    
    private let contentMaxWidth: CGFloat = 380
    
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
                                Text("Digite um título para o treino.")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.65))
                                
                                formCard
                                
                                HStack(spacing: 10) {
                                    Button {
                                        let t = title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                                        if t.isEmpty {
                                            sheetMessage = "Informe um título para o treino."
                                            sheetMessageIsError = true
                                            return
                                        }
                                        
                                        onSave(t)
                                        dismiss()
                                    } label: {
                                        HStack {
                                            Image(systemName: "checkmark")
                                            Text("Salvar")
                                        }
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.92))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(Capsule().fill(Color.green.opacity(0.16)))
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Spacer(minLength: 0)
                                }
                                
                                if let msg = sheetMessage {
                                    sheetMessageCard(text: msg, isError: sheetMessageIsError)
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
            .navigationTitle("Adicionar Treino")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fechar") { dismiss() }
                }
            }
            .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    private var formCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Título do treino")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.55))
                
                ZStack(alignment: .leading) {
                    if title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
                        Text("Ex: Treino A - Peito e tríceps")
                            .foregroundColor(.white.opacity(0.45))
                            .padding(.horizontal, 12)
                    }
                    
                    TextField("", text: $title)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(false)
                        .foregroundColor(.white.opacity(0.92))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                }
                .background(Color.white.opacity(0.10))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
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
    
    private func sheetMessageCard(text: String, isError: Bool) -> some View {
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
}
