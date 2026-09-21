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
        let mapped = TecnofitPersonalRecordsMapper.map(records)
        guard mapped.actualCount > 0 else {
            throw TecnofitImportError.noRecords
        }
        let detailed = try await detailedRecords(
            for: mapped.records,
            companyID: company.id.value,
            token: token
        )
        return TecnofitPersonalRecordsImporter.preview(
            records: detailed,
            unmatchedCount: mapped.unmatchedCount
        )
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

    private func detailedRecords(
        for records: [TecnofitMappedPersonalRecord],
        companyID: String,
        token: String
    ) async throws -> [TecnofitMappedPersonalRecord] {
        var uniqueRecords = [TecnofitMappedPersonalRecord]()
        var seenRecords = Set<String>()

        for record in records {
            let identity = "\(record.source)|\(record.target)|\(record.storageKey)|\(record.movementID ?? "")"
            if seenRecords.insert(identity).inserted {
                uniqueRecords.append(record)
            }
        }

        var detailsByMovement = [String: TecnofitPersonalRecordDetailResponse]()
        var attemptedMovementIDs = Set<String>()
        var imported = [TecnofitMappedPersonalRecord]()
        for record in uniqueRecords {
            guard record.source == .movement else {
                imported.append(record)
                continue
            }

            guard let movementID = record.movementID?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !movementID.isEmpty else {
                imported.append(record)
                continue
            }

            let detail: TecnofitPersonalRecordDetailResponse?
            if attemptedMovementIDs.contains(movementID) {
                detail = detailsByMovement[movementID]
            } else {
                attemptedMovementIDs.insert(movementID)
                do {
                    let response = try await personalRecordDetail(
                        companyID: companyID,
                        movementID: movementID,
                        token: token
                    )
                    detailsByMovement[movementID] = response
                    detail = response
                } catch TecnofitHTTPError.unauthorized {
                    throw TecnofitHTTPError.unauthorized
                } catch {
                    detail = nil
                }
            }

            if let detail,
               let mapped = TecnofitPersonalRecordsMapper.map(detail: detail, to: record) {
                imported.append(mapped)
            } else {
                imported.append(record)
            }
        }

        return imported
    }

    private func personalRecordDetail(
        companyID: String,
        movementID: String,
        token: String
    ) async throws -> TecnofitPersonalRecordDetailResponse {
        var request = URLRequest(
            url: Self.apiBaseURL
                .appendingPathComponent(companyID)
                .appendingPathComponent("crossfit")
                .appendingPathComponent("personal-records")
                .appendingPathComponent("movement")
                .appendingPathComponent(movementID)
        )
        request.timeoutInterval = 20
        applyAuthorization(token, to: &request)
        let data = try await responseData(for: request)
        do {
            return try JSONDecoder().decode(TecnofitPersonalRecordDetailEnvelope.self, from: data).movement
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

    private static let notablesKeys = storageKeys([
        "Black Jack": "black_jack", "Bear Complex": "bear_complex",
        "Broomstick Mile": "broomstick_mile", "Circus": "circus",
        "Crossfit Total": "crossfit_total", "Death by Pull-Ups": "death_by_pull_ups",
        "Fat Amy": "fat_amy", "Fight Gone Bad": "fight_gone_bad",
        "Filthy Fifty": "filthy_fifty", "Hope": "hope",
        "Iron Triathlon": "iron_triathlon", "Jeremy": "jeremy",
        "King Kong": "king_kong", "Nasty Girls": "nasty_gilrs",
        "Tabata Something Else": "tabata_something_else", "Tabata This": "tabata_this",
        "The 300": "the_300", "The Chief": "the_chief"
    ])

    private static let heroesKeys = storageKeys([
        "Abbate": "hero_abbate", "Adam Brown": "hero_adam_brown", "Adrian": "hero_adrian",
        "Alexander": "hero_alexander", "Andy": "hero_andy", "Bert": "hero_bert",
        "Big Sexy": "hero_big_sexy", "Blake": "hero_blake", "Bowen": "hero_bowen",
        "Bradley": "hero_bradley", "Bradshaw": "hero_bradshaw", "Brehm": "hero_brehm",
        "Brian": "hero_brian", "Bruck": "hero_bruck", "Bulger": "hero_bulger",
        "Bull": "hero_bull", "Cameron": "hero_cameron", "Capoot": "hero_capoot",
        "Carse": "hero_carse", "Chad": "hero_chad", "Coe": "hero_coe",
        "Coffey": "hero_coffey", "Garrett": "hero_garrett", "Gator": "hero_gator",
        "Gaza": "hero_gaza", "Glen": "hero_glen", "Griff": "hero_griff",
        "Hall": "hero_hall", "Hamilton": "hero_hamilton", "Hammer": "hero_hammer",
        "Hansen": "hero_hansen", "Murph": "hero_murph", "JT": "hero_jt",
        "Michael": "hero_michael", "Sisson": "hero_sisson", "Randy": "hero_randy"
    ])

    private static let openKeys = storageKeys([
        "Open 11.1": "open_11_1", "Open 11.2": "open_11_2", "Open 11.3": "open_11_3",
        "Open 12.1": "open_12_1", "Open 12.2": "open_12_2", "Open 12.3": "open_12_3",
        "Open 12.4": "open_12_4", "Open 12.5": "open_12_5",
        "Open 13.1": "open_13_1", "Open 13.2": "open_13_2", "Open 13.3": "open_13_3",
        "Open 13.4": "open_13_4", "Open 13.5": "open_13_5",
        "Open 14.1": "open_14_1", "Open 14.2": "open_14_2", "Open 14.3": "open_14_3",
        "Open 14.4": "open_14_4", "Open 14.5": "open_14_5",
        "Open 15.1": "open_15_1", "Open 15.1a": "open_15_1a", "Open 15.2": "open_15_2",
        "Open 15.3": "open_15_3", "Open 15.4": "open_15_4", "Open 15.5": "open_15_5",
        "Open 16.1": "open_16_1", "Open 16.2": "open_16_2", "Open 16.3": "open_16_3",
        "Open 16.4": "open_16_4", "Open 16.5": "open_16_5",
        "Open 17.1 RX": "open_17_1_rx", "Open 17.1 SCALE": "open_17_1_scale",
        "Open 17.2 RX": "open_17_2_rx", "Open 17.2 SCALE": "open_17_2_scale",
        "Open 17.3 RX": "open_17_3_rx", "Open 17.3 SCALE": "open_17_3_scale",
        "Open 17.4 RX": "open_17_4_rx", "Open 17.4 SCALE": "open_17_4_scale",
        "Open 17.5 RX": "open_17_5_rx", "Open 17.5 SCALE": "open_17_5_scale",
        "Open 18.1 RX": "open_18_1_rx", "Open 18.1 SCALE": "open_18_1_scale",
        "Open 18.2": "open_18_2", "Open 18.2a": "open_18_2a",
        "Open 18.3 RX": "open_18_3_rx", "Open 18.3 SCALE": "open_18_3_scale",
        "Open 18.4 RX": "open_18_4_rx", "Open 18.4 SCALE": "open_18_4_scale",
        "Open 18.5 RX": "open_18_5_rx", "Open 18.5 SCALE": "open_18_5_scale",
        "Open 19.1 RX": "open_19_1_rx", "Open 19.1 SCALE": "open_19_1_scale",
        "Open 19.2 RX": "open_19_2_rx", "Open 19.2 SCALE": "open_19_2_scale",
        "Open 19.3 RX": "open_19_3_rx", "Open 19.3 SCALE": "open_19_3_scale",
        "Open 19.4 RX": "open_19_4_rx", "Open 19.4 SCALE": "open_19_4_scale",
        "Open 19.5 RX": "open_19_5_rx", "Open 19.5 SCALE": "open_19_5_scale",
        "Open 20.1 RX": "open_20_1_rx", "Open 20.1 SCALE": "open_20_1_scale",
        "Open 20.2 RX": "open_20_2_rx", "Open 20.2 SCALE": "open_20_2_scale",
        "Open 20.3 RX": "open_20_3_rx", "Open 20.3 SCALE": "open_20_3_scale",
        "Open 20.4 RX": "open_20_4_rx", "Open 20.4 SCALE": "open_20_4_scale",
        "Open 20.5 RX": "open_20_5_rx", "Open 20.5 SCALE": "open_20_5_scale",
        "Open 21.1": "open_21_1", "Open 21.2": "open_21_2", "Open 21.3": "open_21_3",
        "Open 21.4": "open_21_4",
        "Open 22.1 RX": "open_22_1_rx", "Open 22.1 SCALE": "open_22_1_scale",
        "Open 22.2 RX": "open_22_2_rx", "Open 22.2 SCALE": "open_22_2_scale",
        "Open 22.3 RX": "open_22_3_rx", "Open 22.3 SCALE": "open_22_3_scale",
        "Open 23.1 RX": "open_23_1_rx", "Open 23.1 SCALE": "open_23_1_scale",
        "Open 23.2A RX": "open_23_2a_rx", "Open 23.2A SCALE": "open_23_2a_scale",
        "Open 23.2B": "open_23_2b", "Open 23.3 RX": "open_23_3_rx",
        "Open 23.3 SCALE": "open_23_3_scale",
        "Open 24.1 RX": "open_24_1_rx", "Open 24.1 SCALE": "open_24_1_scale",
        "Open 24.2 RX": "open_24_2_rx", "Open 24.2 SCALE": "open_24_2_scale",
        "Open 24.3 RX": "open_24_3_rx", "Open 24.3 SCALE": "open_24_3_scale",
        "Open 25.1 RX": "open_25_1_rx", "Open 25.1 SCALE": "open_25_1_scale",
        "Open 25.2 RX": "open_25_2_rx", "Open 25.2 SCALE": "open_25_2_scale",
        "Open 25.3 RX": "open_25_3_rx", "Open 25.3 SCALE": "open_25_3_scale"
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
            return .init(target: .barbell, storageKey: key, value: .numeric(value), source: .movement, movementID: movementID(record))
        case "gymnastic":
            guard let key = gymnasticKeys[normalize(movement)], let value = textValue(record) else { return nil }
            return .init(target: .gymnastic, storageKey: key, value: .text(value), source: .movement, movementID: movementID(record))
        case "endurance":
            guard let key = enduranceKeys[normalize(movement)], let value = textValue(record) else { return nil }
            return .init(target: .endurance, storageKey: key, value: .text(value), source: .movement, movementID: movementID(record))
        default:
            return nil
        }
    }

    private static func map(_ record: TecnofitRecord, workoutDay: String) -> TecnofitMappedPersonalRecord? {
        guard let name = record.workoutDay else {
            return nil
        }
        if normalize(workoutDay) == "girls",
           let key = girlsKeys[normalize(name)],
           let value = girlsValue(record) {
            return .init(target: .girls, storageKey: key, value: .numeric(value), source: .workoutDay)
        }
        if isOpenWorkoutDay(workoutDay),
           let key = openKeys[normalize(name)],
           let value = textValue(record) {
            return .init(target: .open, storageKey: key, value: .text(value), source: .workoutDay)
        }
        if normalize(workoutDay) == "notables",
           let key = notablesKeys[normalize(name)],
           let value = textValue(record) {
            return .init(target: .notables, storageKey: key, value: .text(value), source: .workoutDay)
        }
        if normalize(workoutDay) == "heroes",
           let key = heroesKeys[normalize(name)],
           let value = textValue(record) {
            return .init(target: .heroes, storageKey: key, value: .text(value), source: .workoutDay)
        }
        return nil
    }

    private static func movementID(_ record: TecnofitRecord) -> String? {
        let value = record.movementId?.value.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }

    private static func isOpenWorkoutDay(_ value: String) -> Bool {
        let category = normalize(value)
        return category == "open" || category == "crossfit open" || category.hasPrefix("open ")
    }

    static func map(
        detail: TecnofitPersonalRecordDetailResponse,
        to record: TecnofitMappedPersonalRecord
    ) -> TecnofitMappedPersonalRecord? {
        guard let movementID = record.movementID?.trimmingCharacters(in: .whitespacesAndNewlines),
              !movementID.isEmpty else {
            return nil
        }

        let histories = detail.records.compactMap {
            detailHistory(
                from: $0,
                target: record.target,
                movementID: movementID,
                unit: detail.unit,
                resultType: detail.resultType
            )
        }
        guard !histories.isEmpty else { return nil }

        let current = currentValue(
            from: histories,
            detailLastRecord: detail.lastRecord?.value,
            originalValue: record.value,
            target: record.target
        )
        let currentValue: TecnofitPersonalRecordValue
        if record.target == .girls,
           let current,
           case .text(let value) = current.history.value,
           let numericValue = seconds(from: value) ?? flexibleDecimal(value) {
            currentValue = .numeric(numericValue)
        } else {
            currentValue = current?.history.value ?? record.value
        }
        return .init(
            target: record.target,
            storageKey: record.storageKey,
            value: currentValue,
            movementID: movementID,
            histories: histories.map(\.history),
            shouldImportCurrentValue: current != nil
        )
    }

    private struct DetailHistory {
        let history: TecnofitPersonalRecordHistory
        let sourceValues: [String]
        let isLastRecord: Bool
    }

    private static func detailHistory(
        from record: TecnofitPersonalRecordDetail,
        target: TecnofitPersonalRecordsTarget,
        movementID: String,
        unit: String?,
        resultType: String?
    ) -> DetailHistory? {
        guard let recordID = record.id?.value.trimmingCharacters(in: .whitespacesAndNewlines),
              !recordID.isEmpty,
              let date = detailDate(from: record.date) else {
            return nil
        }

        let value: TecnofitPersonalRecordValue
        let sourceValues: [String]
        switch target {
        case .barbell:
            guard let kilograms = barbellDetailValue(record, unit: unit) else { return nil }
            value = .numeric(kilograms)
            sourceValues = [record.recordKgs?.value, record.record?.value, record.recordPounds?.value]
                .compactMap { $0 }
        case .girls, .gymnastic, .endurance, .open, .notables, .heroes:
            guard let text = detailTextValue(record.record?.value, resultType: resultType) else { return nil }
            value = .text(text)
            sourceValues = [record.record?.value].compactMap { $0 }
        }

        return .init(
            history: .init(
                id: "tecnofit:\(movementID):\(recordID)",
                value: value,
                createdAt: date
            ),
            sourceValues: sourceValues,
            isLastRecord: isLastRecord(record.lastRecord?.value)
        )
    }

    private static func currentValue(
        from histories: [DetailHistory],
        detailLastRecord: String?,
        originalValue: TecnofitPersonalRecordValue,
        target: TecnofitPersonalRecordsTarget
    ) -> DetailHistory? {
        if let marked = histories.first(where: \.isLastRecord) {
            return marked
        }
        if let detailLastRecord = nonEmpty(detailLastRecord),
           let matched = histories.first(where: {
               $0.sourceValues.contains { valuesMatch($0, detailLastRecord) } ||
               valuesMatch(historyValueString($0.history.value), detailLastRecord)
           }) {
            return matched
        }
        return histories.first { valuesMatch($0.history.value, originalValue, target: target) }
    }

    private static func barbellDetailValue(
        _ record: TecnofitPersonalRecordDetail,
        unit: String?
    ) -> Double? {
        if let kilograms = flexibleDecimal(record.recordKgs?.value) {
            return kilograms
        }
        guard isKilogramUnit(unit) else { return nil }
        return flexibleDecimal(record.record?.value) ?? flexibleDecimal(record.recordPounds?.value)
    }

    private static func detailTextValue(_ rawValue: String?, resultType: String?) -> String? {
        guard let rawValue = nonEmpty(rawValue) else { return nil }
        if rawValue.contains(":") {
            guard seconds(from: rawValue) != nil else { return nil }
            return rawValue
        }
        guard let value = flexibleDecimal(rawValue) else { return nil }
        if isTimeResult(resultType) {
            guard value.rounded() == value else { return nil }
            return timeDisplay(seconds: Int(value))
        }
        return format(value)
    }

    private static func detailDate(from value: String?) -> Date? {
        guard let value = nonEmpty(value) else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        guard let date = formatter.date(from: value), formatter.string(from: date) == value else {
            return nil
        }
        return date
    }

    private static func isKilogramUnit(_ unit: String?) -> Bool {
        switch normalize(unit ?? "") {
        case "kg", "kgs", "kilogram", "kilograms", "kilograma", "kilogramas":
            return true
        default:
            return false
        }
    }

    private static func isTimeResult(_ resultType: String?) -> Bool {
        normalize(resultType ?? "").contains("time")
    }

    private static func isLastRecord(_ value: String?) -> Bool {
        switch normalize(value ?? "") {
        case "true", "yes", "sim":
            return true
        default:
            return false
        }
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        return value
    }

    private static func flexibleDecimal(_ value: String?) -> Double? {
        guard let value = nonEmpty(value),
              let decimal = Double(value.replacingOccurrences(of: ",", with: ".")),
              decimal.isFinite else {
            return nil
        }
        return decimal
    }

    private static func valuesMatch(_ left: String, _ right: String) -> Bool {
        if normalize(left) == normalize(right) { return true }
        if let left = flexibleDecimal(left), let right = flexibleDecimal(right) {
            return abs(left - right) < 0.000_001
        }
        if let left = seconds(from: left), let right = seconds(from: right) {
            return abs(left - right) < 0.000_001
        }
        return false
    }

    private static func valuesMatch(
        _ historyValue: TecnofitPersonalRecordValue,
        _ originalValue: TecnofitPersonalRecordValue,
        target: TecnofitPersonalRecordsTarget
    ) -> Bool {
        switch (historyValue, originalValue) {
        case (.numeric(let history), .numeric(let original)):
            return abs(history - original) < 0.000_001
        case (.text(let history), .text(let original)):
            return valuesMatch(history, original)
        case (.text(let history), .numeric(let original)) where target == .girls:
            guard let historical = seconds(from: history) ?? flexibleDecimal(history) else { return false }
            return abs(historical - original) < 0.000_001
        default:
            return false
        }
    }

    private static func historyValueString(_ value: TecnofitPersonalRecordValue) -> String {
        switch value {
        case .numeric(let number): format(number)
        case .text(let text): text
        }
    }

    private static func timeDisplay(seconds: Int) -> String {
        let hours = seconds / 3_600
        let minutes = (seconds % 3_600) / 60
        let remainingSeconds = seconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        }
        return String(format: "%d:%02d", minutes, remainingSeconds)
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
        return preview(records: mapped.records, unmatchedCount: mapped.unmatchedCount, defaults: defaults)
    }

    static func preview(
        records: [TecnofitMappedPersonalRecord],
        unmatchedCount: Int,
        defaults: UserDefaults = .standard
    ) -> TecnofitImportPreview {
        let existing = ExistingValues(defaults: defaults)
        var ready = [TecnofitMappedPersonalRecord]()
        var conflicts = 0

        for record in records {
            let currentValueExists = existing.hasValue(for: record.target, storageKey: record.storageKey)
            if record.shouldImportCurrentValue && currentValueExists {
                conflicts += 1
            }
            if (record.shouldImportCurrentValue && !currentValueExists && existing.canPersistHistories(for: record)) ||
                existing.hasNewHistory(for: record) {
                ready.append(record)
            }
        }

        return TecnofitImportPreview(
            recordsReady: ready.count,
            conflictsPreserved: conflicts,
            unmatchedSkipped: unmatchedCount,
            records: ready
        )
    }

    @MainActor
    @discardableResult
    static func apply(_ preview: TecnofitImportPreview, defaults: UserDefaults = .standard) -> Int {
        var existing = ExistingValues(defaults: defaults)
        var additions = 0

        for record in preview.records {
            if existing.add(record) {
                additions += 1
            }
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
        private var barbellHistory: [String: [BarbellHistoryEntry]] = [:]
        private var textHistory: [TecnofitPersonalRecordsTarget: [String: [TextHistoryEntry]]] = [:]
        private var validHistoryTargets: Set<TecnofitPersonalRecordsTarget> = []
        private var dirtyHistoryTargets: Set<TecnofitPersonalRecordsTarget> = []

        init(defaults: UserDefaults) {
            loadNumeric(.barbell, defaults: defaults)
            loadNumeric(.girls, defaults: defaults)
            loadText(.gymnastic, defaults: defaults)
            loadText(.endurance, defaults: defaults)
            loadText(.open, defaults: defaults)
            loadText(.notables, defaults: defaults)
            loadText(.heroes, defaults: defaults)
            loadBarbellHistory(defaults: defaults)
            loadTextHistory(.girls, defaults: defaults)
            loadTextHistory(.gymnastic, defaults: defaults)
            loadTextHistory(.endurance, defaults: defaults)
            loadTextHistory(.open, defaults: defaults)
            loadTextHistory(.notables, defaults: defaults)
            loadTextHistory(.heroes, defaults: defaults)
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

        func hasNewHistory(for record: TecnofitMappedPersonalRecord) -> Bool {
            guard validHistoryTargets.contains(record.target) else { return false }
            switch record.target {
            case .barbell:
                let existingIDs = Set(barbellHistory[record.storageKey, default: []].map(\.id))
                return record.histories.contains {
                    !($0.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) &&
                    !existingIDs.contains($0.id) &&
                    isFiniteNumericValue($0.value)
                }
            case .girls, .gymnastic, .endurance, .open, .notables, .heroes:
                let existingIDs = Set(textHistory[record.target]?[record.storageKey]?.map(\.id) ?? [])
                return record.histories.contains {
                    !($0.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) &&
                    !existingIDs.contains($0.id) &&
                    isNonEmptyTextValue($0.value)
                }
            }
        }

        func canPersistHistories(for record: TecnofitMappedPersonalRecord) -> Bool {
            record.histories.isEmpty || validHistoryTargets.contains(record.target)
        }

        mutating func add(_ record: TecnofitMappedPersonalRecord) -> Bool {
            var changed = false
            if record.shouldImportCurrentValue,
               !hasValue(for: record.target, storageKey: record.storageKey),
               canPersistHistories(for: record),
               insertCurrentValue(record) {
                changed = true
            }
            if appendHistories(from: record) {
                changed = true
            }
            return changed
        }

        private mutating func insertCurrentValue(_ record: TecnofitMappedPersonalRecord) -> Bool {
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

        private mutating func appendHistories(from record: TecnofitMappedPersonalRecord) -> Bool {
            guard validHistoryTargets.contains(record.target) else { return false }
            switch record.target {
            case .barbell:
                var entries = barbellHistory[record.storageKey, default: []]
                var existingIDs = Set(entries.map(\.id))
                for history in record.histories {
                    guard !history.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                          !existingIDs.contains(history.id),
                          case .numeric(let value) = history.value,
                          value.isFinite else {
                        continue
                    }
                    entries.append(.init(id: history.id, valueKg: value, createdAt: history.createdAt))
                    existingIDs.insert(history.id)
                }
                guard entries.count != barbellHistory[record.storageKey, default: []].count else { return false }
                barbellHistory[record.storageKey] = entries
            case .girls, .gymnastic, .endurance, .open, .notables, .heroes:
                var historiesByKey = textHistory[record.target, default: [:]]
                var entries = historiesByKey[record.storageKey, default: []]
                var existingIDs = Set(entries.map(\.id))
                for history in record.histories {
                    guard !history.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                          !existingIDs.contains(history.id),
                          case .text(let value) = history.value,
                          !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        continue
                    }
                    entries.append(.init(id: history.id, value: value, createdAt: history.createdAt))
                    existingIDs.insert(history.id)
                }
                guard entries.count != historiesByKey[record.storageKey, default: []].count else { return false }
                historiesByKey[record.storageKey] = entries
                textHistory[record.target] = historiesByKey
            }
            dirtyHistoryTargets.insert(record.target)
            return true
        }

        func save(to defaults: UserDefaults) {
            for target in dirtyTargets {
                let data: Data?
                switch target {
                case .barbell, .girls:
                    data = try? JSONEncoder().encode(numeric[target] ?? [:])
                case .gymnastic, .endurance, .open, .notables, .heroes:
                    data = try? JSONEncoder().encode(text[target] ?? [:])
                }
                if let data { defaults.set(data, forKey: target.valuesKey) }
            }
            for target in dirtyHistoryTargets {
                let data: Data?
                switch target {
                case .barbell:
                    data = try? JSONEncoder().encode(barbellHistory)
                case .girls, .gymnastic, .endurance, .open, .notables, .heroes:
                    data = try? JSONEncoder().encode(textHistory[target] ?? [:])
                }
                if let data { defaults.set(data, forKey: target.historyKey) }
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

        private mutating func loadBarbellHistory(defaults: UserDefaults) {
            guard let data = defaults.data(forKey: TecnofitPersonalRecordsTarget.barbell.historyKey), !data.isEmpty else {
                barbellHistory = [:]
                validHistoryTargets.insert(.barbell)
                return
            }
            guard let history = try? JSONDecoder().decode([String: [BarbellHistoryEntry]].self, from: data) else { return }
            barbellHistory = history
            validHistoryTargets.insert(.barbell)
        }

        private mutating func loadTextHistory(_ target: TecnofitPersonalRecordsTarget, defaults: UserDefaults) {
            guard let data = defaults.data(forKey: target.historyKey), !data.isEmpty else {
                textHistory[target] = [:]
                validHistoryTargets.insert(target)
                return
            }
            guard let history = try? JSONDecoder().decode([String: [TextHistoryEntry]].self, from: data) else { return }
            textHistory[target] = history
            validHistoryTargets.insert(target)
        }

        private func isFiniteNumericValue(_ value: TecnofitPersonalRecordValue) -> Bool {
            guard case .numeric(let number) = value else { return false }
            return number.isFinite
        }

        private func isNonEmptyTextValue(_ value: TecnofitPersonalRecordValue) -> Bool {
            guard case .text(let text) = value else { return false }
            return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private struct BarbellHistoryEntry: Codable {
        let id: String
        let valueKg: Double
        let createdAt: Date
    }

    private struct TextHistoryEntry: Codable {
        let id: String
        let value: String
        let createdAt: Date
    }
}
