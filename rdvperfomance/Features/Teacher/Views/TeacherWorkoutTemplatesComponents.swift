import SwiftUI

// Cores locais exclusivas do Tema Claro (padrao da TrainingWeeksView; Tema Escuro usa sempre os valores originais)
private enum TemplatesLightColors {
    static let cardSurface = Color(red: 0xDD / 255, green: 0xED / 255, blue: 0xDC / 255)   // #DDEDDC
    static let iconSurface = Color(red: 0x85 / 255, green: 0xC9 / 255, blue: 0x95 / 255)   // #85C995
    static let iconInk = Color(red: 0x25 / 255, green: 0x48 / 255, blue: 0x2B / 255)       // #25482B
    static let primaryText = Color(red: 0x17 / 255, green: 0x1C / 255, blue: 0x17 / 255)   // #171C17
    static let chevron = Color(red: 0x29 / 255, green: 0x4A / 255, blue: 0x2F / 255)       // #294A2F
    static let border = Color(red: 0xC9 / 255, green: 0xDF / 255, blue: 0xC9 / 255)        // #C9DFC9
}

struct TeacherWorkoutTemplatesAddButton: View {

    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "plus")
                    .appThemeIconForeground()
                Text(title)
            }
            .padding(.horizontal, 14)
            .compactPrimaryGreenActionButton()
        }
        .buttonStyle(.plain)
    }
}

struct TeacherWorkoutTemplatesContentCard: View {
    @Environment(\.appTheme) private var appTheme

    let isLoading: Bool
    let hasLoadedInitialData: Bool
    let templates: [WorkoutTemplateFS]
    let isCrossfitCategory: Bool
    let category: TreinoTipo
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
                    category: category,
                    showsTemplateActions: showsTemplateActions,
                    onTapTemplate: onTapTemplate,
                    onSendTemplate: onSendTemplate,
                    onDeleteTemplate: onDeleteTemplate
                )
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: TemplatesLightColors.cardSurface))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: TemplatesLightColors.border), lineWidth: 1)
        )
        // Tema Claro: mesma profundidade da AdminProfileSelectionView (Tema Escuro: sem sombra)
        .shadow(
            color: appTheme == .light ? .black.opacity(0.25) : .clear,
            radius: appTheme == .light ? 10 : 0,
            y: appTheme == .light ? 6 : 0
        )
    }
}

struct TeacherWorkoutTemplatesList: View {

    let templates: [WorkoutTemplateFS]
    let category: TreinoTipo
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
                        category: category,
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
    let category: TreinoTipo
    let showsTemplateActions: Bool
    let onSend: () -> Void
    let onDelete: () -> Void

    private var categoryIcon: String {
        switch category {
        case .crossfit:
            return "figure.strengthtraining.traditional"
        case .academia:
            return "dumbbell"
        case .emCasa:
            return "house.fill"
        }
    }

    var body: some View {
        let presentation = DefaultWorkoutLocalization.presentation(for: template, locale: locale)
        HStack(spacing: 12) {

            Image(systemName: categoryIcon)
                .foregroundStyle(AppThemeColor(dark: Color.green.opacity(0.85), light: TemplatesLightColors.iconInk))
                .font(.system(size: 16))
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 4) {
                Text(presentation.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: TemplatesLightColors.primaryText))

                let sub = presentation.description.trimmingCharacters(in: .whitespacesAndNewlines)
                if !sub.isEmpty {
                    Text(sub)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.Colors.ink(0.55))
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
                        .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.55), light: TemplatesLightColors.iconInk))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Image(systemName: "chevron.right")
                .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.35), light: TemplatesLightColors.chevron))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Theme.Colors.ink(0.001)) // ✅ Garante área de toque completa
    }
}

struct TeacherWorkoutTemplatesLoadingView: View {
    var body: some View {
        VStack(spacing: 10) {
            ProgressView()
            Text("ui.loading")
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.ink(0.55))
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
                .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: TemplatesLightColors.primaryText))

            Text(
                isCrossfitCategory
                    ? AppLocalization.string("ui.tap_add_wod_to_start", locale: locale)
                    : AppLocalization.string("ui.create_templates_for_them_to_appear_here", locale: locale)
            )
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.ink(0.55))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 10)
    }
}

struct TeacherWorkoutTemplatesMessageCard: View {
    @Environment(\.appTheme) private var appTheme

    let text: String
    let isError: Bool
    var usesApprovedCardStyle: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundColor(isError ? .yellow.opacity(0.85) : .green.opacity(0.85))

            Text(text)
                .font(.system(size: usesApprovedCardStyle ? 14 : 13))
                .foregroundStyle(Theme.Colors.ink(0.75))

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(usesApprovedCardStyle ? AppThemeColor(dark: Color.black.opacity(0.68), light: TemplatesLightColors.cardSurface) : Theme.Colors.glass(0.35))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    usesApprovedCardStyle
                        ? AnyShapeStyle(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: TemplatesLightColors.border))
                        : AnyShapeStyle(Theme.Colors.ink(0.10)),
                    lineWidth: 1
                )
        )
        // Tema Claro: mesma profundidade da AdminProfileSelectionView (Tema Escuro: sem sombra)
        .shadow(
            color: usesApprovedCardStyle && appTheme == .light ? .black.opacity(0.25) : .clear,
            radius: usesApprovedCardStyle && appTheme == .light ? 10 : 0,
            y: usesApprovedCardStyle && appTheme == .light ? 6 : 0
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
