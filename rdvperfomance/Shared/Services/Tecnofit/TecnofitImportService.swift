import Foundation

enum TecnofitImportError: LocalizedError {
    case credentialsRequired
    case invalidCredentials
    case companySelectionRequired
    case noRecords
    case unavailable

    var errorDescription: String? {
        switch self {
        case .credentialsRequired:
            return "Informe seu e-mail e senha do Tecnofit para continuar."
        case .invalidCredentials:
            return "Não foi possível entrar no Tecnofit. Verifique seus dados."
        case .companySelectionRequired:
            return "Não foi possível identificar com segurança sua unidade CrossFit no Tecnofit."
        case .noRecords:
            return "Não encontramos recordes pessoais no Tecnofit para importar."
        case .unavailable:
            return "Não foi possível consultar o Tecnofit agora. Tente novamente."
        }
    }
}

struct TecnofitImportService {
    private static let authenticationURL = URL(string: "https://app.tecnofit.com.br/api-core/auth")!
    private static let apiBaseURL = URL(string: "https://rest.tecnofit.com.br")!

    func fetchPreview(
        sessionAccount: String,
        email: String?,
        password: String?
    ) async throws -> TecnofitImportPreview {
        if let storedToken = try TecnofitKeychainStore.token(for: sessionAccount) {
            do {
                return try await fetchPreview(token: storedToken)
            } catch TecnofitHTTPError.unauthorized {
                try? TecnofitKeychainStore.deleteToken(for: sessionAccount)
            }
        }

        guard let email = email?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty,
              let password, !password.isEmpty else {
            throw TecnofitImportError.credentialsRequired
        }

        let token = try await authenticate(email: email, password: password)
        do {
            let preview = try await fetchPreview(token: token)
            try TecnofitKeychainStore.save(token: token, for: sessionAccount)
            return preview
        } catch TecnofitHTTPError.unauthorized {
            throw TecnofitImportError.invalidCredentials
        }
    }

    private func authenticate(email: String, password: String) async throws -> String {
        var request = URLRequest(url: Self.authenticationURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(["email": email, "password": password])

        let data: Data
        do {
            data = try await responseData(for: request)
        } catch TecnofitHTTPError.unauthorized {
            throw TecnofitImportError.invalidCredentials
        } catch let error as TecnofitImportError {
            throw error
        } catch {
            throw TecnofitImportError.unavailable
        }

        do {
            let response = try JSONDecoder().decode(TecnofitAuthenticationResponse.self, from: data)
            let token = response.token.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !token.isEmpty else { throw TecnofitImportError.invalidCredentials }
            return token
        } catch let error as TecnofitImportError {
            throw error
        } catch {
            throw TecnofitImportError.invalidCredentials
        }
    }

    private func fetchPreview(token: String) async throws -> TecnofitImportPreview {
        let profile = try await profile(token: token)
        let company = try selectCompany(from: profile.customer.companies)
        let records = try await personalRecords(companyID: company.id.value, token: token)
        guard TecnofitPersonalRecordsMapper.map(records).actualCount > 0 else {
            throw TecnofitImportError.noRecords
        }
        let preview = TecnofitPersonalRecordsImporter.preview(from: records)
        return preview
    }

    private func profile(token: String) async throws -> TecnofitProfileResponse {
        var request = URLRequest(url: Self.apiBaseURL.appendingPathComponent("aluno").appendingPathComponent("eu"))
        request.timeoutInterval = 20
        applyAuthorization(token, to: &request)
        let data = try await responseData(for: request)
        do {
            return try JSONDecoder().decode(TecnofitProfileResponse.self, from: data)
        } catch {
            throw TecnofitImportError.unavailable
        }
    }

    private func personalRecords(companyID: String, token: String) async throws -> TecnofitPersonalRecordsResponse {
        var request = URLRequest(
            url: Self.apiBaseURL
                .appendingPathComponent(companyID)
                .appendingPathComponent("crossfit")
                .appendingPathComponent("personal-records")
        )
        request.timeoutInterval = 20
        applyAuthorization(token, to: &request)
        let data = try await responseData(for: request)
        do {
            return try JSONDecoder().decode(TecnofitPersonalRecordsResponse.self, from: data)
        } catch {
            throw TecnofitImportError.unavailable
        }
    }

    private func selectCompany(from companies: [TecnofitCompany]) throws -> TecnofitCompany {
        let accessible = companies.filter { $0.hasAccess }
        guard accessible.count == 1, let company = accessible.first else {
            throw TecnofitImportError.companySelectionRequired
        }
        return company
    }

    private func applyAuthorization(_ token: String, to request: inout URLRequest) {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
    }

    private func responseData(for request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TecnofitImportError.unavailable
        }
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw TecnofitHTTPError.unauthorized
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw TecnofitImportError.unavailable
        }
        return data
    }
}

