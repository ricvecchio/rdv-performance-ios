import SwiftUI

struct WorkoutTemplateAttachmentButton: View {
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "paperclip")
                Text("Anexar de Meus Treinos")
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white.opacity(0.92))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.green.opacity(0.16)))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

struct WorkoutTemplateAttachmentSheet: View {
    let templates: [WorkoutTemplateFS]
    let isLoading: Bool
    let onSelect: (WorkoutTemplateFS) -> Void
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.headerBackground.ignoresSafeArea()
                if isLoading {
                    ProgressView().tint(.white)
                } else if templates.isEmpty {
                    Text("Nenhum treino encontrado")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                } else {
                    List(templates) { template in
                        Button {
                            onSelect(template)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(template.title)
                                    .font(.system(size: 16, weight: .semibold))
                                if !template.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Text(template.description)
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Meus Treinos")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fechar", action: onClose)
                }
            }
        }
    }
}
