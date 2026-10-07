import SwiftUI

struct TeacherWorkoutTemplatesAddButton: View {

    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "plus")
                Text(title)
            }
            .padding(.horizontal, 14)
            .compactPrimaryGreenActionButton()
        }
        .buttonStyle(.plain)
    }
}

struct TeacherWorkoutTemplatesContentCard: View {

    let isLoading: Bool
    let hasLoadedInitialData: Bool
    let templates: [WorkoutTemplateFS]
    let isCrossfitCategory: Bool
    let showsTemplateActions: Bool

    let onTapTemplate: (WorkoutTemplateFS) -> Void
    let onSendTemplate: (WorkoutTemplateFS) -> Void
    let onDeleteTemplate: (WorkoutTemplateFS) -> Void

    var body: some View {
        VStack(spacing: 0) {
            if isLoading || !hasLoadedInitialData {
                TeacherWorkoutTemplatesLoadingView()
            } else if templates.isEmpty {
                TeacherWorkoutTemplatesEmptyView(isCrossfitCategory: isCrossfitCategory)
            } else {
                TeacherWorkoutTemplatesList(
                    templates: templates,
                    showsTemplateActions: showsTemplateActions,
                    onTapTemplate: onTapTemplate,
                    onSendTemplate: onSendTemplate,
                    onDeleteTemplate: onDeleteTemplate
                )
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
}

struct TeacherWorkoutTemplatesList: View {

    let templates: [WorkoutTemplateFS]
    let showsTemplateActions: Bool
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
                        showsTemplateActions: showsTemplateActions,
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
    @Environment(\.locale) private var locale

    let template: WorkoutTemplateFS
    let showsTemplateActions: Bool
    let onSend: () -> Void
    let onDelete: () -> Void

    var body: some View {
        let presentation = DefaultWorkoutLocalization.presentation(for: template, locale: locale)
        HStack(spacing: 12) {

            Image(systemName: "dumbbell.fill")
                .foregroundColor(.green.opacity(0.85))
                .font(.system(size: 16))
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 4) {
                Text(presentation.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))

                let sub = presentation.description.trimmingCharacters(in: .whitespacesAndNewlines)
                if !sub.isEmpty {
                    Text(sub)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.55))
                        .lineLimit(2)
                }
            }

            Spacer()

            if showsTemplateActions {
                Menu {
                    Button {
                        onSend()
                    } label: {
                        Label(LocalizedStringKey("ui.send_to_student"), systemImage: "paperplane.fill")
                    }

                    Button(role: .destructive) {
                        onDelete()
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
            }

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
            Text("ui.loading")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }
}

struct TeacherWorkoutTemplatesEmptyView: View {

    let isCrossfitCategory: Bool
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(spacing: 10) {
            Text(
                isCrossfitCategory
                    ? AppLocalization.string("ui.no_wod_registered", locale: locale)
                    : AppLocalization.string("ui.no_workout_registered", locale: locale)
            )
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))

            Text(
                isCrossfitCategory
                    ? AppLocalization.string("ui.tap_add_wod_to_start", locale: locale)
                    : AppLocalization.string("ui.create_templates_for_them_to_appear_here", locale: locale)
            )
                .font(.system(size: 14))
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
    var usesApprovedCardStyle: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundColor(isError ? .yellow.opacity(0.85) : .green.opacity(0.85))

            Text(text)
                .font(.system(size: usesApprovedCardStyle ? 14 : 13))
                .foregroundColor(.white.opacity(0.75))

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.black.opacity(usesApprovedCardStyle ? 0.68 : 0.35))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    usesApprovedCardStyle
                        ? Theme.Colors.primaryGreen.opacity(0.28)
                        : Color.white.opacity(0.10),
                    lineWidth: 1
                )
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
