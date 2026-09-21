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

    var valuesKey: String {
        switch self {
        case .barbell: "student_pr_barbell_values_v1"
        case .gymnastic: "student_pr_gymnastic_values_v1"
        case .endurance: "student_pr_endurance_values_v1"
        case .girls: "student_pr_girls_values_v1"
        }
    }
}

enum TecnofitPersonalRecordValue: Equatable {
    case numeric(Double)
    case text(String)
}

struct TecnofitMappedPersonalRecord: Equatable {
    let target: TecnofitPersonalRecordsTarget
    let storageKey: String
    let value: TecnofitPersonalRecordValue
}

struct TecnofitImportPreview: Equatable {
    let recordsReady: Int
    let conflictsPreserved: Int
    let unmatchedSkipped: Int
    let records: [TecnofitMappedPersonalRecord]
}
