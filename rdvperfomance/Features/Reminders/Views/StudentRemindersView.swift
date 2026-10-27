import SwiftUI

/// Tela principal da aba Lembretes: Anotações, Lembretes e acesso à tela de Aniversários.
struct StudentRemindersView: View {

    @Binding var path: [StudentRemindersRoute]
    let onBack: () -> Void
    let onSelectSection: (StudentMainSection) -> Void

    @EnvironmentObject private var store: PersonalOrganizerStore
    @Environment(\.locale) private var locale
    @Environment(\.appTheme) private var appTheme

    @State private var section: PersonalOrganizerSection = .notes
    @State private var noteEditor: NoteEditorTarget?
    @State private var reminderEditor: ReminderEditorTarget?
    @State private var notePendingDeletion: PersonalNote?
    @State private var reminderPendingDeletion: PersonalReminder?
    @State private var errorMessage: String?

    struct NoteEditorTarget: Identifiable {
        let id = UUID()
        let note: PersonalNote?
    }

    struct ReminderEditorTarget: Identifiable {
        let id = UUID()
        let reminder: PersonalReminder?
    }

    var body: some View {
        PersonalScreenScaffold(
            titleKey: "reminders.title",
            onBack: onBack,
            onSelectSection: onSelectSection
        ) {
            sectionPicker

            if let errorMessage {
                PersonalMessageCard(text: errorMessage)
            } else if let loadError = store.loadError {
                PersonalMessageCard(text: loadError.loadMessage)
            }

            switch section {
            case .notes: notesSection
            case .reminders: remindersSection
            case .birthdays: PersonalBirthdaysContent()
            }
        }
        .sheet(item: $noteEditor) { target in
            PersonalNoteEditorSheet(note: target.note)
                .presentationDetents([.large])
        }
        .sheet(item: $reminderEditor) { target in
            PersonalReminderEditorSheet(reminder: target.reminder)
                .presentationDetents([.large])
        }
        .alert(
            "personal.note.delete_title",
            isPresented: Binding(
                get: { notePendingDeletion != nil },
                set: { if !$0 { notePendingDeletion = nil } }
            )
        ) {
            Button("common.cancel", role: .cancel) { notePendingDeletion = nil }
            Button("common.delete", role: .destructive) {
                if let note = notePendingDeletion { delete(note) }
                notePendingDeletion = nil
            }
        } message: {
            Text("personal.delete_message")
        }
        .alert(
            "personal.reminder.delete_title",
            isPresented: Binding(
                get: { reminderPendingDeletion != nil },
                set: { if !$0 { reminderPendingDeletion = nil } }
            )
        ) {
            Button("common.cancel", role: .cancel) { reminderPendingDeletion = nil }
            Button("common.delete", role: .destructive) {
                if let reminder = reminderPendingDeletion { delete(reminder) }
                reminderPendingDeletion = nil
            }
        } message: {
            Text("personal.delete_message")
        }
    }

    // MARK: - Seletor das três áreas

    private var sectionPicker: some View {
        HStack(spacing: 8) {
            sectionChip(titleKey: "personal.section.notes", icon: "note.text", isSelected: section == .notes) {
                section = .notes
            }
            sectionChip(titleKey: "personal.section.reminders", icon: "bell", isSelected: section == .reminders) {
                section = .reminders
            }
            sectionChip(titleKey: "personal.section.birthdays", icon: "gift", isSelected: section == .birthdays) {
                section = .birthdays
            }
        }
    }

