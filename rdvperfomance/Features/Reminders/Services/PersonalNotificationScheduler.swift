import Foundation
import UserNotifications

// MARK: - Identificadores estáveis

/// Identificadores de notificações locais: `rdv.personal.{uid}.{tipo}.{registro}[.{alerta}.{ano}]`.
/// O prefixo global permite limpar somente as notificações desta funcionalidade, preservando as demais.
enum PersonalNotificationIdentifier {
    static let globalPrefix = "rdv.personal."

    static func userPrefix(uid: String) -> String {
        "\(globalPrefix)\(uid)."
    }

    static func reminder(uid: String, id: String) -> String {
        "\(userPrefix(uid: uid))reminder.\(id)"
    }

    static func birthdayPrefix(uid: String, id: String) -> String {
        "\(userPrefix(uid: uid))birthday.\(id)."
    }

    static func birthday(uid: String, id: String, alert: BirthdayAlert, year: Int) -> String {
        "\(birthdayPrefix(uid: uid, id: id))\(alert.rawValue).\(year)"
    }

    enum BirthdayAlert: String {
        case oneMonth = "month"
        case oneWeek = "week"
        case sameDay = "day"
    }
}

// MARK: - Plano de notificações

struct PersonalNotificationPlan: Equatable {
    let identifier: String
    let fireDate: Date
    let title: String
    let body: String

    /// Muda quando data, idioma ou texto mudam (usada para evitar reagendamentos desnecessários).
    var signature: String {
        "\(Int(fireDate.timeIntervalSince1970))|\(title)|\(body)"
    }
}

/// Cálculo puro (sem acesso ao iOS) das notificações desejadas.
///
/// Recorrência anual de aniversários: como o iOS limita as notificações pendentes (64), não são agendados
/// todos os anos futuros. Para cada aniversário ativo são planejadas as ocorrências do ano corrente e do
/// próximo ano (alertas de um mês, uma semana e do próprio dia) que ainda estejam no futuro. O plano é
/// recalculado (reconciliação) sempre que o app abre, volta ao primeiro plano, muda o idioma, uma
/// permissão ou algum registro. Se o app ficar mais de ~1 ano sem ser aberto, as notificações já
/// agendadas se esgotam e só voltam a ser criadas na próxima abertura (limitação das notificações locais).
enum PersonalNotificationPlanner {

    /// Limite próprio, abaixo do máximo de 64 pendentes do iOS.
    static let maxPlans = 60

    static func plans(
        ownerUid: String,
        reminders: [PersonalReminder],
        birthdays: [PersonalBirthday],
        now: Date = Date(),
        calendar: Calendar = .current,
        locale: Locale
    ) -> [PersonalNotificationPlan] {
        var result: [PersonalNotificationPlan] = []

        // Lembretes pessoais
        for reminder in reminders where reminder.notificationsEnabled && reminder.remindAt > now {
            let trimmedDetails = reminder.details.trimmingCharacters(in: .whitespacesAndNewlines)
            result.append(
                PersonalNotificationPlan(
                    identifier: PersonalNotificationIdentifier.reminder(uid: ownerUid, id: reminder.id),
                    fireDate: reminder.remindAt,
                    title: reminder.title,
                    body: trimmedDetails.isEmpty
                        ? AppLocalization.string("personal_notification.reminder_default_body", locale: locale)
                        : trimmedDetails
                )
            )
        }

        // Aniversários
        let currentYear = calendar.component(.year, from: now)
        let title = AppLocalization.string("personal_notification.birthday_title", locale: locale)
        let dateFormatter = DateFormatter()
        dateFormatter.locale = locale
        dateFormatter.setLocalizedDateFormatFromTemplate("dMMMM")

        for birthday in birthdays where birthday.remindersEnabled {
            for year in currentYear...(currentYear + 1) {
                guard let occurrence = birthday.occurrenceDate(year: year, calendar: calendar) else { continue }
                let formattedDate = dateFormatter.string(from: occurrence)

                // No próprio dia: sempre incluído quando o lembrete está ativado
                appendBirthdayPlan(
                    &result, uid: ownerUid, birthday: birthday, alert: .sameDay, year: year,
                    fireDate: occurrence, now: now, title: title,
                    body: String(
                        format: AppLocalization.string("personal_notification.birthday_today_body", locale: locale),
                        birthday.name
                    )
                )

                if birthday.notifyOneWeekBefore,
                   let fire = calendar.date(byAdding: .day, value: -7, to: occurrence) {
                    appendBirthdayPlan(
                        &result, uid: ownerUid, birthday: birthday, alert: .oneWeek, year: year,
                        fireDate: fire, now: now, title: title,
                        body: String(
                            format: AppLocalization.string("personal_notification.birthday_week_body", locale: locale),
                            birthday.name,
                            formattedDate
                        )
                    )
                }

                // Calendário ajusta datas inexistentes ao último dia válido do mês (ex.: 31/03 → 28/02)
                if birthday.notifyOneMonthBefore,
                   let fire = calendar.date(byAdding: .month, value: -1, to: occurrence) {
                    appendBirthdayPlan(
                        &result, uid: ownerUid, birthday: birthday, alert: .oneMonth, year: year,
                        fireDate: fire, now: now, title: title,
                        body: String(
                            format: AppLocalization.string("personal_notification.birthday_month_body", locale: locale),
                            birthday.name,
                            formattedDate
                        )
                    )
                }
            }
        }

        return Array(result.sorted { $0.fireDate < $1.fireDate }.prefix(maxPlans))
    }

