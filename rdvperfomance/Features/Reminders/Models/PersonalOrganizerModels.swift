import Foundation
import FirebaseFirestore

// MARK: - Coleções

/// Subcoleções pessoais de `users/{uid}`. Isoladas dos dados de treino e nunca compartilhadas com professores.
enum PersonalOrganizerCollection: String, CaseIterable {
    case notes = "personal_notes"
    case reminders = "personal_reminders"
    case birthdays = "personal_birthdays"
}

// MARK: - Anotação

struct PersonalNote: Identifiable, Equatable {
    let id: String
    var ownerUid: String
    var title: String
    var details: String
    var createdAt: Date
    var updatedAt: Date

    init(id: String, ownerUid: String, title: String, details: String, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.ownerUid = ownerUid
        self.title = title
        self.details = details
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init?(id: String, data: [String: Any]) {
        guard let ownerUid = data["ownerUid"] as? String,
              let title = data["title"] as? String else { return nil }
        self.init(
            id: id,
            ownerUid: ownerUid,
            title: title,
            details: data["details"] as? String ?? "",
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }

    var firestoreData: [String: Any] {
        [
            "id": id,
            "ownerUid": ownerUid,
            "title": title,
            "details": details,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
    }

    func hasSameContent(as other: PersonalNote) -> Bool {
        title == other.title && details == other.details
    }
}

// MARK: - Lembrete

struct PersonalReminder: Identifiable, Equatable {
    let id: String
    var ownerUid: String
    var title: String
    var details: String
    var remindAt: Date
    var notificationsEnabled: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String,
        ownerUid: String,
        title: String,
        details: String,
        remindAt: Date,
        notificationsEnabled: Bool,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.ownerUid = ownerUid
        self.title = title
        self.details = details
        self.remindAt = remindAt
        self.notificationsEnabled = notificationsEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init?(id: String, data: [String: Any]) {
        guard let ownerUid = data["ownerUid"] as? String,
              let title = data["title"] as? String,
              let remindAt = (data["remindAt"] as? Timestamp)?.dateValue() else { return nil }
        self.init(
            id: id,
            ownerUid: ownerUid,
            title: title,
            details: data["details"] as? String ?? "",
            remindAt: remindAt,
            notificationsEnabled: data["notificationsEnabled"] as? Bool ?? false,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }

    var firestoreData: [String: Any] {
        [
            "id": id,
            "ownerUid": ownerUid,
            "title": title,
            "details": details,
            "remindAt": Timestamp(date: remindAt),
            "notificationsEnabled": notificationsEnabled,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
    }

    func hasSameContent(as other: PersonalReminder) -> Bool {
        title == other.title
            && details == other.details
            && remindAt == other.remindAt
            && notificationsEnabled == other.notificationsEnabled
            && repeatsDaily == other.repeatsDaily
    }

    /// Lembrete diário com notificação ativa continua sendo disparado todos os dias: nunca é "vencido".
    var isOverdue: Bool { !(notificationsEnabled && repeatsDaily) && remindAt < Date() }
}

// MARK: - Aniversário

struct PersonalBirthday: Identifiable, Equatable {
    /// Horário fixo (09:00) dos alertas: o mesmo para os antecipados e para o do próprio dia.
    static let notificationHour = 9
    static let notificationMinute = 0

    let id: String
    var ownerUid: String
    var name: String
    var day: Int
    var month: Int
    var birthYear: Int?
    var remindersEnabled: Bool
    var notifyOneMonthBefore: Bool
    var notifyOneWeekBefore: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String,
        ownerUid: String,
        name: String,
        day: Int,
        month: Int,
        birthYear: Int?,
        remindersEnabled: Bool,
        notifyOneMonthBefore: Bool,
        notifyOneWeekBefore: Bool,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.ownerUid = ownerUid
        self.name = name
        self.day = day
        self.month = month
        self.birthYear = birthYear
        self.remindersEnabled = remindersEnabled
        self.notifyOneMonthBefore = notifyOneMonthBefore
        self.notifyOneWeekBefore = notifyOneWeekBefore
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init?(id: String, data: [String: Any]) {
        guard let ownerUid = data["ownerUid"] as? String,
              let name = data["name"] as? String,
              let day = data["day"] as? Int,
              let month = data["month"] as? Int,
              (1...12).contains(month),
              (1...Self.daysInMonth(month)).contains(day) else { return nil }
        self.init(
            id: id,
            ownerUid: ownerUid,
            name: name,
            day: day,
            month: month,
            birthYear: data["birthYear"] as? Int,
            remindersEnabled: data["remindersEnabled"] as? Bool ?? false,
            notifyOneMonthBefore: data["notifyOneMonthBefore"] as? Bool ?? false,
            notifyOneWeekBefore: data["notifyOneWeekBefore"] as? Bool ?? false,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }

    var firestoreData: [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "ownerUid": ownerUid,
            "name": name,
            "day": day,
            "month": month,
            "remindersEnabled": remindersEnabled,
            "notifyOneMonthBefore": notifyOneMonthBefore,
            "notifyOneWeekBefore": notifyOneWeekBefore,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
        if let birthYear { data["birthYear"] = birthYear }
        return data
    }

    func hasSameContent(as other: PersonalBirthday) -> Bool {
        name == other.name
            && day == other.day
            && month == other.month
            && birthYear == other.birthYear
            && remindersEnabled == other.remindersEnabled
            && notifyOneMonthBefore == other.notifyOneMonthBefore
            && notifyOneWeekBefore == other.notifyOneWeekBefore
    }

    // MARK: Calendário

    static func isLeapYear(_ year: Int) -> Bool {
        (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
    }

    /// Maior dia possível do mês (fevereiro aceita 29, pois o aniversário vale todos os anos).
    static func daysInMonth(_ month: Int) -> Int {
        switch month {
        case 2: return 29
        case 4, 6, 9, 11: return 30
        default: return 31
        }
    }

    /// Dia do aniversário no ano informado. 29/02 vira 28/02 em anos não bissextos.
    func occurrenceDay(year: Int, calendar: Calendar = .current) -> Date? {
        var effectiveDay = day
        if month == 2 && day == 29 && !Self.isLeapYear(year) {
            effectiveDay = 28
        }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = effectiveDay
        return calendar.date(from: components)
    }

    /// Data/hora (09:00) do aniversário no ano informado.
    func occurrenceDate(year: Int, calendar: Calendar = .current) -> Date? {
        guard let dayStart = occurrenceDay(year: year, calendar: calendar) else { return nil }
        return calendar.date(
            bySettingHour: Self.notificationHour,
            minute: Self.notificationMinute,
            second: 0,
            of: dayStart
        )
    }

    /// Próximo dia de aniversário a partir de hoje (inclusive), considerando apenas dia e mês.
    func nextOccurrenceDay(from now: Date = Date(), calendar: Calendar = .current) -> Date {
        let today = calendar.startOfDay(for: now)
        let currentYear = calendar.component(.year, from: now)
        for year in currentYear...(currentYear + 1) {
            if let candidate = occurrenceDay(year: year, calendar: calendar), candidate >= today {
                return candidate
            }
        }
        return Date.distantFuture
    }
}

