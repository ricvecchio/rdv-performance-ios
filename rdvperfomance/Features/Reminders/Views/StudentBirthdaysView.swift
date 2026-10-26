import SwiftUI
import UIKit

/// Tela dedicada de Aniversários (rota existente). O conteúdo é compartilhado com a aba Lembretes.
struct StudentBirthdaysView: View {

    @Binding var path: [StudentRemindersRoute]
    let onSelectSection: (StudentMainSection) -> Void

    @EnvironmentObject private var store: PersonalOrganizerStore

    var body: some View {
        PersonalScreenScaffold(
            titleKey: "birthdays.title",
            onBack: { if !path.isEmpty { path.removeLast() } },
            onSelectSection: onSelectSection
        ) {
            if let loadError = store.loadError {
                PersonalMessageCard(text: loadError.loadMessage)
            }

            PersonalBirthdaysContent()
        }
    }
}

/// Lista de aniversários (próximos primeiro), cadastro, edição e exclusão, sem estrutura de tela.
/// Usada dentro de `StudentRemindersView` e de `StudentBirthdaysView`.
struct PersonalBirthdaysContent: View {

    @EnvironmentObject private var store: PersonalOrganizerStore
    @Environment(\.locale) private var locale
    @Environment(\.scenePhase) private var scenePhase

    @State private var editor: BirthdayEditorTarget?
    @State private var pendingDeletion: PersonalBirthday?
    @State private var errorMessage: String?
    /// Data de referência do ícone de bolo; atualizada ao voltar ao primeiro plano e na virada do dia.
    @State private var today = Date()

    struct BirthdayEditorTarget: Identifiable {
        let id = UUID()
        let birthday: PersonalBirthday?
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let errorMessage {
                PersonalMessageCard(text: errorMessage)
            }

            let birthdays = store.upcomingBirthdays(now: today)

            if birthdays.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "gift")
                        .font(.system(size: 32))
                        .foregroundStyle(Theme.Colors.systemAccentForeground())

                    Text("birthdays.empty")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.Colors.ink(0.65))
                        .multilineTextAlignment(.center)

                    PersonalAddButton(titleKey: "birthdays.new") {
                        editor = BirthdayEditorTarget(birthday: nil)
                    }
                }
                .frame(maxWidth: .infinity)
                .personalCard()
            } else {
                PersonalAddButton(titleKey: "birthdays.new") {
                    editor = BirthdayEditorTarget(birthday: nil)
                }

                ForEach(birthdays) { birthday in
                    Button {
                        editor = BirthdayEditorTarget(birthday: birthday)
                    } label: {
                        row(birthday)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { today = Date() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            today = Date()
        }
        .sheet(item: $editor) { target in
            PersonalBirthdayEditorSheet(birthday: target.birthday)
                .presentationDetents([.large])
        }
        .alert(
            "birthdays.delete_title",
            isPresented: Binding(
                get: { pendingDeletion != nil },
                set: { if !$0 { pendingDeletion = nil } }
            )
        ) {
            Button("common.cancel", role: .cancel) { pendingDeletion = nil }
            Button("common.delete", role: .destructive) {
                if let birthday = pendingDeletion { delete(birthday) }
                pendingDeletion = nil
            }
        } message: {
            Text("personal.delete_message")
        }
    }

    private func row(_ birthday: PersonalBirthday) -> some View {
        let isToday = isBirthdayToday(birthday)

        return HStack(spacing: 12) {
            PersonalRowIcon(systemName: "gift.fill")

            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: isToday ? "🎂 \(birthday.name)" : birthday.name)
                    .font(.system(size: 17, weight: .semibold))
                    .modifier(PersonalPrimaryTextStyle())
                    .multilineTextAlignment(.leading)

                Text(verbatim: dateText(for: birthday))
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.ink(0.75))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: birthday.remindersEnabled ? "bell.fill" : "bell.slash")
                .font(.system(size: 15))
                .foregroundStyle(
                    birthday.remindersEnabled
                        ? AnyShapeStyle(Theme.Colors.systemAccentForeground())
                        : AnyShapeStyle(Theme.Colors.ink(0.45))
                )
                .accessibilityLabel(
                    Text(birthday.remindersEnabled ? "personal.notifications_on" : "personal.notifications_off")
                )

            Button {
                pendingDeletion = birthday
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 15))
                    .foregroundColor(.red.opacity(0.9))
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("common.delete"))
        }
        .personalCard()
    }

    /// "26 de outubro" ou, com ano de nascimento informado, "26 de outubro de 1965".
    private func dateText(for birthday: PersonalBirthday) -> String {
        if let year = birthday.birthYear {
            return PersonalDateFormat.dayMonthYear(
                day: birthday.day, month: birthday.month, year: year, locale: locale
            )
        }
        return PersonalDateFormat.dayMonth(day: birthday.day, month: birthday.month, locale: locale)
    }

    /// Hoje (data local do dispositivo). 29/02 em ano não bissexto vale em 28/02.
    private func isBirthdayToday(_ birthday: PersonalBirthday) -> Bool {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: today)
        guard let occurrence = birthday.occurrenceDay(year: year, calendar: calendar) else { return false }
        return calendar.isDate(occurrence, inSameDayAs: today)
    }

    private func delete(_ birthday: PersonalBirthday) {
        Task {
            do {
                try await store.deleteBirthday(birthday)
                errorMessage = nil
            } catch {
                errorMessage = PersonalOrganizerErrorKind.message(for: error)
            }
        }
    }
}

// MARK: - Editor de aniversário

struct PersonalBirthdayEditorSheet: View {
    let birthday: PersonalBirthday?