    private static func appendBirthdayPlan(
        _ result: inout [PersonalNotificationPlan],
        uid: String,
        birthday: PersonalBirthday,
        alert: PersonalNotificationIdentifier.BirthdayAlert,
        year: Int,
        fireDate: Date,
        now: Date,
        title: String,
        body: String
    ) {
        guard fireDate > now else { return }
        result.append(
            PersonalNotificationPlan(
                identifier: PersonalNotificationIdentifier.birthday(uid: uid, id: birthday.id, alert: alert, year: year),
                fireDate: fireDate,
                title: title,
                body: body
            )
        )
    }
}

// MARK: - Agendador (UserNotifications)

enum PersonalNotificationAuthorization: Equatable {
    case unknown
    case notDetermined
    case denied
    case authorized
}

@MainActor
final class PersonalNotificationScheduler {

    static let shared = PersonalNotificationScheduler()
    private init() {}

    private var center: UNUserNotificationCenter { UNUserNotificationCenter.current() }

    func authorizationStatus() async -> PersonalNotificationAuthorization {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .authorized, .provisional, .ephemeral: return .authorized
        @unknown default: return .denied
        }
    }

    /// Solicita autorização somente se o usuário ainda não decidiu (comportamento padrão do iOS).
    func requestAuthorizationIfNeeded() async -> PersonalNotificationAuthorization {
        let current = await authorizationStatus()
        guard current == .notDetermined else { return current }
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
        return await authorizationStatus()
    }

    /// Reconcilia as notificações pendentes com o plano desejado do usuário atual:
    /// remove as obsoletas (e as de outras contas), cria as que faltam e substitui as alteradas.
    /// Somente identificadores com o prefixo desta funcionalidade são tocados.
    func reconcile(plans: [PersonalNotificationPlan]) async {
        let status = await authorizationStatus()
        let pending = await center.pendingNotificationRequests()
        let mine = pending.filter { $0.identifier.hasPrefix(PersonalNotificationIdentifier.globalPrefix) }

        let desired = status == .authorized ? plans : []
        let desiredIds = Set(desired.map(\.identifier))

        let obsolete = mine.map(\.identifier).filter { !desiredIds.contains($0) }
        if !obsolete.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: obsolete)
        }
        guard status == .authorized else { return }

        var existingSignatures: [String: String] = [:]
        for request in mine {
            if let signature = request.content.userInfo["signature"] as? String {
                existingSignatures[request.identifier] = signature
            }
        }

        let calendar = Calendar.current
        for plan in desired where existingSignatures[plan.identifier] != plan.signature {
            let content = UNMutableNotificationContent()
            content.title = plan.title
            content.body = plan.body
            content.sound = .default
            content.userInfo = ["signature": plan.signature]

            let components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: plan.fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: plan.identifier, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    /// Cancela somente as notificações pendentes de um registro (aniversário ou lembrete).
    func cancelBirthday(ownerUid: String, id: String) async {
        let prefix = PersonalNotificationIdentifier.birthdayPrefix(uid: ownerUid, id: id)
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        if !ids.isEmpty { center.removePendingNotificationRequests(withIdentifiers: ids) }
    }

    /// Cancela o lembrete (disparo único, recorrente diário e ocorrências antecipadas).
    func cancelReminder(ownerUid: String, id: String) async {
        let single = PersonalNotificationIdentifier.reminder(uid: ownerUid, id: id)
        let dailyPrefix = PersonalNotificationIdentifier.reminderDailyPrefix(uid: ownerUid, id: id)
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0 == single || $0.hasPrefix(dailyPrefix) }
        if !ids.isEmpty { center.removePendingNotificationRequests(withIdentifiers: ids) }
    }

    /// Remove todas as notificações desta funcionalidade (logout, troca de conta ou exclusão de conta).
    func removeAllPersonalNotifications() async {
        let pending = await center.pendingNotificationRequests()
        let pendingIds = pending.map(\.identifier).filter { $0.hasPrefix(PersonalNotificationIdentifier.globalPrefix) }
        if !pendingIds.isEmpty { center.removePendingNotificationRequests(withIdentifiers: pendingIds) }

        let delivered = await center.deliveredNotifications()
        let deliveredIds = delivered.map(\.request.identifier).filter { $0.hasPrefix(PersonalNotificationIdentifier.globalPrefix) }
        if !deliveredIds.isEmpty { center.removeDeliveredNotifications(withIdentifiers: deliveredIds) }
    }
}

/// Permite exibir banner/som quando a notificação dispara com o app em primeiro plano.
nonisolated final class PersonalNotificationPresenter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = PersonalNotificationPresenter()

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}