    private func sectionChip(
        titleKey: LocalizedStringKey,
        icon: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                Text(titleKey)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(
                isSelected
                    ? AnyShapeStyle(Theme.Colors.systemAccentForeground())
                    : AnyShapeStyle(Theme.Colors.ink(0.75))
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                AppThemeColor(
                    dark: Color.black.opacity(isSelected ? 0.68 : 0.45),
                    light: PersonalOrganizerLightColors.innerSurface.opacity(isSelected ? 1 : 0.75)
                )
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected
                            ? AnyShapeStyle(Theme.Colors.cardBorder)
                            : AnyShapeStyle(Theme.Colors.ink(0.10)),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Anotações

    @ViewBuilder
    private var notesSection: some View {
        PersonalAddButton(titleKey: "personal.note.new") {
            noteEditor = NoteEditorTarget(note: nil)
        }

        if store.notes.isEmpty {
            emptyCard(textKey: "personal.note.empty")
        } else {
            ForEach(store.notes) { note in
                Button {
                    noteEditor = NoteEditorTarget(note: note)
                } label: {
                    noteRow(note)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func noteRow(_ note: PersonalNote) -> some View {
        HStack(alignment: .top, spacing: 12) {
            PersonalRowIcon(systemName: "note.text")

            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: note.title)
                    .font(.system(size: 17, weight: .semibold))
                    .modifier(PersonalPrimaryTextStyle())
                    .multilineTextAlignment(.leading)

                if !note.details.isEmpty {
                    Text(verbatim: note.details)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.Colors.ink(0.75))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }

                Text(verbatim: PersonalDateFormat.dateTime(note.updatedAt, locale: locale))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink(0.45))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            deleteButton { notePendingDeletion = note }
        }
        .personalCard()
    }

    // MARK: - Lembretes

    @ViewBuilder
    private var remindersSection: some View {
        PersonalAddButton(titleKey: "personal.reminder.new") {
            reminderEditor = ReminderEditorTarget(reminder: nil)
        }

        if store.reminders.isEmpty {
            emptyCard(textKey: "personal.reminder.empty")
        } else {
            ForEach(store.reminders) { reminder in
                Button {
                    reminderEditor = ReminderEditorTarget(reminder: reminder)
                } label: {
                    reminderRow(reminder)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func reminderRow(_ reminder: PersonalReminder) -> some View {
        let overdue = reminder.isOverdue

        return HStack(alignment: .top, spacing: 12) {
            PersonalRowIcon(systemName: "bell")

            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: reminder.title)
                    .font(.system(size: 17, weight: .semibold))
                    .modifier(PersonalPrimaryTextStyle())
                    .multilineTextAlignment(.leading)

                if !reminder.details.isEmpty {
                    Text(verbatim: reminder.details)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.Colors.ink(0.75))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }

                HStack(spacing: 8) {
                    Image(systemName: overdue ? "exclamationmark.circle.fill" : "clock")
                        .font(.system(size: 12))
                    Text(verbatim: PersonalDateFormat.dateTime(reminder.remindAt, locale: locale))
                        .font(.system(size: 12, weight: .semibold))
                    Text(overdue ? "personal.reminder.overdue" : "personal.reminder.upcoming")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(overdue ? Color.orange.opacity(0.25) : Color.green.opacity(0.22))
                        )
                    if reminder.notificationsEnabled {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 12))
                            .accessibilityLabel(Text("personal.notifications_on"))
                        if reminder.repeatsDaily {
                            Image(systemName: "repeat")
                                .font(.system(size: 12))
                                .accessibilityLabel(Text("personal.field.repeat_daily"))
                        }
                    }
                }
                .foregroundStyle(
                    overdue
                        ? AnyShapeStyle(Color.orange)
                        : AnyShapeStyle(Theme.Colors.systemAccentForeground())
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            deleteButton { reminderPendingDeletion = reminder }
        }
        .personalCard()
    }

    // MARK: - Auxiliares

    private func emptyCard(textKey: LocalizedStringKey) -> some View {
        Text(textKey)
            .font(.system(size: 14))
            .foregroundStyle(Theme.Colors.ink(0.55))
            .personalCard()
    }

    private func deleteButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "trash")
                .font(.system(size: 15))
                .foregroundColor(.red.opacity(0.9))
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("common.delete"))
    }

    private func delete(_ note: PersonalNote) {
        Task {
            do {
                try await store.deleteNote(note)
                errorMessage = nil
            } catch {
                errorMessage = PersonalOrganizerErrorKind.message(for: error)
            }
        }
    }

    private func delete(_ reminder: PersonalReminder) {
        Task {
            do {
                try await store.deleteReminder(reminder)
                errorMessage = nil
            } catch {
                errorMessage = PersonalOrganizerErrorKind.message(for: error)
            }
        }
    }
}

// MARK: - Card local dos registros de lembrete

/// Mesmo estilo de `PersonalCardModifier`, com fundo #DDEDDC apenas no Tema Claro.
private struct ReminderRowCardModifier: ViewModifier {
    @Environment(\.appTheme) private var appTheme

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                AppThemeColor(
                    dark: Color.black.opacity(0.68),
                    light: Color(red: 0xDD / 255, green: 0xED / 255, blue: 0xDC / 255)
                )
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        AppThemeColor(
                            dark: Theme.Colors.primaryGreen.opacity(0.28),
                            light: PersonalOrganizerLightColors.chevron
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: appTheme == .light ? .black.opacity(0.25) : .clear,
                radius: appTheme == .light ? 10 : 0,
                y: appTheme == .light ? 6 : 0
            )
    }
}

// MARK: - Editor de anotação

struct PersonalNoteEditorSheet: View {
    let note: PersonalNote?

    @EnvironmentObject private var store: PersonalOrganizerStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale

    @State private var title: String
    @State private var details: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(note: PersonalNote?) {
        self.note = note
        _title = State(initialValue: note?.title ?? "")
        _details = State(initialValue: note?.details ?? "")
    }

