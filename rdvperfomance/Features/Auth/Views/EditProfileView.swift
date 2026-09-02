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
        whatsappDigits != originalWhatsappDigits ||
        focusAreaDraft != originalFocusArea ||
        crefDraft != originalCref ||
        bioDraft != originalBio ||
        hasNewPhoto
    }

    /// Botão Salvar fica habilitado quando há alterações válidas e não está salvando.
    private var canSave: Bool {
        isPhoneValid && hasChanges && !isSaving
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
                            actionCard()

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
            readOnlyRow(title: "Nome", value: userName)
            readOnlyRow(title: "E-mail", value: userEmail)

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

            if session.userType == .TRAINER {
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

    // Retorna card com botões de ação (importar, salvar, remover)
    private func actionCard() -> some View {
        VStack(spacing: 10) {

            Menu {
                Button("Escolher foto da biblioteca") {
                    showPhotoPicker = true
                }
                Button("Escolher Avatar") {
                    showAvatarPicker = true
                }
                Button("Cancelar", role: .cancel) {}
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .foregroundColor(.white.opacity(0.9))

                    Text(isLoadingImage ? "Carregando..." : "Adicionar foto ou Avatar")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))

                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(Color.green.opacity(0.28))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                )
                .shadow(color: Color.green.opacity(0.10), radius: 10, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .disabled(isLoadingImage)

            Button {
                Task { await saveAllAndSync() }
            } label: {
                HStack(spacing: 10) {
                    if isSaving {
                        ProgressView()
                            .tint(.white.opacity(0.9))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white.opacity(0.9))
                    }

                    Text(isSaving ? "Salvando..." : "Salvar")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))

                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .background(
                    // ✅ Verde quando há alterações válidas; neutro caso contrário
                    Capsule()
                        .fill(canSave ? Color.green.opacity(0.28) : Color.white.opacity(0.10))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
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
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
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
                phone: whatsappDigits.isEmpty ? nil : whatsappDigits,
                cref: session.userType == .TRAINER ? crefDraft : nil,
                bio: session.userType == .TRAINER ? bioDraft : nil,
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
                originalFocusArea = focusAreaDraft
                originalCref = crefDraft
                originalBio = bioDraft
                hasNewPhoto = false
            }
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
        private struct AvatarOption: Identifiable {
            let symbolName: String
            let color: UIColor

            var id: String { symbolName }

            func image() -> UIImage {
                let size = CGSize(width: 512, height: 512)
                let format = UIGraphicsImageRendererFormat()
                format.scale = 1
                format.opaque = true

                return UIGraphicsImageRenderer(size: size, format: format).image { _ in
                    color.setFill()
                    UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).fill()

                    let configuration = UIImage.SymbolConfiguration(pointSize: 260, weight: .medium)
                    let symbol = UIImage(systemName: symbolName, withConfiguration: configuration)?
                        .withTintColor(.white, renderingMode: .alwaysOriginal)
                    symbol?.draw(in: CGRect(x: 126, y: 126, width: 260, height: 260))
                }
            }
        }

        private let options: [AvatarOption] = [
            AvatarOption(symbolName: "person.fill", color: .systemBlue),
            AvatarOption(symbolName: "figure.run", color: .systemGreen),
            AvatarOption(symbolName: "figure.walk", color: .systemOrange),
            AvatarOption(symbolName: "heart.fill", color: .systemPink),
            AvatarOption(symbolName: "bolt.fill", color: .systemIndigo),
            AvatarOption(symbolName: "star.fill", color: .systemPurple)
        ]

        let onSelect: (UIImage) -> Void
        @Environment(\.dismiss) private var dismiss

        var body: some View {
            NavigationStack {
                ZStack {
                    Theme.Colors.headerBackground
                        .ignoresSafeArea()

                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3),
                        spacing: 16
                    ) {
                        ForEach(options) { option in
                            Button {
                                onSelect(option.image())
                                dismiss()
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(uiColor: option.color))
                                    Image(systemName: option.symbolName)
                                        .font(.system(size: 38, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                .frame(width: 88, height: 88)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(24)
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