    @EnvironmentObject private var store: PersonalOrganizerStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale

    @State private var name: String
    @State private var day: Int
    @State private var month: Int
    @State private var includesYear: Bool
    @State private var birthYear: Int
    @State private var remindersEnabled: Bool
    @State private var notifyOneMonthBefore: Bool
    @State private var notifyOneWeekBefore: Bool
    @State private var isSaving = false
    @State private var errorMessage: String?

    private static let currentYear = Calendar.current.component(.year, from: Date())

    init(birthday: PersonalBirthday?) {
        self.birthday = birthday
        let calendar = Calendar.current
        _name = State(initialValue: birthday?.name ?? "")
        _day = State(initialValue: birthday?.day ?? calendar.component(.day, from: Date()))
        _month = State(initialValue: birthday?.month ?? calendar.component(.month, from: Date()))
        _includesYear = State(initialValue: birthday?.birthYear != nil)
        _birthYear = State(initialValue: birthday?.birthYear ?? (Self.currentYear - 30))
        _remindersEnabled = State(initialValue: birthday?.remindersEnabled ?? true)
        _notifyOneMonthBefore = State(initialValue: birthday?.notifyOneMonthBefore ?? false)
        _notifyOneWeekBefore = State(initialValue: birthday?.notifyOneWeekBefore ?? false)
    }

    private var isNameValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 29/02 com ano de nascimento não bissexto é uma data inexistente.
    private var isDateValid: Bool {
        guard includesYear, month == 2, day == 29 else { return true }
        return PersonalBirthday.isLeapYear(birthYear)
    }

    var body: some View {
        PersonalEditorSheet(
            titleKey: birthday == nil ? "birthdays.new" : "birthdays.edit",
            canSave: isNameValid && isDateValid,
            isSaving: isSaving,
            onCancel: { dismiss() },
            onSave: save
        ) {
            PersonalLabeledField(titleKey: "birthdays.field.name") {
                TextField("birthdays.field.name_placeholder", text: $name)
                    .textInputAutocapitalization(.words)
                    .modifier(PersonalFieldModifier())
            }

            PersonalLabeledField(titleKey: "birthdays.field.date") {
                HStack(spacing: 12) {
                    Picker("birthdays.field.day", selection: $day) {
                        ForEach(1...PersonalBirthday.daysInMonth(month), id: \.self) { value in
                            Text(verbatim: "\(value)").tag(value)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("birthdays.field.month", selection: $month) {
                        ForEach(1...12, id: \.self) { value in
                            Text(verbatim: PersonalDateFormat.monthNames(locale: locale)[value - 1]).tag(value)
                        }
                    }
                    .pickerStyle(.menu)

                    Spacer(minLength: 0)
                }
                .tint(Theme.Colors.systemAccentForeground())
                .onChange(of: month) { _, newMonth in
                    day = min(day, PersonalBirthday.daysInMonth(newMonth))
                }
            }

            Toggle(isOn: $includesYear) {
                Text("birthdays.field.include_year")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink(0.85))
            }
            .tint(Theme.Colors.primaryGreen)

            if includesYear {
                Picker("birthdays.field.year", selection: $birthYear) {
                    ForEach((1900...Self.currentYear).reversed(), id: \.self) { value in
                        Text(verbatim: "\(value)").tag(value)
                    }
                }
                .pickerStyle(.menu)
                .tint(Theme.Colors.systemAccentForeground())

                if !isDateValid {
                    Text("birthdays.invalid_date")
                        .font(.system(size: 13))
                        .foregroundColor(.yellow.opacity(0.95))
                }
            }

            Divider().background(Theme.Colors.divider)

            Toggle(isOn: $remindersEnabled) {
                Text("birthdays.field.remind")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink(0.85))
            }
            .tint(Theme.Colors.primaryGreen)
            .onChange(of: remindersEnabled) { _, isOn in
                // Autorização solicitada somente na primeira ativação
                if isOn { Task { await store.requestNotificationAuthorizationIfNeeded() } }
            }

            if remindersEnabled {
                Text("birthdays.same_day_info")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Colors.ink(0.55))

                Toggle(isOn: $notifyOneMonthBefore) {
                    Text("birthdays.field.one_month_before")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.Colors.ink(0.85))
                }
                .tint(Theme.Colors.primaryGreen)

                Toggle(isOn: $notifyOneWeekBefore) {
                    Text("birthdays.field.one_week_before")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.Colors.ink(0.85))
                }
                .tint(Theme.Colors.primaryGreen)

                if store.authorization == .denied {
                    PersonalNotificationsDisabledBanner()
                }
            }

            if let errorMessage {
                Text(verbatim: errorMessage)
                    .font(.system(size: 13))
                    .foregroundColor(.yellow.opacity(0.95))
            }
        }
    }

    private func save() {
        guard isNameValid, isDateValid else { return }
        isSaving = true
        Task {
            do {
                if remindersEnabled {
                    await store.requestNotificationAuthorizationIfNeeded()
                }
                try await store.saveBirthday(
                    id: birthday?.id,
                    name: name,
                    day: day,
                    month: month,
                    birthYear: includesYear ? birthYear : nil,
                    remindersEnabled: remindersEnabled,
                    // Períodos adicionais só valem com o lembrete ativado; o alerta do dia é sempre incluído
                    notifyOneMonthBefore: remindersEnabled && notifyOneMonthBefore,
                    notifyOneWeekBefore: remindersEnabled && notifyOneWeekBefore
                )
                dismiss()
            } catch {
                errorMessage = PersonalOrganizerErrorKind.message(for: error)
            }
            isSaving = false
        }
    }
}

