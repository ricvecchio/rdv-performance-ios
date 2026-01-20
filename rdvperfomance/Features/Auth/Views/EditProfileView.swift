// Tela para editar foto de perfil, WhatsApp e área de foco
import SwiftUI
import PhotosUI
import UIKit

struct EditProfileView: View {

    @Binding var path: [AppRoute]
    @EnvironmentObject private var session: AppSession

    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var previewImage: UIImage? = nil
    @State private var isLoadingImage: Bool = false

    @State private var whatsappDraft: String = ""
    @State private var focusAreaDraft: FocusAreaDTO = .CROSSFIT

    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    private let textSecondary = Color.white.opacity(0.60)
    private let lineColor = Color.white.opacity(0.35)

    private let contentMaxWidth: CGFloat = 380

    private let studentFocusOptions: [FocusAreaDTO] = [.CROSSFIT, .GYM, .HOME]

    // Retorna UID do usuário atual
    private var currentUid: String? { session.currentUid }

    // Retorna imagem armazenada localmente para o usuário
    private var storedImageForUser: UIImage? {
        LocalProfileStore.shared.getPhotoImage(userId: currentUid)
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
        .toolbar {

            ToolbarItem(placement: .navigationBarLeading) {
                Button { pop() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.green)
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
        .onAppear {
            loadFromStore()
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            Task { await loadImage(from: newItem) }
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

            Text("A foto escolhida será exibida no seu perfil e no cabeçalho quando logado.")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.white.opacity(0.60))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    // Retorna card com campos do formulário
    private func formCard() -> some View {
        VStack(spacing: 18) {

            underlineTextField(
                title: "WhatsApp (opcional)",
                text: $whatsappDraft
            )

            pickerRow(
                title: "Área de foco",
                selection: $focusAreaDraft,
                options: studentFocusOptions,
                displayText: displayTextForFocusArea
            )
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

            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .foregroundColor(.white.opacity(0.9))

                    Text(isLoadingImage ? "Carregando..." : "Importar foto do celular")
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
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white.opacity(0.9))

                    Text("Salvar")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))

                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.10))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)

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

    // Carrega dados salvos do usuário atual do armazenamento local
    private func loadFromStore() {
        guard let _ = currentUid else {
            whatsappDraft = ""
            focusAreaDraft = .CROSSFIT
            previewImage = nil
            return
        }

        whatsappDraft = LocalProfileStore.shared.getWhatsapp(userId: currentUid)

        let raw = LocalProfileStore.shared.getFocusAreaRaw(userId: currentUid)
        focusAreaDraft = FocusAreaDTO(rawValue: raw.isEmpty ? FocusAreaDTO.CROSSFIT.rawValue : raw) ?? .CROSSFIT

        if previewImage == nil, let img = LocalProfileStore.shared.getPhotoImage(userId: currentUid) {
            previewImage = img
        }

        showError = false
        errorMessage = ""
    }

    // ✅ Salva local + sincroniza foto no Firestore (para o professor enxergar na lista)
    private func saveAllAndSync() async {
        saveWhatsapp()
        saveFocusArea()

        do {
            try await savePhotoIfNeededAndSync()
            await MainActor.run {
                showError = false
                errorMessage = ""
            }
            pop()
        } catch {
            presentError((error as NSError).localizedDescription)
        }
    }

    // Persiste WhatsApp localmente
    private func saveWhatsapp() {
        let v = whatsappDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        LocalProfileStore.shared.setWhatsapp(v, userId: currentUid)
    }

    // Persiste área de foco localmente
    private func saveFocusArea() {
        LocalProfileStore.shared.setFocusAreaRaw(focusAreaDraft.rawValue, userId: currentUid)
    }

    // ✅ Persiste foto localmente e no Firestore (base64)
    private func savePhotoIfNeededAndSync() async throws {
        guard let uid = currentUid?.trimmingCharacters(in: .whitespacesAndNewlines), !uid.isEmpty else {
            throw FirestoreRepositoryError.missingUserId
        }

        // Se não tem preview novo, não faz escrita desnecessária
        guard let previewImage else { return }

        // 1) Salvar local (como já fazia)
        let ok = LocalProfileStore.shared.setPhotoImage(previewImage, userId: currentUid, compressionQuality: 0.82)
        if !ok {
            throw FirestoreRepositoryError.writeFailed
        }

        // 2) Salvar no Firestore em base64 (para outras telas/usuários verem)
        guard let data = previewImage.jpegData(compressionQuality: 0.72) else {
            throw FirestoreRepositoryError.invalidData
        }

        let base64 = data.base64EncodedString()
        try await FirestoreRepository.shared.setUserPhotoBase64(uid: uid, photoBase64: base64)
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

    // Remove a última rota da pilha de navegação
    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    // Retorna campo de texto com estilo underline
    private func underlineTextField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {

            Text(title)
                .font(.system(size: 14))
                .foregroundColor(textSecondary)

            TextField("", text: text)
                .foregroundColor(.white.opacity(0.92))
                .font(.system(size: 16))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .keyboardType(.phonePad)
                .padding(.vertical, 10)

            Rectangle()
                .fill(lineColor)
                .frame(height: 1)
        }
    }

    // Converte FocusAreaDTO em texto amigável
    private func displayTextForFocusArea(_ opt: FocusAreaDTO) -> String {
        switch opt {
        case .CROSSFIT: return "Crossfit"
        case .GYM: return "Academia"
        case .HOME: return "Treinos em Casa"
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