    var body: some View {
        PersonalEditorSheet(
            titleKey: note == nil ? "personal.note.new" : "personal.note.edit",
            canSave: !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            isSaving: isSaving,
            onCancel: { dismiss() },
            onSave: save
        ) {
            PersonalLabeledField(titleKey: "personal.field.title") {
                TextField("personal.field.title_placeholder", text: $title)
                    .modifier(PersonalFieldModifier())
            }

            PersonalLabeledField(titleKey: "personal.field.description") {
                TextField("personal.field.description_placeholder", text: $details, axis: .vertical)
                    .lineLimit(4...10)
                    .modifier(PersonalFieldModifier())
            }

            if let note {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("personal.note.created")
                        Text(verbatim: PersonalDateFormat.dateTime(note.createdAt, locale: locale))
                    }
                    HStack(spacing: 4) {
                        Text("personal.note.updated")
                        Text(verbatim: PersonalDateFormat.dateTime(note.updatedAt, locale: locale))
                    }
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.Colors.ink(0.45))
            }

            if let errorMessage {
                Text(verbatim: errorMessage)
                    .font(.system(size: 13))
                    .foregroundColor(.yellow.opacity(0.95))
            }
        }
    }

    private func save() {
        isSaving = true
        Task {
            do {
                try await store.saveNote(id: note?.id, title: title, details: details)
                dismiss()
            } catch {
                errorMessage = PersonalOrganizerErrorKind.message(for: error)
            }
            isSaving = false
        }
    }
}

// MARK: - Editor de lembrete

struct PersonalReminderEditorSheet: View {
    let reminder: PersonalReminder?

    @EnvironmentObject private var store: PersonalOrganizerStore
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var details: String
    @State private var remindAt: Date
    @State private var notificationsEnabled: Bool
    @State private var repeatsDaily: Bool
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(reminder: PersonalReminder?) {
        self.reminder = reminder
        _title = State(initialValue: reminder?.title ?? "")
        _details = State(initialValue: reminder?.details ?? "")
        _remindAt = State(initialValue: reminder?.remindAt ?? Self.defaultDate())
        _notificationsEnabled = State(initialValue: reminder?.notificationsEnabled ?? true)
        _repeatsDaily = State(initialValue: reminder?.repeatsDaily ?? false)
    }

    /// Próxima hora cheia.
    private static func defaultDate() -> Date {
        let calendar = Calendar.current
        let nextHour = calendar.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        return calendar.date(bySetting: .minute, value: 0, of: nextHour) ?? nextHour
    }

    var body: some View {
        PersonalEditorSheet(
            titleKey: reminder == nil ? "personal.reminder.new" : "personal.reminder.edit",
            canSave: !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            isSaving: isSaving,
            onCancel: { dismiss() },
            onSave: save
        ) {
            PersonalLabeledField(titleKey: "personal.field.title") {
                TextField("personal.field.title_placeholder", text: $title)
                    .modifier(PersonalFieldModifier())
            }

            PersonalLabeledField(titleKey: "personal.field.description") {
                TextField("personal.field.description_placeholder", text: $details, axis: .vertical)
                    .lineLimit(3...8)
                    .modifier(PersonalFieldModifier())
            }

            DatePicker(
                "personal.field.date",
                selection: $remindAt,
                displayedComponents: .date
            )
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Theme.Colors.ink(0.85))

            DatePicker(
                "personal.field.time",
                selection: $remindAt,
                displayedComponents: .hourAndMinute
            )
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Theme.Colors.ink(0.85))

            Toggle(isOn: $notificationsEnabled) {
                Text("personal.field.notify")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink(0.85))
            }
            .tint(Theme.Colors.primaryGreen)
            .onChange(of: notificationsEnabled) { _, isOn in
                // Autorização solicitada somente na primeira ativação (o iOS não repete o pedido depois)
                if isOn { Task { await store.requestNotificationAuthorizationIfNeeded() } }
            }

            if notificationsEnabled {
                Toggle(isOn: $repeatsDaily) {
                    Text("personal.field.repeat_daily")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink(0.85))
                }
                .tint(Theme.Colors.primaryGreen)
            }

            if notificationsEnabled && store.authorization == .denied {
                PersonalNotificationsDisabledBanner()
            }

            if let errorMessage {
                Text(verbatim: errorMessage)
                    .font(.system(size: 13))
                    .foregroundColor(.yellow.opacity(0.95))
            }
        }
    }

    private func save() {
        isSaving = true
        Task {
            do {
                if notificationsEnabled {
                    await store.requestNotificationAuthorizationIfNeeded()
                }
                try await store.saveReminder(
                    id: reminder?.id,
                    title: title,
                    details: details,
                    remindAt: remindAt,
                    notificationsEnabled: notificationsEnabled,
                    repeatsDaily: notificationsEnabled && repeatsDaily
                )
                dismiss()
            } catch {
                errorMessage = PersonalOrganizerErrorKind.message(for: error)
            }
            isSaving = false
        }
    }
}