private enum TecnofitHTTPError: Error {
    case unauthorized
}

enum TecnofitPersonalRecordsMapper {
    private static let barbellKeys = storageKeys([
        "Back Squat": "back_squat", "Bench Press": "bench_press", "Clean": "clean",
        "Clean & Jerk": "clean_and_jerk", "Clean Pull": "clean_pull", "Cluster": "cluster",
        "Deadlift": "deadlift", "Front Squat": "front_squat", "Hang Power Clean": "hang_power_clean",
        "Hang Power Snatch": "hang_power_snatch", "Muscle Clean": "muscle_clean",
        "Overhead Lunge": "overhead_lunge", "Power Clean": "power_clean", "Power Snatch": "power_snatch",
        "Push Jerk": "push_jerk", "Push Press": "push_press", "Shoulder Press": "shoulder_press",
        "Snatch": "snatch", "Snatch Balance": "snatch_balance", "Snatch Deadlift": "snatch_deadlift",
        "Snatch Pull": "snatch_pull", "Split Jerk": "split_jerk", "Squat Jerk": "squat_jerk",
        "Squat Snatch": "squat_snatch", "Sumo Deadlift": "sumo_deadlift",
        "Sumo Deadlift High Pull": "sumo_deadlift_high_pull", "Thruster": "thruster"
    ])

    private static let gymnasticKeys = storageKeys([
        "Abmat Sit-up: Max Reps": "abmat", "Air Squat: Max Reps": "air_squat",
        "Bar Muscle-ups: Max Reps": "bar_muscle_ups", "Box Jump: Max Height": "box_jump",
        "Double-under: Max Reps": "double_unders", "Handstand Push-ups: Max Reps": "handstand_push_ups",
        "Handstand Walk: Max Distance": "handstand_walk", "L-sit: Max Hold": "l_sit",
        "Muscle-ups: 30 Reps for Time": "muscle_ups_30_for_time", "Muscle-ups: Max Reps": "muscle_ups",
        "Pull-up (Chest to Bar): Max Reps": "pull_ups_ctb",
        "Pull-up (Strict): Max Reps": "pull_ups_strict",
        "Pull-up (Weighted): 1 Rep Max": "pull_up_weighted_1rm", "Push-up: Max Reps": "push_ups",
        "Ring Dip: Max Reps": "ring_dips", "Ring Muscle-ups: Max Reps": "ring_muscle_ups",
        "Ring Row": "ring_row", "Single Under: Max Reps": "single_unders",
        "Toes to Bar: Max Reps": "toes_to_bar", "Wall Ball: Max Reps": "wallball"
    ])

    private static let enduranceKeys = storageKeys([
        "Air Bike (100 Cal)": "air_bike_100_cal", "Air Bike (50 Cal)": "air_bike_50_cal",
        "Air Bike (Max Cal 1')": "air_bike_max_cal_1", "Row 100m": "row_100_m",
        "Row 1km": "row_1_km", "Row 2km": "row_2_km", "Row 5km": "row_5_km",
        "Row 10km": "row_10_km", "Row 21km": "row_21_km", "Row 500m": "row_500_m",
        "Run 100m": "run_100_m", "Run 200m": "run_200_m", "Run 400m": "run_400_m",
        "Run 800m": "run_800_m", "Run 1200m": "run_1200_m", "Run 1km": "run_1_km",
        "Run 2km": "run_2_km", "Run 5km": "run_5_km", "Run 10km": "run_10_km", "Run 15km": "run_15_km"
    ])

    private static let girlsKeys = storageKeys([
        "Amanda": "girls_amanda", "Angie": "girls_angie", "Annie": "girls_annie",
        "Barbara Ann": "girls_barbara_ann", "Barbara": "girls_barbara", "Charlotte": "girls_charlotte",
        "Chelsea": "girls_chelsea", "Christine": "girls_christine", "Cindy": "girls_cindy",
        "Diane": "girls_diane", "Elizabeth": "girls_elizabeth", "Emily": "girls_emily", "Eva": "girls_eva",
        "Fran": "girls_fran", "Grettel": "girls_grettel", "Grace": "girls_grace", "Gwen": "girls_gwen",
        "Helen": "girls_helen", "lasmim": "girls_lasmim", "Ingrid": "girls_ingrid", "Isabel": "girls_isabel",
        "Jackie": "girls_jackie", "Karen": "girls_karen", "Kelly": "girls_kelly", "Lesley": "girls_lesley",
        "Linda": "girls_linda", "Lola": "girls_lola", "Lyla": "girls_lyla", "Lynne": "girls_lynne",
        "Mary": "girls_mary", "Megan": "girls_megan", "Nancy": "girls_nancy", "Nicole": "girls_nicole",
        "Oleta": "girls_oleta", "Yvonne": "girls_yvonne"
    ])

