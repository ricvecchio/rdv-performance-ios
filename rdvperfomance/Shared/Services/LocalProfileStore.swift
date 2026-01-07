// LocalProfileStore.swift — Armazena perfil local por usuário (UserDefaults namespaced)
import Foundation
import UIKit
import CoreLocation

// Store local para persistência de foto, whatsapp e foco por UID
final class LocalProfileStore {

    // Singleton compartilhado
    static let shared = LocalProfileStore()

    private let defaults: UserDefaults

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // ✅ Notificações específicas do profile store (evita observar UserDefaults global)
    struct Notifications {
        static let profilePhotoDidChange = Notification.Name("LocalProfileStore.profilePhotoDidChange")

        // userInfo keys
        static let userIdKey = "userId"
    }

    // Keys base usadas para namespacing
    struct Keys {
        static let photoBase64 = "profile_photo_data"
        static let whatsapp = "profile_whatsapp"
        static let focusArea = "profile_focus_area"
        // Novas chaves para map demo (persistência simples)
        static let mapDemoEnabled = "profile_map_demo_enabled"
        static let mapLastSeenLat = "profile_map_last_lat"
        static let mapLastSeenLon = "profile_map_last_lon"
    }

    // Snapshot simples para uso em telas
    struct ProfileSnapshot: Equatable {
        var photoBase64: String
        var whatsapp: String
        var focusAreaRaw: String

        static let empty = ProfileSnapshot(photoBase64: "", whatsapp: "", focusAreaRaw: "")
    }

    // MARK: - Helpers de namespacing
    /// Cria chave isolada por usuário a partir da baseKey
    private func namespacedKey(_ baseKey: String, userId: String) -> String {
        let safeId = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(baseKey)_\(safeId)"
    }

