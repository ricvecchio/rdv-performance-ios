import Foundation

struct TecnofitAuthenticationResponse: Decodable {
    let token: String
}

struct TecnofitProfileResponse: Decodable {
    let customer: TecnofitCustomer
}

struct TecnofitCustomer: Decodable {
    let companies: [TecnofitCompany]
}

struct TecnofitCompany: Decodable {
    let id: TecnofitIdentifier
    let name: String
    let hasAccess: Bool
}

struct TecnofitPersonalRecordsResponse: Decodable {
    let unit: String?
    let modalities: [TecnofitModality]
    let workoutDay: [TecnofitWorkoutDay]

    private enum CodingKeys: String, CodingKey {
        case unit, modalities, workoutDay
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        unit = try container.decodeIfPresent(String.self, forKey: .unit)
        modalities = try container.decodeIfPresent([TecnofitModality].self, forKey: .modalities) ?? []
        workoutDay = try container.decodeIfPresent([TecnofitWorkoutDay].self, forKey: .workoutDay) ?? []
    }
}

struct TecnofitModality: Decodable {
    let modalityId: TecnofitIdentifier?
    let modality: String
    let personalRecords: [TecnofitRecord]
}

struct TecnofitWorkoutDay: Decodable {
    let workoutDayId: TecnofitIdentifier?
    let workoutDay: String
    let personalRecords: [TecnofitRecord]
}

struct TecnofitRecord: Decodable {
    let movementId: TecnofitIdentifier?
    let movement: String?
    let workoutDayId: TecnofitIdentifier?
    let workoutDay: String?
    let resultType: String?
    let customerId: TecnofitIdentifier?
    let companyId: TecnofitIdentifier?
    let decimalRecord: String?
    let timeRecord: String?
    let poundsRecord: String?
}

struct TecnofitFlexibleString: Decodable, Equatable {
    let value: String

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let boolean = try? container.decode(Bool.self) {
            value = boolean ? "true" : "false"
        } else if let integer = try? container.decode(Int.self) {
            value = String(integer)
        } else if let decimal = try? container.decode(Double.self) {
            value = String(decimal)
        } else {
            throw DecodingError.typeMismatch(
                String.self,
                .init(codingPath: decoder.codingPath, debugDescription: "Expected a Tecnofit string or number.")
            )
        }
    }
}

struct TecnofitPersonalRecordDetailResponse: Decodable {
    let customerId: TecnofitIdentifier?
    let movementId: TecnofitIdentifier?
    let movement: String?
    let resultType: String?
    let unit: String?
    let lastRecord: TecnofitFlexibleString?
    let records: [TecnofitPersonalRecordDetail]

    private enum CodingKeys: String, CodingKey {
        case customerId, movementId, movement, resultType, unit, lastRecord, records
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        customerId = try container.decodeIfPresent(TecnofitIdentifier.self, forKey: .customerId)
        movementId = try container.decodeIfPresent(TecnofitIdentifier.self, forKey: .movementId)
        movement = try container.decodeIfPresent(String.self, forKey: .movement)
        resultType = try container.decodeIfPresent(String.self, forKey: .resultType)
        unit = try container.decodeIfPresent(String.self, forKey: .unit)
        lastRecord = try container.decodeIfPresent(TecnofitFlexibleString.self, forKey: .lastRecord)
        records = try container.decodeIfPresent([TecnofitPersonalRecordDetail].self, forKey: .records) ?? []
    }
}

struct TecnofitPersonalRecordDetailEnvelope: Decodable {
    let movement: TecnofitPersonalRecordDetailResponse
}

struct TecnofitPersonalRecordDetail: Decodable {
    let id: TecnofitIdentifier?
    let record: TecnofitFlexibleString?
    let recordKgs: TecnofitFlexibleString?
    let recordPounds: TecnofitFlexibleString?
    let date: String?
    let lastRecord: TecnofitFlexibleString?
}

struct TecnofitIdentifier: Decodable, Equatable {
    let value: String

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let integer = try? container.decode(Int.self) {
            value = String(integer)
        } else if let decimal = try? container.decode(Double.self) {
            value = String(decimal)
        } else {
            throw DecodingError.typeMismatch(
                String.self,
                .init(codingPath: decoder.codingPath, debugDescription: "Expected a Tecnofit identifier.")
            )
        }
    }
}

enum TecnofitPersonalRecordsTarget: Hashable {
    case barbell
    case gymnastic
    case endurance
    case girls
    case open

    var valuesKey: String {
        switch self {
        case .barbell: "student_pr_barbell_values_v1"
        case .gymnastic: "student_pr_gymnastic_values_v1"
        case .endurance: "student_pr_endurance_values_v1"
        case .girls: "student_pr_girls_values_v1"
        case .open: "student_pr_open_values_v1"
        }
    }

    var historyKey: String {
        switch self {
        case .barbell: "student_pr_barbell_history_v1"
        case .gymnastic: "student_pr_gymnastic_history_v1"
        case .endurance: "student_pr_endurance_history_v1"
        case .girls: "student_pr_girls_history_v1"
        case .open: "student_pr_open_history_v1"
        }
    }
}

enum TecnofitPersonalRecordValue: Equatable {
    case numeric(Double)
    case text(String)
}

struct TecnofitPersonalRecordHistory: Equatable {
    let id: String
    let value: TecnofitPersonalRecordValue
    let createdAt: Date
}

struct TecnofitMappedPersonalRecord: Equatable {
    let target: TecnofitPersonalRecordsTarget
    let storageKey: String
    let value: TecnofitPersonalRecordValue
    let movementID: String?
    let histories: [TecnofitPersonalRecordHistory]
    let shouldImportCurrentValue: Bool

    init(
        target: TecnofitPersonalRecordsTarget,
        storageKey: String,
        value: TecnofitPersonalRecordValue,
        movementID: String? = nil,
        histories: [TecnofitPersonalRecordHistory] = [],
        shouldImportCurrentValue: Bool = true
    ) {
        self.target = target
        self.storageKey = storageKey
        self.value = value
        self.movementID = movementID
        self.histories = histories
        self.shouldImportCurrentValue = shouldImportCurrentValue
    }
}

struct TecnofitImportPreview: Equatable {
    let recordsReady: Int
    let conflictsPreserved: Int
    let unmatchedSkipped: Int
    let records: [TecnofitMappedPersonalRecord]
}
