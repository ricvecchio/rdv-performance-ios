//
//  LocalProfileStore.swift
//  rdvperfomance
//
//  Created to support per-user local profile persistence (photo/whatsapp/focusArea)
//  ✅ Isola os dados por usuário (UID) para evitar “vazar” foto/whats entre logins.
//
//  Coloque este arquivo em:
//  ./rdvperfomance/Shared/Services/LocalProfileStore.swift
//

import Foundation
import UIKit

// MARK: - LocalProfileStore
/// Store local (UserDefaults) para persistir informações de perfil por usuário.
///
/// Por padrão, você estava usando @AppStorage com chaves fixas:
/// - "profile_photo_data"
/// - "profile_whatsapp"
/// - "profile_focus_area"
///
/// Isso faz com que TODOS os usuários compartilhem os mesmos valores.
///
/// ✅ Solução: usar chaves "namespaced" por userId (uid).
/// Ex.: "profile_photo_data_<uid>", "profile_whatsapp_<uid>", etc.
///
/// Observação:
/// - Este store NÃO depende de Firebase diretamente.
/// - Você deve fornecer o userId (uid) a partir do AppSession (ou equivalente).
final class LocalProfileStore {

    // MARK: - Singleton (simples e prático)
    static let shared = LocalProfileStore()

    private let defaults: UserDefaults

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Tipos

    struct Keys {
        static let photoBase64 = "profile_photo_data"
        static let whatsapp = "profile_whatsapp"
        static let focusArea = "profile_focus_area"
    }

    struct ProfileSnapshot: Equatable {
        var photoBase64: String
        var whatsapp: String
        var focusAreaRaw: String

        static let empty = ProfileSnapshot(photoBase64: "", whatsapp: "", focusAreaRaw: "")
    }

    // MARK: - Helpers (namespacing)

    /// Cria uma chave do UserDefaults isolada por usuário.
    /// - Ex.: baseKey="profile_photo_data", userId="abc" => "profile_photo_data_abc"
    private func namespacedKey(_ baseKey: String, userId: String) -> String {
        // evita espaços / caracteres estranhos na chave
        let safeId = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(baseKey)_\(safeId)"
    }

    /// (Opcional) quando não houver userId válido, usamos um "bucket" padrão.
    /// Isso ajuda a evitar crash e mantém comportamento previsível.
    private func safeUserId(_ userId: String?) -> String {
        let id = (userId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return id.isEmpty ? "anonymous" : id
    }

    // MARK: - Public API (String)

    func getPhotoBase64(userId: String?) -> String {
        let uid = safeUserId(userId)
        let key = namespacedKey(Keys.photoBase64, userId: uid)
        return defaults.string(forKey: key) ?? ""
    }

    func setPhotoBase64(_ value: String, userId: String?) {
        let uid = safeUserId(userId)
        let key = namespacedKey(Keys.photoBase64, userId: uid)
        defaults.set(value, forKey: key)
    }

    func clearPhoto(userId: String?) {
        setPhotoBase64("", userId: userId)
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

    // MARK: - Public API (UIImage)

    /// Converte e retorna a foto salva do usuário como UIImage (se existir).
    func getPhotoImage(userId: String?) -> UIImage? {
        let base64 = getPhotoBase64(userId: userId)
        guard !base64.isEmpty else { return nil }
        guard let data = Data(base64Encoded: base64) else { return nil }
        return UIImage(data: data)
    }

    /// Salva uma UIImage como Base64 (JPEG) por usuário.
    /// - compressionQuality padrão alinhado ao seu EditProfileView (0.82)
    func setPhotoImage(_ image: UIImage, userId: String?, compressionQuality: CGFloat = 0.82) -> Bool {
        guard let data = image.jpegData(compressionQuality: compressionQuality) else { return false }
        let base64 = data.base64EncodedString()
        setPhotoBase64(base64, userId: userId)
        return true
    }

    // MARK: - Snapshot (útil para telas)

    func loadProfile(userId: String?) -> ProfileSnapshot {
        ProfileSnapshot(
            photoBase64: getPhotoBase64(userId: userId),
            whatsapp: getWhatsapp(userId: userId),
            focusAreaRaw: getFocusAreaRaw(userId: userId)
        )
    }

    func saveProfile(_ snapshot: ProfileSnapshot, userId: String?) {
        setPhotoBase64(snapshot.photoBase64, userId: userId)
        setWhatsapp(snapshot.whatsapp, userId: userId)
        setFocusAreaRaw(snapshot.focusAreaRaw, userId: userId)
    }

    func clearAll(userId: String?) {
        clearPhoto(userId: userId)
        setWhatsapp("", userId: userId)
        setFocusAreaRaw("", userId: userId)
    }

    // MARK: - Migração (uma vez)
    /// Migra chaves antigas (globais) -> chaves por usuário.
    ///
    /// Use quando você implementar a mudança para UID.
    /// Assim, o usuário atual não “perde” a foto/whats que já estava salva.
    ///
    /// - Atenção: após migrar, você pode optar por limpar as chaves globais.
    func migrateLegacyKeysToUser(userId: String?, clearLegacy: Bool = false) {
        let uid = safeUserId(userId)

        let legacyPhoto = defaults.string(forKey: Keys.photoBase64) ?? ""
        let legacyWhatsapp = defaults.string(forKey: Keys.whatsapp) ?? ""
        let legacyFocus = defaults.string(forKey: Keys.focusArea) ?? ""

        // só migra se existir algo no legado e ainda não houver valor por usuário
        let currentPhoto = getPhotoBase64(userId: uid)
        let currentWhatsapp = getWhatsapp(userId: uid)
        let currentFocus = getFocusAreaRaw(userId: uid)

        if !legacyPhoto.isEmpty && currentPhoto.isEmpty {
            setPhotoBase64(legacyPhoto, userId: uid)
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
    }
}