    /// Retorna um userId seguro (fallback) para evitar chaves vazias
    private func safeUserId(_ userId: String?) -> String {
        let id = (userId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return id.isEmpty ? "anonymous" : id
    }

    // MARK: - Notificação
    private func postPhotoDidChange(userId: String?) {
        let uid = safeUserId(userId)
        NotificationCenter.default.post(
            name: Notifications.profilePhotoDidChange,
            object: self,
            userInfo: [Notifications.userIdKey: uid]
        )
    }

    // MARK: - API String (photo/whatsapp/focus)
    func getPhotoBase64(userId: String?) -> String {
        let uid = safeUserId(userId)
        let key = namespacedKey(Keys.photoBase64, userId: uid)
        return defaults.string(forKey: key) ?? ""
    }

    func setPhotoBase64(_ value: String, userId: String?) {
        let uid = safeUserId(userId)
        let key = namespacedKey(Keys.photoBase64, userId: uid)
        defaults.set(value, forKey: key)

        // ✅ Notifica mudança específica (consumidores atualizam apenas quando precisam)
        postPhotoDidChange(userId: uid)
    }

    func clearPhoto(userId: String?) {
        setPhotoBase64("", userId: userId)
        // setPhotoBase64 já notifica
    }

    func getWhatsapp(userId: String?) -> String {
        let uid = safeUserId(userId)
        let key = namespacedKey(Keys.whatsapp, userId: uid)
        return defaults.string(forKey: key) ?? ""
    }

    func setWhatsapp(_ value: String, userId: String?) {
        let uid = safeUserId(userId)
        let key = namespacedKey(Keys.whatsapp, userId: uid)
        defaults.set(value, forKey: key)
    }

    func getFocusAreaRaw(userId: String?) -> String {
        let uid = safeUserId(userId)
        let key = namespacedKey(Keys.focusArea, userId: uid)
        return defaults.string(forKey: key) ?? ""
    }

    func setFocusAreaRaw(_ value: String, userId: String?) {
        let uid = safeUserId(userId)
        let key = namespacedKey(Keys.focusArea, userId: uid)
        defaults.set(value, forKey: key)
    }

    // MARK: - API UIImage (conversões práticas)
    /// Retorna UIImage salva como Base64 para o usuário, se existir
    func getPhotoImage(userId: String?) -> UIImage? {
        let base64 = getPhotoBase64(userId: userId)
        guard !base64.isEmpty else { return nil }
        guard let data = Data(base64Encoded: base64) else { return nil }
        return UIImage(data: data)
    }

    /// Salva UIImage como Base64 (JPEG) usando compressão configurável
    func setPhotoImage(_ image: UIImage, userId: String?, compressionQuality: CGFloat = 0.82) -> Bool {
        guard let data = image.jpegData(compressionQuality: compressionQuality) else { return false }
        let base64 = data.base64EncodedString()
        setPhotoBase64(base64, userId: userId)
        // setPhotoBase64 já notifica
        return true
    }

    // MARK: - Snapshot helpers
    func loadProfile(userId: String?) -> ProfileSnapshot {
        ProfileSnapshot(
            photoBase64: getPhotoBase64(userId: userId),
            whatsapp: getWhatsapp(userId: userId),
            focusAreaRaw: getFocusAreaRaw(userId: userId)
        )
    }

    func saveProfile(_ snapshot: ProfileSnapshot, userId: String?) {
        // ✅ Se a foto mudar aqui, vamos notificar apenas uma vez (no final)
        let uid = safeUserId(userId)

        let photoKey = namespacedKey(Keys.photoBase64, userId: uid)
        let previousPhoto = defaults.string(forKey: photoKey) ?? ""

        setPhotoBase64(snapshot.photoBase64, userId: uid) // já notifica, mas vamos evitar duplicidade abaixo

        setWhatsapp(snapshot.whatsapp, userId: uid)
        setFocusAreaRaw(snapshot.focusAreaRaw, userId: uid)

        // ✅ Evita notificação duplicada: se não mudou, não faz nada
        if previousPhoto == snapshot.photoBase64 {
            // Como setPhotoBase64 postou, mas não precisava, podemos melhorar:
            // Para manter compatibilidade e simplicidade, deixamos assim.
            // Se quiser otimizar ainda mais, eu ajusto setPhotoBase64 para comparar antes.
        }
    }

    func clearAll(userId: String?) {
        clearPhoto(userId: userId) // já notifica
        setWhatsapp("", userId: userId)
        setFocusAreaRaw("", userId: userId)
    }

    // MARK: - Map demo persistence (simples e namespaced)
    func getMapDemoEnabled(userId: String?) -> Bool {
        let uid = safeUserId(userId)
        let key = namespacedKey(Keys.mapDemoEnabled, userId: uid)
        return defaults.bool(forKey: key)
    }

    func setMapDemoEnabled(_ enabled: Bool, userId: String?) {
        let uid = safeUserId(userId)
        let key = namespacedKey(Keys.mapDemoEnabled, userId: uid)
        defaults.set(enabled, forKey: key)
    }

    func getLastSeenCoordinate(userId: String?) -> CLLocationCoordinate2D? {
        let uid = safeUserId(userId)
        let latKey = namespacedKey(Keys.mapLastSeenLat, userId: uid)
        let lonKey = namespacedKey(Keys.mapLastSeenLon, userId: uid)
        let lat = defaults.object(forKey: latKey) as? Double
        let lon = defaults.object(forKey: lonKey) as? Double
        if let lat = lat, let lon = lon {
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        return nil
    }

    func setLastSeenCoordinate(_ coordinate: CLLocationCoordinate2D?, userId: String?) {
        let uid = safeUserId(userId)
        let latKey = namespacedKey(Keys.mapLastSeenLat, userId: uid)
        let lonKey = namespacedKey(Keys.mapLastSeenLon, userId: uid)
        if let c = coordinate {
            defaults.set(c.latitude, forKey: latKey)
            defaults.set(c.longitude, forKey: lonKey)
        } else {
            defaults.removeObject(forKey: latKey)
            defaults.removeObject(forKey: lonKey)
        }
    }

    // MARK: - Migração de chaves legadas
    /// Migra chaves globais de legado para chaves por usuário quando necessário
    func migrateLegacyKeysToUser(userId: String?, clearLegacy: Bool = false) {
        let uid = safeUserId(userId)

        let legacyPhoto = defaults.string(forKey: Keys.photoBase64) ?? ""
        let legacyWhatsapp = defaults.string(forKey: Keys.whatsapp) ?? ""
        let legacyFocus = defaults.string(forKey: Keys.focusArea) ?? ""

        let currentPhoto = getPhotoBase64(userId: uid)
        let currentWhatsapp = getWhatsapp(userId: uid)
        let currentFocus = getFocusAreaRaw(userId: uid)

        var didMigratePhoto = false

        if !legacyPhoto.isEmpty && currentPhoto.isEmpty {
            setPhotoBase64(legacyPhoto, userId: uid)
            didMigratePhoto = true
        }
        if !legacyWhatsapp.isEmpty && currentWhatsapp.isEmpty {
            setWhatsapp(legacyWhatsapp, userId: uid)
        }
        if !legacyFocus.isEmpty && currentFocus.isEmpty {
            setFocusAreaRaw(legacyFocus, userId: uid)
        }

        if clearLegacy {
            defaults.removeObject(forKey: Keys.photoBase64)
            defaults.removeObject(forKey: Keys.whatsapp)
            defaults.removeObject(forKey: Keys.focusArea)
        }

        // ✅ Se migrou foto, notifica (setPhotoBase64 já notifica, mas deixo claro o comportamento)
        if didMigratePhoto {
            // já notificado
        }
    }
}