    static func map(_ response: TecnofitPersonalRecordsResponse) -> (records: [TecnofitMappedPersonalRecord], actualCount: Int, unmatchedCount: Int) {
        var mapped = [TecnofitMappedPersonalRecord]()
        var actualCount = 0
        var unmatchedCount = 0

        for modality in response.modalities {
            for record in modality.personalRecords where hasActualResult(record) {
                actualCount += 1
                guard let item = map(record, modality: modality.modality) else {
                    unmatchedCount += 1
                    continue
                }
                mapped.append(item)
            }
        }

        for workoutDay in response.workoutDay {
            for record in workoutDay.personalRecords where hasActualResult(record) {
                actualCount += 1
                guard let item = map(record, workoutDay: workoutDay.workoutDay) else {
                    unmatchedCount += 1
                    continue
                }
                mapped.append(item)
            }
        }

        return (mapped, actualCount, unmatchedCount)
    }

    static func normalize(_ value: String) -> String {
        let folded = value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
        return folded.unicodeScalars.reduce(into: "") { result, scalar in
            if CharacterSet.alphanumerics.contains(scalar) {
                result.unicodeScalars.append(scalar)
            } else {
                result.append(" ")
            }
        }
        .split(whereSeparator: { $0.isWhitespace })
        .joined(separator: " ")
        .lowercased()
    }

    private static func map(_ record: TecnofitRecord, modality: String) -> TecnofitMappedPersonalRecord? {
        guard let movement = record.movement else { return nil }
        switch normalize(modality) {
        case "barbell":
            guard let key = barbellKeys[normalize(movement)], let value = decimalValue(record) else { return nil }
            return .init(target: .barbell, storageKey: key, value: .numeric(value))
        case "gymnastic":
            guard let key = gymnasticKeys[normalize(movement)], let value = textValue(record) else { return nil }
            return .init(target: .gymnastic, storageKey: key, value: .text(value))
        case "endurance":
            guard let key = enduranceKeys[normalize(movement)], let value = textValue(record) else { return nil }
            return .init(target: .endurance, storageKey: key, value: .text(value))
        default:
            return nil
        }
    }

    private static func map(_ record: TecnofitRecord, workoutDay: String) -> TecnofitMappedPersonalRecord? {
        guard normalize(workoutDay) == "girls",
              let name = record.workoutDay,
              let key = girlsKeys[normalize(name)],
              let value = girlsValue(record) else {
            return nil
        }
        return .init(target: .girls, storageKey: key, value: .numeric(value))
    }

