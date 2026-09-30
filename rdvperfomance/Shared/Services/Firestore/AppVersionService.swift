import Foundation
import FirebaseFirestore

struct AppVersionConfig {
    let minimumVersion: AppVersion
    let latestVersion: AppVersion
    let forceUpdate: Bool
    let appStoreURL: String
    let message: String?

    init?(data: [String: Any]) {
        guard
            let minimumVersionValue = data["minimumVersion"] as? String,
            let minimumVersion = AppVersion(minimumVersionValue),
            let latestVersionValue = data["latestVersion"] as? String,
            let latestVersion = AppVersion(latestVersionValue),
            let forceUpdate = data["forceUpdate"] as? Bool,
            let appStoreURL = Self.optionalNonEmptyString(from: data["appStoreURL"]),
            minimumVersion <= latestVersion
        else {
            return nil
        }

        self.minimumVersion = minimumVersion
        self.latestVersion = latestVersion
        self.forceUpdate = forceUpdate
        self.appStoreURL = appStoreURL
        self.message = Self.optionalNonEmptyString(from: data["message"])
    }

    private static func optionalNonEmptyString(from value: Any?) -> String? {
        guard let string = value as? String else {
            return nil
        }

        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

struct AppVersion: Comparable {
    private let components: [Int]

    init?(_ value: String) {
        let parts = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: ".", omittingEmptySubsequences: false)

        let numericComponents = parts.compactMap { Int($0) }

        guard
            !parts.isEmpty,
            parts.allSatisfy({ !$0.isEmpty && $0.allSatisfy(\.isNumber) }),
            numericComponents.count == parts.count
        else {
            return nil
        }

        self.components = numericComponents
    }

    static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        let componentCount = max(lhs.components.count, rhs.components.count)

        for index in 0..<componentCount {
            let left = index < lhs.components.count ? lhs.components[index] : 0
            let right = index < rhs.components.count ? rhs.components[index] : 0

            if left != right {
                return left < right
            }
        }

        return false
    }

    static func == (lhs: AppVersion, rhs: AppVersion) -> Bool {
        let componentCount = max(lhs.components.count, rhs.components.count)

        for index in 0..<componentCount {
            let left = index < lhs.components.count ? lhs.components[index] : 0
            let right = index < rhs.components.count ? rhs.components[index] : 0

            if left != right {
                return false
            }
        }

        return true
    }
}

enum AppUpdateState {
    case checking
    case upToDate
    case optionalUpdate
    case forceUpdate(AppVersionConfig)
}

final class AppVersionService {
    private enum FirestorePath {
        static let collection = "app_config"
        static let document = "ios"
    }

    func updateState() async -> AppUpdateState {
        guard let installedVersionValue = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
              let installedVersion = AppVersion(installedVersionValue) else {
            log("A versão instalada não pôde ser lida.")
            return .upToDate
        }

        do {
            let snapshot = try await Firestore.firestore()
                .collection(FirestorePath.collection)
                .document(FirestorePath.document)
                .getDocument()

            guard snapshot.exists else {
                log("O documento app_config/ios não existe.")
                return .upToDate
            }

            guard let data = snapshot.data(), let config = AppVersionConfig(data: data) else {
                log("A configuração app_config/ios é inválida.")
                return .upToDate
            }

            if config.forceUpdate && installedVersion < config.minimumVersion {
                return .forceUpdate(config)
            }

            return installedVersion < config.latestVersion ? .optionalUpdate : .upToDate
        } catch {
            log("Não foi possível consultar app_config/ios: \(error.localizedDescription)")
            return .upToDate
        }
    }

    private func log(_ message: String) {
        #if DEBUG
        print("[AppVersionService] \(message)")
        #endif
    }
}
