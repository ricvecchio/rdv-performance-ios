import SwiftUI

struct TeacherWorkoutTemplatesAddButton: View {

    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus")
                Text(title)
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white.opacity(0.92))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Capsule().fill(Color.green.opacity(0.16)))
        }
        .buttonStyle(.plain)
    }
}

struct TeacherWorkoutTemplatesContentCard: View {

    let isLoading: Bool
    let templates: [WorkoutTemplateFS]
    let isCrossfitCategory: Bool

    let onTapTemplate: (WorkoutTemplateFS) -> Void
    let onSendTemplate: (WorkoutTemplateFS) -> Void
    let onDeleteTemplate: (WorkoutTemplateFS) -> Void

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                TeacherWorkoutTemplatesLoadingView()
            } else if templates.isEmpty {
                TeacherWorkoutTemplatesEmptyView(isCrossfitCategory: isCrossfitCategory)
            } else {
                TeacherWorkoutTemplatesList(
                    templates: templates,
                    onTapTemplate: onTapTemplate,
                    onSendTemplate: onSendTemplate,
                    onDeleteTemplate: onDeleteTemplate
                )
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
}

struct TeacherWorkoutTemplatesList: View {

    let templates: [WorkoutTemplateFS]
    let onTapTemplate: (WorkoutTemplateFS) -> Void
    let onSendTemplate: (WorkoutTemplateFS) -> Void
    let onDeleteTemplate: (WorkoutTemplateFS) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(templates.indices, id: \.self) { idx in
                let t = templates[idx]

                Button {
                    onTapTemplate(t)
                } label: {
                    TeacherWorkoutTemplateRow(
                        template: t,
                        onSend: { onSendTemplate(t) },
                        onDelete: { onDeleteTemplate(t) }
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if idx < templates.count - 1 {
                    TeacherWorkoutTemplatesInnerDivider(leading: 14)
                }
            }
        }
    }
}

struct TeacherWorkoutTemplateRow: View {

    let template: WorkoutTemplateFS
    let onSend: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {

            Image(systemName: "flame.fill")
                .foregroundColor(.green.opacity(0.85))
                .font(.system(size: 16))
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 4) {
                Text(template.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))

                let sub = template.description.trimmingCharacters(in: .whitespacesAndNewlines)
                if !sub.isEmpty {
                    Text(sub)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.55))
                        .lineLimit(2)
                }
            }

            Spacer()

            Menu {
                Button {
                    onSend()
                } label: {
                    Label("Enviar para aluno", systemImage: "paperplane.fill")
                }

                Button(role: .destructive) {
                    onDelete()
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
        .background(Color.white.opacity(0.001)) // ✅ Garante área de toque completa
    }
}

struct TeacherWorkoutTemplatesLoadingView: View {
    var body: some View {
        VStack(spacing: 10) {
            ProgressView()
            Text("Carregando...")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }
}

struct TeacherWorkoutTemplatesEmptyView: View {

    let isCrossfitCategory: Bool

    var body: some View {
        VStack(spacing: 10) {
            Text(isCrossfitCategory ? "Nenhum WOD cadastrado" : "Nenhum treino cadastrado")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))

            Text(isCrossfitCategory ? "Toque em \"Adicionar WOD\" para começar." : "Cadastre templates para aparecerem aqui.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 10)
    }
}

struct TeacherWorkoutTemplatesMessageCard: View {

    let text: String
    let isError: Bool

    var body: some View {
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

struct TeacherWorkoutTemplatesInnerDivider: View {

    let leading: CGFloat

    var body: some View {
        Divider()
            .background(Theme.Colors.divider)
            .padding(.leading, leading)
    }
}
