// Tela para editar foto de perfil, WhatsApp e área de foco
import SwiftUI
import PhotosUI
import UIKit

private enum ProfilePhotoProcessingError: LocalizedError {
    case unableToProcess

    var errorDescription: String? {
        "Não foi possível processar a foto selecionada. Escolha outra imagem e tente novamente."
    }
}

struct EditProfileView: View {

    @Binding var path: [AppRoute]
    @EnvironmentObject private var session: AppSession

    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var previewImage: UIImage? = nil
    @State private var isLoadingImage: Bool = false
    @State private var hasNewPhoto: Bool = false
    @State private var showPhotoPicker: Bool = false
    @State private var showAvatarPicker: Bool = false

    // ✅ Armazena apenas dígitos normalizados (ex.: "11988888888")
    @State private var whatsappDigits: String = ""
    @State private var focusAreaDraft: FocusAreaDTO = .CROSSFIT
    @State private var userName: String = ""
    @State private var userEmail: String = ""
    @State private var crefDraft: String = ""
    @State private var bioDraft: String = ""

    // Referência original para detectar alterações pendentes
    @State private var originalWhatsappDigits: String = ""
    @State private var originalUserName: String = ""
    @State private var originalFocusArea: FocusAreaDTO = .CROSSFIT
    @State private var originalCref: String = ""
    @State private var originalBio: String = ""

    @State private var isSaving: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    // ✅ FocusState para fechar o teclado do campo de telefone
    @FocusState private var phoneFieldFocused: Bool

    private let textSecondary = Color.white.opacity(0.60)
    private let lineColor = Color.white.opacity(0.35)

    private let contentMaxWidth: CGFloat = 380

    private let studentFocusOptions: [FocusAreaDTO] = [.CROSSFIT, .GYM, .HOME]

    private static let maxProfilePhotoBase64Bytes = 800_000
    private static let profilePhotoDimensions: [CGFloat] = [1024, 800, 640]
    private static let compressionQualities: [CGFloat] = [0.82, 0.72, 0.62, 0.52, 0.42]

    private var currentUid: String? { session.currentUid }
    private let repository: FirestoreRepository = .shared

    private var storedImageForUser: UIImage? {
        LocalProfileStore.shared.getPhotoImage(userId: currentUid)
    }

    // MARK: - Estado do formulário

    /// Telefone é válido se estiver vazio, com 10 ou com 11 dígitos.
    private var isPhoneValid: Bool {
        BrazilianPhoneFormatter.isValid(whatsappDigits)
    }

    /// Existem alterações pendentes em relação ao estado original.
    private var hasChanges: Bool {
        userName.trimmingCharacters(in: .whitespacesAndNewlines) != originalUserName ||
        whatsappDigits != originalWhatsappDigits ||
        focusAreaDraft != originalFocusArea ||
        crefDraft != originalCref ||
        bioDraft != originalBio ||
        hasNewPhoto
    }

    /// Botão Salvar fica habilitado quando há alterações válidas e não está salvando.
    private var canSave: Bool {
        !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        isPhoneValid &&
        hasChanges &&
        !isSaving
    }

    // Interface principal com avatar, formulário e ações
    var body: some View {
        ZStack {

            Image("rdv_fundo")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {

                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)

                ScrollView(showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 0)

                        VStack(spacing: 16) {

                            avatarCard()
                            formCard()
                            photoAvatarButton()
                            actionButtons()

                            if showError {
                                Text(errorMessage)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.95))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.red.opacity(0.25))
                                    .cornerRadius(12)
                            }