    private static func hasActualResult(_ record: TecnofitRecord) -> Bool {
        guard let customerID = record.customerId?.value.trimmingCharacters(in: .whitespacesAndNewlines), !customerID.isEmpty,
              let companyID = record.companyId?.value.trimmingCharacters(in: .whitespacesAndNewlines), !companyID.isEmpty else {
            return false
        }
        return [record.decimalRecord, record.timeRecord, record.poundsRecord].contains { value in
            guard let value else { return false }
            return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private static func decimalValue(_ record: TecnofitRecord) -> Double? {
        guard let value = record.decimalRecord?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty,
              let decimal = Double(value.replacingOccurrences(of: ",", with: ".")),
              decimal.isFinite else {
            return nil
        }
        return decimal
    }

    private static func textValue(_ record: TecnofitRecord) -> String? {
        if let time = record.timeRecord?.trimmingCharacters(in: .whitespacesAndNewlines), !time.isEmpty {
            return time
        }
        guard let decimal = decimalValue(record) else { return nil }
        return format(decimal)
    }

    private static func girlsValue(_ record: TecnofitRecord) -> Double? {
        if let time = record.timeRecord?.trimmingCharacters(in: .whitespacesAndNewlines), !time.isEmpty {
            return seconds(from: time)
        }
        let type = normalize(record.resultType ?? "")
        guard [
            "rep", "reps", "max rep", "max reps", "repetition", "repetitions", "max repetitions",
            "score", "round", "rounds", "cal", "cals", "calorie", "calories", "point", "points"
        ].contains(type) else {
            return nil
        }
        return decimalValue(record)
    }

    private static func seconds(from value: String) -> Double? {
        let parts = value.split(separator: ":", omittingEmptySubsequences: false)
        if parts.count == 1 {
            return Double(value.replacingOccurrences(of: ",", with: "."))
        }
        guard (2...3).contains(parts.count),
              let seconds = Int(parts[parts.count - 1]), (0..<60).contains(seconds),
              let minutes = Int(parts[parts.count - 2]), (0..<60).contains(minutes) else {
            return nil
        }
        if parts.count == 2 { return Double(minutes * 60 + seconds) }
        guard let hours = Int(parts[0]), hours >= 0 else { return nil }
        return Double(hours * 3_600 + minutes * 60 + seconds)
    }

    private static func format(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 6
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    private static func storageKeys(_ source: [String: String]) -> [String: String] {
        Dictionary(uniqueKeysWithValues: source.map { (normalize($0.key), $0.value) })
    }
}

enum TecnofitPersonalRecordsImporter {
    static func preview(from response: TecnofitPersonalRecordsResponse, defaults: UserDefaults = .standard) -> TecnofitImportPreview {
        let mapped = TecnofitPersonalRecordsMapper.map(response)
        let existing = ExistingValues(defaults: defaults)
        var ready = [TecnofitMappedPersonalRecord]()
        var conflicts = 0

        for record in mapped.records {
            if existing.hasValue(for: record.target, storageKey: record.storageKey) {
                conflicts += 1
            } else {
                ready.append(record)
            }
        }

        return TecnofitImportPreview(
            recordsReady: ready.count,
            conflictsPreserved: conflicts,
            unmatchedSkipped: mapped.unmatchedCount,
            records: ready
        )
    }

    @MainActor
    @discardableResult
    static func apply(_ preview: TecnofitImportPreview, defaults: UserDefaults = .standard) -> Int {
        var existing = ExistingValues(defaults: defaults)
        var additions = 0

        for record in preview.records where !existing.hasValue(for: record.target, storageKey: record.storageKey) {
            guard existing.insert(record) else { continue }
            additions += 1
        }

        existing.save(to: defaults)
        if additions > 0 {
            PersonalRecordsSyncService.shared.didMutateLocalRecords()
        }
        return additions
    }

    private struct ExistingValues {
        private var numeric: [TecnofitPersonalRecordsTarget: [String: Double]] = [:]
        private var text: [TecnofitPersonalRecordsTarget: [String: String]] = [:]
        private var validTargets: Set<TecnofitPersonalRecordsTarget> = []
        private var dirtyTargets: Set<TecnofitPersonalRecordsTarget> = []

        init(defaults: UserDefaults) {
            loadNumeric(.barbell, defaults: defaults)
            loadNumeric(.girls, defaults: defaults)
            loadText(.gymnastic, defaults: defaults)
            loadText(.endurance, defaults: defaults)
        }

        func hasValue(for target: TecnofitPersonalRecordsTarget, storageKey: String) -> Bool {
            guard validTargets.contains(target) else { return true }
            if let value = numeric[target]?[storageKey] {
                return value.isFinite
            }
            if let value = text[target]?[storageKey] {
                return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            return false
        }

        mutating func insert(_ record: TecnofitMappedPersonalRecord) -> Bool {
            guard validTargets.contains(record.target) else { return false }
            switch record.value {
            case .numeric(let value):
                guard value.isFinite else { return false }
                numeric[record.target, default: [:]][record.storageKey] = value
            case .text(let value):
                guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
                text[record.target, default: [:]][record.storageKey] = value
            }
            dirtyTargets.insert(record.target)
            return true
        }

        func save(to defaults: UserDefaults) {
            for target in dirtyTargets {
                let data: Data?
                switch target {
                case .barbell, .girls:
                    data = try? JSONEncoder().encode(numeric[target] ?? [:])
                case .gymnastic, .endurance:
                    data = try? JSONEncoder().encode(text[target] ?? [:])
                }
                if let data { defaults.set(data, forKey: target.valuesKey) }
            }
        }

        private mutating func loadNumeric(_ target: TecnofitPersonalRecordsTarget, defaults: UserDefaults) {
            guard let data = defaults.data(forKey: target.valuesKey), !data.isEmpty else {
                numeric[target] = [:]
                validTargets.insert(target)
                return
            }
            guard let values = try? JSONDecoder().decode([String: Double].self, from: data) else { return }
            numeric[target] = values
            validTargets.insert(target)
        }

        private mutating func loadText(_ target: TecnofitPersonalRecordsTarget, defaults: UserDefaults) {
            guard let data = defaults.data(forKey: target.valuesKey), !data.isEmpty else {
                text[target] = [:]
                validTargets.insert(target)
                return
            }
            guard let values = try? JSONDecoder().decode([String: String].self, from: data) else { return }
            text[target] = values
            validTargets.insert(target)
        }
    }
}
