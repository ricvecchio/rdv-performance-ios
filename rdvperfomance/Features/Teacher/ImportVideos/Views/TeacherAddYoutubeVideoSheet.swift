import SwiftUI

struct TeacherAddYoutubeVideoSheet: View {

    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var url: String = ""
    @State private var selectedCategory: TeacherYoutubeVideoCategory = .crossfit
    @State private var sheetMessage: String? = nil
    @State private var sheetMessageIsError: Bool = false

    let onSave: (_ title: String, _ url: String, _ category: TeacherYoutubeVideoCategory) -> Void

    private let contentMaxWidth: CGFloat = 380

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.headerBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 0)

                        VStack(alignment: .leading, spacing: 14) {
                            Capsule()
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 44, height: 5)
                                .padding(.top, 10)
                                .frame(maxWidth: .infinity)

                            Text("Adicionar Vídeo")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.top, 4)
                                .frame(maxWidth: .infinity)

                            Text("Cole o link do YouTube e adicione um título para facilitar a busca.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.60))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 16)

                            formFields

                            HStack(spacing: 12) {
                                Button {
                                    let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
                                    let u = url.trimmingCharacters(in: .whitespacesAndNewlines)
                                    onSave(t, u, selectedCategory)
                                    dismiss()
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: "checkmark")
                                        Text("Salvar")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .primaryGreenActionButton()
                                }
                                .buttonStyle(.plain)
                                .disabled(url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                                Button {
                                    handleCopyYoutubeLink()
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: "doc.on.doc")
                                        Text("Copiar link YouTube")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .primaryGreenActionButton()
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.top, 6)

                            if let msg = sheetMessage {
                                sheetMessageCard(text: msg, isError: sheetMessageIsError)
                            }
                            
                            Color.clear.frame(height: 18)
                        }
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)

                        Spacer(minLength: 0)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fechar") { dismiss() }
                }
            }
            .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.Colors.headerBackground)
    }
    
    private var formFields: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Título (opcional)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.75))
                
                ZStack(alignment: .leading) {
                    if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Ex: Mobilidade de ombro")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.45))
                            .padding(.horizontal, 14)
                    }
                    
                    TextField("", text: $title)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(false)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                }
                .background(Theme.Colors.cardBackground)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Link do YouTube")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.75))
                
                ZStack(alignment: .leading) {
                    if url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Cole aqui o link (youtu.be / youtube.com)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.45))
                            .padding(.horizontal, 14)
                    }
                    
                    TextField("", text: $url)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                }
                .background(Theme.Colors.cardBackground)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Categoria do vídeo")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.75))
                
                Picker("", selection: $selectedCategory) {
                    ForEach(TeacherYoutubeVideoCategory.allCases) { c in
                        Text(c.rawValue).tag(c)
                    }
                }
                .pickerStyle(.segmented)
                .padding(14)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }
    
    private func sheetMessageCard(text: String, isError: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundColor(isError ? .yellow.opacity(0.85) : .green.opacity(0.85))
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.75))
            
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.35))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }
    
    private func handleCopyYoutubeLink() {
        sheetMessage = nil
        sheetMessageIsError = false
        
        let clipboard = (UIPasteboard.general.string ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        if YouTubeVideoImporter.isValidYoutubeUrl(clipboard) {
            url = clipboard
            sheetMessage = "Link do YouTube colado do clipboard."
            sheetMessageIsError = false
            return
        }
        
        openYoutubeExternal()
        sheetMessage = "YouTube aberto. Copie o link do vídeo e volte para colar aqui."
        sheetMessageIsError = false
    }
    
    private func openYoutubeExternal() {
        guard let youtubeUrl = URL(string: "https://m.youtube.com") else { return }
        UIApplication.shared.open(youtubeUrl, options: [:], completionHandler: nil)
    }
}