                            Color.clear.frame(height: 18)
                        }
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        Spacer(minLength: 0)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
        .id(session.currentUid ?? "anonymous")
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {

            ToolbarItem(placement: .topBarLeading) {
                Button { pop() } label: {
                    ZStack {
                        Color.clear
                            .frame(width: 44, height: 44)

                        Image(systemName: "chevron.left")
                            .foregroundColor(.green)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("Editar Perfil")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        // ✅ Botão "Concluir" na toolbar do teclado para fechar o .phonePad
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Concluir") {
                    phoneFieldFocused = false
                }
            }
        }
        .onAppear {
            Task { await loadProfile() }
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            Task { await loadImage(from: newItem) }
        }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .sheet(isPresented: $showAvatarPicker) {
            AvatarPickerView { image in
                previewImage = image
                hasNewPhoto = true
            }
        }
    }

    // Retorna card com avatar e descrição
    private func avatarCard() -> some View {
        VStack(spacing: 12) {

            ZStack {
                avatarView()
                    .frame(width: 112, height: 112)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))

                if isLoadingImage {
                    ProgressView()
                        .tint(.white.opacity(0.9))
                }
            }

            Text("Foto de Perfil")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))

        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    // Retorna card com campos do formulário
    private func formCard() -> some View {
        VStack(spacing: 18) {
            readOnlyRow(title: "E-mail", value: userEmail)
            nameField()

            // ✅ Campo de telefone com máscara brasileira e FocusState
            VStack(alignment: .leading, spacing: 6) {
                Text("WhatsApp (opcional)")
                    .font(.system(size: 14))
                    .foregroundColor(textSecondary)

                TextField("", text: Binding(
                    get: { BrazilianPhoneFormatter.format(whatsappDigits) },
                    set: { whatsappDigits = BrazilianPhoneFormatter.normalize($0) }
                ))
                .foregroundColor(.white.opacity(0.92))
                .font(.system(size: 16))
                .keyboardType(.phonePad)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .focused($phoneFieldFocused)

                Rectangle()
                    .fill(lineColor)
                    .frame(height: 1)

                // Indicador de validação (apenas quando há dígitos e está inválido)
                if !whatsappDigits.isEmpty && !isPhoneValid {
                    Text("Número incompleto (mínimo 10 dígitos)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.yellow.opacity(0.85))
                }
            }

            pickerRow(
                title: "Área de foco",
                selection: $focusAreaDraft,
                options: studentFocusOptions,
                displayText: displayTextForFocusArea
            )

            if session.isTrainer {
                UnderlineTextField(
                    title: "CREF (opcional)",
                    text: $crefDraft,
                    isSecure: false,
                    showPassword: .constant(false),
                    lineColor: lineColor,
                    textColor: .white,
                    placeholderColor: textSecondary
                )

                multilineBioField()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    private func photoAvatarButton() -> some View {
        Menu {
            Button {
                showPhotoPicker = true
            } label: {
                Label("Escolher foto da biblioteca", systemImage: "photo")
            }
            Button {
                showAvatarPicker = true
            } label: {
                Label("Escolher Avatar", systemImage: "person.crop.circle")
            }
        } label: {
            HStack {
                Spacer()
                HStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text(isLoadingImage ? "Carregando..." : "Adicionar foto ou Avatar")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))
                Spacer()
            }
            .padding(.vertical, 14)
            .background(Theme.Colors.primaryGreen.opacity(0.18))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.Colors.primaryGreen.opacity(0.30), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoadingImage)
    }

    private func actionButtons() -> some View {
        VStack(spacing: 10) {

            Button {
                Task { await saveAllAndSync() }
            } label: {
                HStack {
                    Spacer()
                    HStack(spacing: 10) {
                        if isSaving {
                            ProgressView()
                                .tint(.white.opacity(0.9))
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                        }

                        Text(isSaving ? "Salvando..." : "Salvar")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
                    Spacer()
                }
                .padding(.vertical, 14)
                .background(canSave ? Theme.Colors.primaryGreen.opacity(0.18) : Color.white.opacity(0.10))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            canSave ? Theme.Colors.primaryGreen.opacity(0.35) : Color.white.opacity(0.12),
                            lineWidth: 1
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(!canSave)

            Button {
                Task { await clearPhotoOnlyAndSync() }
            } label: {
                Text("Remover foto")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .underline()
                    .padding(.top, 2)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    // Escolhe imagem correta para exibir (preview > armazenada > padrão)
    @ViewBuilder
    private func avatarView() -> some View {
        if let previewImage {
            Image(uiImage: previewImage)
                .resizable()
                .scaledToFill()
        } else if let stored = storedImageForUser {
            Image(uiImage: stored)
                .resizable()
                .scaledToFill()
        } else {
            Image("rdv_user_default")
                .resizable()
                .scaledToFill()
        }
    }

    private func readOnlyRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(textSecondary)

            Text(value)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.45))
                .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle()
                .fill(lineColor)
                .frame(height: 1)
        }
    }

    private func nameField() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Nome")
                .font(.system(size: 14))
                .foregroundColor(textSecondary)

            TextField("", text: $userName)
                .foregroundColor(.white.opacity(0.92))
                .font(.system(size: 16))
                .textContentType(.name)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled(false)

            Rectangle()
                .fill(lineColor)
                .frame(height: 1)
        }
    }

    private func multilineBioField() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bio (opcional)")
                .font(.system(size: 14))
                .foregroundColor(textSecondary)

            TextEditor(text: $bioDraft)
                .frame(height: 88)
                .foregroundColor(.white)
                .font(.system(size: 16))
                .background(Color.clear)
                .scrollContentBackground(.hidden)
                .overlay(
                    Rectangle()
                        .fill(lineColor)
                        .frame(height: 1),
                    alignment: .bottom
                )
        }
    }

    // Carrega o perfil remoto e usa o armazenamento local apenas para dados legados.
    private func loadProfile() async {
        guard let uid = currentUid?.trimmingCharacters(in: .whitespacesAndNewlines), !uid.isEmpty else {
            whatsappDigits = ""
            originalWhatsappDigits = ""
            focusAreaDraft = .CROSSFIT
            originalFocusArea = .CROSSFIT
            userName = ""
            originalUserName = ""
            userEmail = ""
            crefDraft = ""
            originalCref = ""
            bioDraft = ""
            originalBio = ""
            previewImage = nil
            hasNewPhoto = false
            return
        }

        let localPhone = LocalProfileStore.shared.getWhatsapp(userId: uid)
        let localFocusArea = LocalProfileStore.shared.getFocusAreaRaw(userId: uid)

        var didLoadRemoteProfile = false
        do {
            let user = try await repository.getUser(uid: uid)
            let remotePhone = (user?.phone ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let remoteFocusArea = (user?.focusArea ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let phone = remotePhone.isEmpty ? localPhone : remotePhone
            let focusArea = remoteFocusArea.isEmpty ? localFocusArea : remoteFocusArea
            let area = FocusAreaDTO(rawValue: focusArea) ?? .CROSSFIT

            userName = user?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            originalUserName = userName
            userEmail = user?.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
            whatsappDigits = BrazilianPhoneFormatter.normalize(phone)
            originalWhatsappDigits = whatsappDigits
            focusAreaDraft = area
            originalFocusArea = area
            crefDraft = (user?.cref ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            originalCref = crefDraft
            bioDraft = (user?.bio ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            originalBio = bioDraft
            didLoadRemoteProfile = true
        } catch {
            presentError((error as NSError).localizedDescription)
            let normalized = BrazilianPhoneFormatter.normalize(localPhone)
            whatsappDigits = normalized
            originalWhatsappDigits = normalized
            let area = FocusAreaDTO(rawValue: localFocusArea) ?? .CROSSFIT
            focusAreaDraft = area
            originalFocusArea = area
        }

        hasNewPhoto = false

        if previewImage == nil, let img = LocalProfileStore.shared.getPhotoImage(userId: currentUid) {
            previewImage = img
        }

        if didLoadRemoteProfile {
            showError = false
            errorMessage = ""
        }
    }

    // ✅ Salva local + sincroniza foto no Firestore (para o professor enxergar na lista)
    private func saveAllAndSync() async {
        guard !isSaving else { return }
        isSaving = true
        phoneFieldFocused = false  // Fecha teclado antes de salvar
        defer { isSaving = false }

        do {
            guard let uid = currentUid?.trimmingCharacters(in: .whitespacesAndNewlines), !uid.isEmpty else {
                throw FirestoreRepositoryError.missingUserId
            }
            try await repository.updateUserProfile(
                uid: uid,
                name: userName,
                phone: whatsappDigits.isEmpty ? nil : whatsappDigits,
                cref: session.isTrainer ? crefDraft : nil,
                bio: session.isTrainer ? bioDraft : nil,
                focusArea: focusAreaDraft.rawValue
            )
            try await savePhotoIfNeededAndSync()
            await MainActor.run {
                saveWhatsapp()
                saveFocusArea()
                showError = false
                errorMessage = ""
                // Atualiza referência original para refletir dados salvos
                originalWhatsappDigits = whatsappDigits
                originalUserName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
                originalFocusArea = focusAreaDraft
                originalCref = crefDraft
                originalBio = bioDraft
                hasNewPhoto = false
            }
            session.userName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
            pop()
        } catch {
            presentError((error as NSError).localizedDescription)
        }
    }

    // ✅ Persiste WhatsApp como dígitos normalizados
    private func saveWhatsapp() {
        LocalProfileStore.shared.setWhatsapp(whatsappDigits, userId: currentUid)
    }

    // Persiste área de foco localmente
    private func saveFocusArea() {
        LocalProfileStore.shared.setFocusAreaRaw(focusAreaDraft.rawValue, userId: currentUid)
    }

    // ✅ Persiste foto localmente e no Firestore (base64) — apenas se há nova foto
    private func savePhotoIfNeededAndSync() async throws {
        guard hasNewPhoto else { return }  // Sem nova foto, pula escrita desnecessária

        guard let uid = currentUid?.trimmingCharacters(in: .whitespacesAndNewlines), !uid.isEmpty else {
            throw FirestoreRepositoryError.missingUserId
        }

        guard let previewImage else { return }

        let processedPhoto = Self.makeProfilePhoto(from: previewImage)

        guard let processedPhoto else {
            throw ProfilePhotoProcessingError.unableToProcess
        }

        // Persiste exatamente a versão aprovada para o Firestore.
        LocalProfileStore.shared.setPhotoBase64(processedPhoto.base64, userId: currentUid)
        self.previewImage = processedPhoto.image

        try await FirestoreRepository.shared.setUserPhotoBase64(
            uid: uid,
            photoBase64: processedPhoto.base64
        )
    }

    // ✅ Remove foto local + remove do Firestore
    private func clearPhotoOnlyAndSync() async {
        guard let uid = currentUid?.trimmingCharacters(in: .whitespacesAndNewlines), !uid.isEmpty else {
            presentError("Não foi possível identificar o usuário para remover a foto.")
            return
        }

        previewImage = nil
        selectedItem = nil
        LocalProfileStore.shared.clearPhoto(userId: currentUid)

        do {
            try await FirestoreRepository.shared.clearUserPhotoBase64(uid: uid)
            await MainActor.run {
                showError = false
                errorMessage = ""
            }
        } catch {
            presentError((error as NSError).localizedDescription)
        }
    }

    // Carrega imagem selecionada do PhotosPicker
    private func loadImage(from item: PhotosPickerItem) async {
        isLoadingImage = true
        defer { isLoadingImage = false }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                await MainActor.run {
                    self.previewImage = uiImage
                    self.hasNewPhoto = true   // ✅ Marca foto como alterada
                    self.showError = false
                    self.errorMessage = ""
                }
            } else {
                presentError("Não foi possível carregar a imagem selecionada.")
            }
        } catch {
            presentError("Erro ao carregar imagem: \(error.localizedDescription)")
        }
    }

    // Exibe mensagem de erro na interface
    private func presentError(_ message: String) {
        Task { @MainActor in
            self.showError = true
            self.errorMessage = message
        }
    }

    private static func makeProfilePhoto(from image: UIImage) -> (image: UIImage, base64: String)? {
        for dimension in profilePhotoDimensions {
            guard let resizedImage = normalizedAndResizedImage(image, maximumDimension: dimension) else {
                return nil
            }

            for quality in compressionQualities {
                guard let data = resizedImage.jpegData(compressionQuality: quality) else {
                    continue
                }

                let base64 = data.base64EncodedString()
                if base64.utf8.count <= maxProfilePhotoBase64Bytes {
                    return (resizedImage, base64)
                }
            }
        }

        return nil
    }

    private static func normalizedAndResizedImage(
        _ image: UIImage,
        maximumDimension: CGFloat
    ) -> UIImage? {
        let sourceSize = image.size
        guard sourceSize.width > 0, sourceSize.height > 0 else {
            return nil
        }

        let scale = min(maximumDimension / max(sourceSize.width, sourceSize.height), 1)
        let targetSize = CGSize(
            width: (sourceSize.width * scale).rounded(.down),
            height: (sourceSize.height * scale).rounded(.down)
        )
        guard targetSize.width > 0, targetSize.height > 0 else {
            return nil
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    // Remove a última rota da pilha de navegação
    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    // Converte FocusAreaDTO em texto amigável
    private func displayTextForFocusArea(_ opt: FocusAreaDTO) -> String {
        switch opt {
        case .CROSSFIT: return "Crossfit"
        case .GYM: return "Academia"
        case .HOME: return "Treinos em Casa"
        }
    }

    private struct AvatarPickerView: View {
        private enum HairStyle {
            case bald
            case short
            case long
            case curly
        }

        private struct PersonStyle {
            let skinColor: UIColor
            let hairColor: UIColor
            let shirtColor: UIColor
            let hairStyle: HairStyle
            let beardColor: UIColor?
            let wearsGlasses: Bool
        }

        private struct AvatarOption: Identifiable {
            let id: String
            let color: UIColor
            let symbolName: String?
            let person: PersonStyle?

            init(symbolName: String, color: UIColor) {
                self.id = symbolName
                self.color = color
                self.symbolName = symbolName
                self.person = nil
            }

            init(id: String, color: UIColor, person: PersonStyle) {
                self.id = id
                self.color = color
                self.symbolName = nil
                self.person = person
            }

            func image() -> UIImage {
                let size = CGSize(width: 512, height: 512)
                let format = UIGraphicsImageRendererFormat()
                format.scale = 1
                format.opaque = true

                return UIGraphicsImageRenderer(size: size, format: format).image { _ in
                    color.setFill()
                    UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).fill()

                    if let person {
                        drawPerson(person)
                    } else if let symbolName {
                        let configuration = UIImage.SymbolConfiguration(pointSize: 260, weight: .medium)
                        let symbol = UIImage(systemName: symbolName, withConfiguration: configuration)?
                            .withTintColor(.white, renderingMode: .alwaysOriginal)
                        symbol?.draw(in: CGRect(x: 126, y: 126, width: 260, height: 260))
                    }
                }
            }

            private func drawPerson(_ person: PersonStyle) {
                let shoulderRect = CGRect(x: 78, y: 342, width: 356, height: 220)
                person.shirtColor.setFill()
                UIBezierPath(roundedRect: shoulderRect, cornerRadius: 150).fill()

                if case .long = person.hairStyle {
                    person.hairColor.setFill()
                    UIBezierPath(roundedRect: CGRect(x: 126, y: 106, width: 260, height: 290), cornerRadius: 118).fill()
                }

                person.skinColor.setFill()
                UIBezierPath(roundedRect: CGRect(x: 218, y: 278, width: 76, height: 98), cornerRadius: 26).fill()
                UIBezierPath(ovalIn: CGRect(x: 151, y: 104, width: 210, height: 246)).fill()

                switch person.hairStyle {
                case .bald:
                    break
                case .short:
                    person.hairColor.setFill()
                    UIBezierPath(roundedRect: CGRect(x: 150, y: 92, width: 212, height: 118), cornerRadius: 84).fill()
                    person.skinColor.setFill()
                    UIBezierPath(ovalIn: CGRect(x: 174, y: 145, width: 164, height: 178)).fill()
                case .long:
                    person.hairColor.setFill()
                    UIBezierPath(roundedRect: CGRect(x: 144, y: 90, width: 224, height: 150), cornerRadius: 94).fill()
                    person.skinColor.setFill()
                    UIBezierPath(ovalIn: CGRect(x: 168, y: 148, width: 176, height: 174)).fill()
                case .curly:
                    person.hairColor.setFill()
                    for x in stride(from: 148, through: 332, by: 46) {
                        UIBezierPath(ovalIn: CGRect(x: x, y: 92, width: 68, height: 78)).fill()
                    }
                    UIBezierPath(ovalIn: CGRect(x: 142, y: 138, width: 70, height: 86)).fill()
                    UIBezierPath(ovalIn: CGRect(x: 302, y: 138, width: 70, height: 86)).fill()
                }

                let featureColor = UIColor(white: 0.16, alpha: 0.82)
                featureColor.setFill()
                UIBezierPath(ovalIn: CGRect(x: 204, y: 218, width: 18, height: 18)).fill()
                UIBezierPath(ovalIn: CGRect(x: 290, y: 218, width: 18, height: 18)).fill()
                UIBezierPath(roundedRect: CGRect(x: 226, y: 280, width: 60, height: 12), cornerRadius: 6).fill()

                if let beardColor = person.beardColor {
                    beardColor.setFill()
                    UIBezierPath(roundedRect: CGRect(x: 190, y: 274, width: 132, height: 74), cornerRadius: 34).fill()
                    person.skinColor.setFill()
                    UIBezierPath(roundedRect: CGRect(x: 226, y: 280, width: 60, height: 12), cornerRadius: 6).fill()
                }

                if person.wearsGlasses {
                    featureColor.setStroke()
                    let leftLens = UIBezierPath(ovalIn: CGRect(x: 180, y: 198, width: 66, height: 54))
                    leftLens.lineWidth = 9
                    leftLens.stroke()
                    let rightLens = UIBezierPath(ovalIn: CGRect(x: 266, y: 198, width: 66, height: 54))
                    rightLens.lineWidth = 9
                    rightLens.stroke()
                    let bridge = UIBezierPath()
                    bridge.move(to: CGPoint(x: 246, y: 225))
                    bridge.addLine(to: CGPoint(x: 266, y: 225))
                    bridge.lineWidth = 9
                    bridge.stroke()
                }
            }
        }

        private let options: [AvatarOption] = [
            AvatarOption(symbolName: "person.fill", color: .systemBlue),
            AvatarOption(symbolName: "figure.run", color: .systemGreen),
            AvatarOption(symbolName: "figure.walk", color: .systemOrange),
            AvatarOption(symbolName: "heart.fill", color: .systemPink),
            AvatarOption(symbolName: "bolt.fill", color: .systemIndigo),
            AvatarOption(symbolName: "star.fill", color: .systemPurple),
            AvatarOption(id: "avatar_person_01", color: .systemTeal, person: PersonStyle(skinColor: UIColor(red: 0.96, green: 0.77, blue: 0.61, alpha: 1), hairColor: UIColor(red: 0.20, green: 0.12, blue: 0.08, alpha: 1), shirtColor: .systemBlue, hairStyle: .short, beardColor: nil, wearsGlasses: false)),
            AvatarOption(id: "avatar_person_02", color: .systemPurple, person: PersonStyle(skinColor: UIColor(red: 0.61, green: 0.38, blue: 0.24, alpha: 1), hairColor: UIColor(red: 0.10, green: 0.07, blue: 0.05, alpha: 1), shirtColor: .systemPink, hairStyle: .curly, beardColor: nil, wearsGlasses: true)),
            AvatarOption(id: "avatar_person_03", color: .systemOrange, person: PersonStyle(skinColor: UIColor(red: 0.79, green: 0.53, blue: 0.35, alpha: 1), hairColor: UIColor(red: 0.17, green: 0.10, blue: 0.06, alpha: 1), shirtColor: .systemIndigo, hairStyle: .bald, beardColor: UIColor(red: 0.17, green: 0.10, blue: 0.06, alpha: 1), wearsGlasses: false)),
            AvatarOption(id: "avatar_person_04", color: .systemBlue, person: PersonStyle(skinColor: UIColor(red: 0.98, green: 0.83, blue: 0.72, alpha: 1), hairColor: UIColor(red: 0.72, green: 0.36, blue: 0.16, alpha: 1), shirtColor: .systemGreen, hairStyle: .long, beardColor: nil, wearsGlasses: false)),
            AvatarOption(id: "avatar_person_05", color: .systemGreen, person: PersonStyle(skinColor: UIColor(red: 0.42, green: 0.25, blue: 0.16, alpha: 1), hairColor: UIColor(red: 0.04, green: 0.03, blue: 0.02, alpha: 1), shirtColor: .systemYellow, hairStyle: .short, beardColor: UIColor(red: 0.04, green: 0.03, blue: 0.02, alpha: 1), wearsGlasses: true)),
            AvatarOption(id: "avatar_person_06", color: .systemPink, person: PersonStyle(skinColor: UIColor(red: 0.87, green: 0.64, blue: 0.49, alpha: 1), hairColor: UIColor(red: 0.16, green: 0.09, blue: 0.04, alpha: 1), shirtColor: .systemTeal, hairStyle: .curly, beardColor: nil, wearsGlasses: false)),
            AvatarOption(id: "avatar_person_07", color: .systemIndigo, person: PersonStyle(skinColor: UIColor(red: 0.70, green: 0.45, blue: 0.28, alpha: 1), hairColor: UIColor(red: 0.33, green: 0.18, blue: 0.08, alpha: 1), shirtColor: .systemOrange, hairStyle: .long, beardColor: nil, wearsGlasses: true)),
            AvatarOption(id: "avatar_person_08", color: .systemMint, person: PersonStyle(skinColor: UIColor(red: 0.94, green: 0.72, blue: 0.56, alpha: 1), hairColor: UIColor(red: 0.50, green: 0.28, blue: 0.12, alpha: 1), shirtColor: .systemPurple, hairStyle: .short, beardColor: nil, wearsGlasses: true)),
            AvatarOption(id: "avatar_person_09", color: .systemRed, person: PersonStyle(skinColor: UIColor(red: 0.32, green: 0.19, blue: 0.12, alpha: 1), hairColor: UIColor(red: 0.03, green: 0.02, blue: 0.01, alpha: 1), shirtColor: .systemCyan, hairStyle: .bald, beardColor: UIColor(red: 0.03, green: 0.02, blue: 0.01, alpha: 1), wearsGlasses: false)),
            AvatarOption(id: "avatar_person_10", color: .systemBrown, person: PersonStyle(skinColor: UIColor(red: 0.83, green: 0.58, blue: 0.42, alpha: 1), hairColor: UIColor(red: 0.76, green: 0.63, blue: 0.31, alpha: 1), shirtColor: .systemBlue, hairStyle: .long, beardColor: nil, wearsGlasses: false)),
            AvatarOption(id: "avatar_person_11", color: .systemCyan, person: PersonStyle(skinColor: UIColor(red: 0.56, green: 0.34, blue: 0.21, alpha: 1), hairColor: UIColor(red: 0.12, green: 0.07, blue: 0.04, alpha: 1), shirtColor: .systemPink, hairStyle: .curly, beardColor: UIColor(red: 0.12, green: 0.07, blue: 0.04, alpha: 1), wearsGlasses: false)),
            AvatarOption(id: "avatar_person_12", color: .systemGray, person: PersonStyle(skinColor: UIColor(red: 0.97, green: 0.78, blue: 0.65, alpha: 1), hairColor: UIColor(red: 0.27, green: 0.20, blue: 0.16, alpha: 1), shirtColor: .systemGreen, hairStyle: .short, beardColor: nil, wearsGlasses: true))
        ]

        let onSelect: (UIImage) -> Void
        @Environment(\.dismiss) private var dismiss

        var body: some View {
            NavigationStack {
                ZStack {
                    Theme.Colors.headerBackground
                        .ignoresSafeArea()

                    ScrollView(showsIndicators: false) {
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3),
                            spacing: 16
                        ) {
                            ForEach(options) { option in
                                Button {
                                    onSelect(option.image())
                                    dismiss()
                                } label: {
                                    Image(uiImage: option.image())
                                        .resizable()
                                        .scaledToFill()
                                        .clipShape(Circle())
                                        .frame(width: 88, height: 88)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(24)
                    }
                }
                .navigationTitle("Escolher Avatar")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Fechar") {
                            dismiss()
                        }
                    }
                }
                .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
            }
        }
    }

    // Retorna picker estilizado com underline
    private func pickerRow<T: RawRepresentable & CaseIterable>(
        title: String,
        selection: Binding<T>,
        options: [T],
        displayText: ((T) -> String)? = nil
    ) -> some View where T.RawValue == String {
        VStack(alignment: .leading, spacing: 8) {

            Text(title)
                .font(.system(size: 14))
                .foregroundColor(textSecondary)

            Menu {
                ForEach(options, id: \.rawValue) { opt in
                    Button(displayText?(opt) ?? opt.rawValue) {
                        selection.wrappedValue = opt
                    }
                }
            } label: {
                HStack {
                    Text(displayText?(selection.wrappedValue) ?? selection.wrappedValue.rawValue)
                        .foregroundColor(.white.opacity(0.92))
                        .font(.system(size: 16))

                    Spacer()

                    Image(systemName: "chevron.down")
                        .foregroundColor(.white.opacity(0.55))
                }
                .contentShape(Rectangle())
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(lineColor)
                .frame(height: 1)
        }
    }
}
