import SwiftUI

struct TeacherAddYoutubeVideoSheet: View {

    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var url: String = ""
    @State private var selectedCategory: TeacherYoutubeVideoCategory = .crossfit
    @State private var sheetMessage: String? = nil
    @State private var sheetMessageIsError: Bool = false

    let onSave: (_ title: String, _ url: String, _ category: TeacherYoutubeVideoCategory) -> Void

    var body: some View {
        ZStack {
            Theme.Colors.headerBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        Capsule()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 44, height: 5)
                            .padding(.top, 10)

                        Text("Adicionar Vídeo")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 4)

                        VStack(alignment: .leading, spacing: 14) {
                            Text("Cole o link do YouTube e adicione um título para facilitar a busca.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.45))

                            formFields

                            if let msg = sheetMessage {
                                sheetMessageCard(text: msg, isError: sheetMessageIsError)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.Colors.cardBackground)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        handleCopyYoutubeLink()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "doc.on.doc")
                            Text("Abrir YouTube")
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.10))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

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
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 16)
            }
        }
        .presentationDetents([.medium])
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
                .background(Color.white.opacity(0.10))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
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
                .background(Color.white.opacity(0.10))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
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
                .background(Color.white.opacity(0.10))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
            }
        }
    }
    
    private func sheetMessageCard(text: String, isError: Bool) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(isError ? .yellow.opacity(0.85) : .green.opacity(0.85))
            .frame(maxWidth: .infinity, alignment: .leading)
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
