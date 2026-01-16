import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import WebKit
import SafariServices
import UIKit

struct TeacherImportVideosView: View {

    @Binding var path: [AppRoute]
    let category: TreinoTipo

    private let contentMaxWidth: CGFloat = 380

    @State private var videos: [TeacherYoutubeVideo] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    @State private var isAddSheetPresented: Bool = false

    // ✅ Player interno (embed travado)
    @State private var activePlayer: PlayerItem? = nil
    private struct PlayerItem: Identifiable {
        let id = UUID()
        let title: String
        let videoId: String
    }

    // ✅ Fallback: YouTube dentro do app (Safari)
    @State private var activeSafari: SafariItem? = nil
    private struct SafariItem: Identifiable {
        let id = UUID()
        let title: String
        let url: URL
    }

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

                ScrollView(showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 0)

                        VStack(alignment: .leading, spacing: 14) {

                            header

                            addButtonCard

                            contentCard

                            if let err = errorMessage {
                                messageCard(text: err, isError: true)
                            }

                            Color.clear.frame(height: Theme.Layout.footerHeight + 20)
                        }
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        Spacer(minLength: 0)
                    }
                }

                FooterBar(
                    path: $path,
                    kind: .teacherHomeAlunosSobrePerfil(
                        selectedCategory: category,
                        isHomeSelected: false,
                        isAlunosSelected: false,
                        isSobreSelected: false,
                        isPerfilSelected: false
                    )
                )
                .frame(height: Theme.Layout.footerHeight)
                .background(Theme.Colors.footerBackground)
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
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
                Text("Importar Vídeos")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
                    .lineLimit(1)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await loadVideos() }
        .onAppear { Task { await loadVideos() } }

        // ✅ Sheet adicionar vídeo
        .sheet(isPresented: $isAddSheetPresented) {
            TeacherAddYoutubeVideoSheet { title, url in
                Task { await addVideo(title: title, url: url) }
            }
        }

        // ✅ Sheet player embed (travado)
        .sheet(item: $activePlayer) { item in
            TeacherYoutubeEmbedLockedSheet(
                title: item.title,
                videoId: item.videoId,
                onOpenInYoutube: {
                    openYoutubeInsideApp(title: item.title, videoId: item.videoId)
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(22)
        }

        // ✅ Fallback (Safari interno)
        .sheet(item: $activeSafari) { item in
            TeacherYoutubeSafariSheet(title: item.title, url: item.url)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(22)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Salve links do YouTube para consultar depois.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var addButtonCard: some View {
        Button {
            errorMessage = nil
            isAddSheetPresented = true
        } label: {
            HStack {
                Image(systemName: "plus")
                Text("Adicionar Vídeo")
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white.opacity(0.92))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Capsule().fill(Color.green.opacity(0.16)))
        }
        .buttonStyle(.plain)
    }

    private var contentCard: some View {
        VStack(spacing: 0) {
            if isLoading {
                loadingView
            } else if videos.isEmpty {
                emptyView
            } else {
                videosList
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var videosList: some View {
        VStack(spacing: 0) {
            ForEach(videos.indices, id: \.self) { idx in
                let v = videos[idx]

                videoRow(video: v)
                    .contentShape(Rectangle())

                if idx < videos.count - 1 {
                    innerDivider(leading: 14)
                }
            }
        }
    }

    private func videoRow(video v: TeacherYoutubeVideo) -> some View {
        HStack(spacing: 12) {

            thumbnailView(videoId: v.videoId)

            VStack(alignment: .leading, spacing: 4) {
                Text(v.title.isEmpty ? "Vídeo do YouTube" : v.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(1)

                Text(v.url)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(1)
            }

            Spacer()

            Menu {
                Button {
                    playInsideApp(video: v)
                } label: {
                    Label("Reproduzir no app", systemImage: "airplayvideo")
                }

                Button {
                    openYoutubeInsideApp(title: v.title.isEmpty ? "Vídeo do YouTube" : v.title, videoId: v.videoId)
                } label: {
                    Label("Abrir no YouTube", systemImage: "safari.fill")
                }

                Button(role: .destructive) {
                    Task { await deleteVideo(videoId: v.id) }
                } label: {
                    Label("Remover", systemImage: "trash.fill")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.55))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.35))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .onTapGesture {
            playInsideApp(video: v)
        }
    }

    private func playInsideApp(video v: TeacherYoutubeVideo) {
        errorMessage = nil
        let title = v.title.isEmpty ? "Vídeo do YouTube" : v.title
        activePlayer = PlayerItem(title: title, videoId: v.videoId)
    }

    private func openYoutubeInsideApp(title: String, videoId: String) {
        guard let url = URL(string: "https://m.youtube.com/watch?v=\(videoId)") else { return }
        activeSafari = SafariItem(title: title, url: url)
    }

    private func thumbnailView(videoId: String) -> some View {
        let thumb = "https://img.youtube.com/vi/\(videoId)/hqdefault.jpg"
        return AsyncImage(url: URL(string: thumb)) { phase in
            switch phase {
            case .empty:
                ZStack {
                    Color.white.opacity(0.06)
                    ProgressView().tint(.white.opacity(0.8))
                }
            case .success(let img):
                img.resizable().scaledToFill()
            case .failure:
                ZStack {
                    Color.white.opacity(0.06)
                    Image(systemName: "video.fill")
                        .foregroundColor(.green.opacity(0.85))
                }
            @unknown default:
                Color.white.opacity(0.06)
            }
        }
        .frame(width: 66, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private var loadingView: some View {
        VStack(spacing: 10) {
            ProgressView()
            Text("Carregando...")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private var emptyView: some View {
        VStack(spacing: 10) {
            Text("Nenhum vídeo cadastrado")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))

            Text("Toque em “Adicionar Vídeo” para salvar um link do YouTube.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 10)
    }

    private func messageCard(text: String, isError: Bool) -> some View {
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

    private func innerDivider(leading: CGFloat) -> some View {
        Divider()
            .background(Theme.Colors.divider)
            .padding(.leading, leading)
    }

    // MARK: - Firestore

    private func loadVideos() async {
        errorMessage = nil

        let teacherId = (Auth.auth().currentUser?.uid ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !teacherId.isEmpty else {
            videos = []
            errorMessage = "Não foi possível identificar o professor logado."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let snap = try await Firestore.firestore()
                .collection("teachers")
                .document(teacherId)
                .collection("youtubeVideos")
                .order(by: "createdAt", descending: true)
                .getDocuments()

            let parsed: [TeacherYoutubeVideo] = snap.documents.compactMap { doc in
                let data = doc.data()
                let title = (data["title"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let url = (data["url"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let videoId = (data["videoId"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                guard !url.isEmpty, !videoId.isEmpty else { return nil }

                return TeacherYoutubeVideo(
                    id: doc.documentID,
                    title: title,
                    url: url,
                    videoId: videoId
                )
            }

            videos = parsed
        } catch {
            videos = []
            errorMessage = error.localizedDescription
        }
    }

    private func addVideo(title: String, url: String) async {
        errorMessage = nil

        let teacherId = (Auth.auth().currentUser?.uid ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !teacherId.isEmpty else {
            errorMessage = "Não foi possível identificar o professor logado."
            return
        }

        let cleanedUrl = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let videoId = extractYoutubeVideoId(from: cleanedUrl) else {
            errorMessage = "Link inválido. Cole um link do YouTube (youtu.be/ ou youtube.com/watch)."
            return
        }

        let payload: [String: Any] = [
            "title": title.trimmingCharacters(in: .whitespacesAndNewlines),
            "url": cleanedUrl,
            "videoId": videoId,
            "createdAt": Timestamp(date: Date())
        ]

        isLoading = true
        defer { isLoading = false }

        do {
            try await Firestore.firestore()
                .collection("teachers")
                .document(teacherId)
                .collection("youtubeVideos")
                .addDocument(data: payload)

            await loadVideos()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteVideo(videoId: String) async {
        errorMessage = nil

        let teacherId = (Auth.auth().currentUser?.uid ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !teacherId.isEmpty else {
            errorMessage = "Não foi possível identificar o professor logado."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await Firestore.firestore()
                .collection("teachers")
                .document(teacherId)
                .collection("youtubeVideos")
                .document(videoId)
                .delete()

            await loadVideos()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private func extractYoutubeVideoId(from urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }

        if let host = url.host, host.contains("youtu.be") {
            let id = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return id.isEmpty ? nil : id
        }

        if let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let host = comps.host,
           host.contains("youtube.com") {
            if url.path.contains("/watch") {
                let v = comps.queryItems?.first(where: { $0.name == "v" })?.value
                return (v?.isEmpty == false) ? v : nil
            }

            if url.path.contains("/shorts/") {
                let parts = url.path.split(separator: "/")
                if let idx = parts.firstIndex(of: "shorts"), idx + 1 < parts.count {
                    return String(parts[idx + 1])
                }
            }

            if url.path.contains("/embed/") {
                let parts = url.path.split(separator: "/")
                if let idx = parts.firstIndex(of: "embed"), idx + 1 < parts.count {
                    return String(parts[idx + 1])
                }
            }
        }

        return nil
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

// MARK: - Model local
private struct TeacherYoutubeVideo: Identifiable, Equatable {
    let id: String
    let title: String
    let url: String
    let videoId: String
}

// MARK: - Sheet player embed travado
private struct TeacherYoutubeEmbedLockedSheet: View {

    let title: String
    let videoId: String
    let onOpenInYoutube: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Image("rdv_fundo")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                VStack(spacing: 12) {

                    // ✅ Player contido (não estoura laterais)
                    HStack {
                        Spacer(minLength: 0)
                        YoutubeEmbedLockedWebView(videoId: videoId)
                            .frame(maxWidth: 380)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    // ✅ Ações
                    HStack {
                        Spacer()
                        Button {
                            onOpenInYoutube()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "safari.fill")
                                Text("Abrir no YouTube")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.92))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Color.green.opacity(0.16)))
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.horizontal, 16)

                    Spacer(minLength: 0)
                }
            }
            .navigationTitle(title)
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
    }
}

// MARK: - WKWebView embed TRAVADO (bloqueia navegar para outros vídeos)
private struct YoutubeEmbedLockedWebView: UIViewRepresentable {

    let videoId: String

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        if #available(iOS 10.0, *) {
            config.mediaTypesRequiringUserActionForPlayback = []
        }

        let web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = context.coordinator
        web.scrollView.isScrollEnabled = false
        web.isOpaque = false
        web.backgroundColor = .clear

        // ✅ HTML mínimo com iframe embed
        // - rel=0: reduz recomendados
        // - modestbranding=1: menos “cara de YouTube”
        // - playsinline=1: toca dentro
        // - disablekb=1: reduz controles de teclado
        let html = """
        <!doctype html>
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
            <style>
              html, body { margin:0; padding:0; background: transparent; }
              .wrap { position: relative; width: 100%; padding-top: 56.25%; }
              iframe { position:absolute; top:0; left:0; width:100%; height:100%; border:0; }
            </style>
          </head>
          <body>
            <div class="wrap">
              <iframe
                src="https://www.youtube-nocookie.com/embed/\(videoId)?playsinline=1&rel=0&modestbranding=1&controls=1&fs=1&disablekb=1"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; fullscreen"
                allowfullscreen>
              </iframe>
            </div>
          </body>
        </html>
        """
        web.loadHTMLString(html, baseURL: nil)
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) { }

    final class Coordinator: NSObject, WKNavigationDelegate {
        // ✅ Bloqueia qualquer tentativa de navegar dentro do WebView (outros vídeos, links etc.)
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

            // Permite somente o carregamento inicial do HTML/iframe
            if navigationAction.navigationType == .other || navigationAction.navigationType == .reload {
                decisionHandler(.allow)
                return
            }

            // Bloqueia cliques e redirecionamentos para outras páginas
            decisionHandler(.cancel)
        }
    }
}

// MARK: - Sheet Safari (fallback)
private struct TeacherYoutubeSafariSheet: View {

    let title: String
    let url: URL

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            SafariView(url: url)
                .navigationTitle(title)
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
    }
}

private struct SafariView: UIViewControllerRepresentable {

    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        config.barCollapsingEnabled = true
        let vc = SFSafariViewController(url: url, configuration: config)
        vc.preferredControlTintColor = UIColor.systemGreen
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) { }
}

// MARK: - Sheet adicionar vídeo (mantido aqui para não dar "Cannot find ... in scope")
private struct TeacherAddYoutubeVideoSheet: View {

    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var url: String = ""

    let onSave: (_ title: String, _ url: String) -> Void

    private let contentMaxWidth: CGFloat = 380

    var body: some View {
        NavigationStack {
            ZStack {

                Image("rdv_fundo")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                VStack(spacing: 0) {

                    Rectangle()
                        .fill(Theme.Colors.divider)
                        .frame(height: 1)

                    ScrollView(showsIndicators: false) {
                        HStack {
                            Spacer(minLength: 0)

                            VStack(alignment: .leading, spacing: 14) {

                                Text("Cole o link do YouTube e adicione um título para facilitar a busca.")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.65))

                                formCard

                                Button {
                                    let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
                                    let u = url.trimmingCharacters(in: .whitespacesAndNewlines)
                                    onSave(t, u)
                                    dismiss()
                                } label: {
                                    HStack {
                                        Image(systemName: "checkmark")
                                        Text("Salvar")
                                    }
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.92))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(Capsule().fill(Color.green.opacity(0.16)))
                                }
                                .buttonStyle(.plain)
                                .disabled(url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                                Color.clear.frame(height: 18)
                            }
                            .frame(maxWidth: contentMaxWidth)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)

                            Spacer(minLength: 0)
                        }
                    }
                }
                .ignoresSafeArea(.container, edges: [.bottom])
            }
            .navigationTitle("Adicionar Vídeo")
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
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            VStack(alignment: .leading, spacing: 6) {
                Text("Título (opcional)")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.55))

                ZStack(alignment: .leading) {
                    if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Ex: Mobilidade de ombro")
                            .foregroundColor(.white.opacity(0.45))
                            .padding(.horizontal, 12)
                    }

                    TextField("", text: $title)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(false)
                        .foregroundColor(.white.opacity(0.92))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                }
                .background(Color.white.opacity(0.10))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
            }

            Divider().background(Theme.Colors.divider)

            VStack(alignment: .leading, spacing: 6) {
                Text("Link do YouTube")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.55))

                ZStack(alignment: .leading) {
                    if url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Cole aqui o link (youtu.be / youtube.com)")
                            .foregroundColor(.white.opacity(0.45))
                            .padding(.horizontal, 12)
                    }

                    TextField("", text: $url)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .foregroundColor(.white.opacity(0.92))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                }
                .background(Color.white.opacity(0.10))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

