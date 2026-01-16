import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import SafariServices
import UIKit
import AVKit
import WebKit

struct TeacherImportVideosView: View {

    @Binding var path: [AppRoute]
    let category: TreinoTipo

    private let contentMaxWidth: CGFloat = 380

    @State private var videos: [TeacherYoutubeVideo] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    @State private var isAddSheetPresented: Bool = false

    // ✅ Sheet player travado no vídeo
    @State private var activeLockedPlayer: LockedPlayerItem? = nil

    private struct LockedPlayerItem: Identifiable {
        let id = UUID()
        let title: String
        let videoId: String
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

        // ✅ Reproduzir no app (WKWebView travado)
        .sheet(item: $activeLockedPlayer) { item in
            TeacherYoutubeLockedPlayerSheet(title: item.title, videoId: item.videoId)
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

    // Botão no padrão capsule
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

    private func openLockedPlayer(for video: TeacherYoutubeVideo) {
        activeLockedPlayer = LockedPlayerItem(
            title: video.title.isEmpty ? "Vídeo do YouTube" : video.title,
            videoId: video.videoId
        )
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

            // ✅ Menu agora SOMENTE remover
            Menu {
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

            // ✅ Seta =CTA: reproduzir no app
            Button {
                openLockedPlayer(for: v)
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.35))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        // ✅ Toque na linha: reproduzir no app
        .onTapGesture {
            openLockedPlayer(for: v)
        }
    }

    // ✅ Thumbnail com overlay do ícone PLAY
    private func thumbnailView(videoId: String) -> some View {
        let thumb = "https://img.youtube.com/vi/\(videoId)/hqdefault.jpg"

        return ZStack(alignment: .bottomTrailing) {

            AsyncImage(url: URL(string: thumb)) { phase in
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

            // ✅ Ícone play (reforça ação)
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.45))
                Image(systemName: "play.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.95))
                    .padding(.leading, 1) // leve ajuste óptico
            }
            .frame(width: 18, height: 18)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .padding(6)
        }
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

        // 1) youtu.be/<id>
        if let host = url.host, host.contains("youtu.be") {
            let id = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return id.isEmpty ? nil : id
        }

        // 2) youtube.com/watch?v=<id>
        if let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let host = comps.host,
           host.contains("youtube.com") {
            if url.path.contains("/watch") {
                let v = comps.queryItems?.first(where: { $0.name == "v" })?.value
                return (v?.isEmpty == false) ? v : nil
            }

            // 3) youtube.com/shorts/<id>
            if url.path.contains("/shorts/") {
                let parts = url.path.split(separator: "/")
                if let idx = parts.firstIndex(of: "shorts"), idx + 1 < parts.count {
                    return String(parts[idx + 1])
                }
            }

            // 4) youtube.com/embed/<id>
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

// MARK: - Model local (somente para esta tela)
private struct TeacherYoutubeVideo: Identifiable, Equatable {
    let id: String
    let title: String
    let url: String
    let videoId: String
}

// MARK: - Sheet adicionar vídeo (incluído aqui para não dar "Cannot find ... in scope")
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

// MARK: - Reproduzir no app (TRAVADO) — WKWebView sem rolagem + bloqueio de links + AirPlay no header
private struct TeacherYoutubeLockedPlayerSheet: View {

    let title: String
    let videoId: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            LockedYoutubeWebView(videoId: videoId)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {

                    ToolbarItem(placement: .topBarLeading) {
                        Button("Fechar") { dismiss() }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        AirPlayRoutePicker()
                            .frame(width: 34, height: 34)
                            .accessibilityLabel("Reproduzir com AirPlay")
                    }
                }
                .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

private struct LockedYoutubeWebView: UIViewRepresentable {

    let videoId: String

    func makeUIView(context: Context) -> WKWebView {

        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.allowsAirPlayForMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = false

        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false

        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.scrollView.backgroundColor = UIColor.clear

        let urlString = "https://m.youtube.com/watch?v=\(videoId)&playsinline=1"
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, WKNavigationDelegate {

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

            if navigationAction.navigationType == .other {
                decisionHandler(.allow)
                return
            }

            decisionHandler(.cancel)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let js = """
            (function() {
                try {
                    document.documentElement.style.overflow = 'hidden';
                    document.body.style.overflow = 'hidden';
                    document.body.style.height = '100vh';
                    document.body.style.margin = '0';

                    var style = document.createElement('style');
                    style.innerHTML = `
                        header, ytm-pivot-bar, ytm-browse, ytm-item-section-renderer,
                        ytm-engagement-panel-section-list-renderer, ytm-comment-section-renderer,
                        ytm-slim-video-metadata-section-renderer,
                        ytm-video-with-context-renderer,
                        ytm-reel-shelf-renderer,
                        ytm-single-column-watch-next-results-renderer,
                        ytm-watch-next-secondary-results-renderer,
                        ytm-watch-next-feed,
                        #related, #secondary, #comments, #chips {
                            display: none !important;
                            visibility: hidden !important;
                            height: 0 !important;
                            overflow: hidden !important;
                        }
                        ytm-app, ytm-watch {
                            overflow: hidden !important;
                        }
                    `;
                    document.head.appendChild(style);

                    document.addEventListener('click', function(e) {
                        var a = e.target.closest('a');
                        if (a) { e.preventDefault(); e.stopPropagation(); }
                    }, true);
                } catch (e) {}
            })();
            """
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
}

// MARK: - AirPlay Picker (AVRoutePickerView)
private struct AirPlayRoutePicker: UIViewRepresentable {

    func makeUIView(context: Context) -> AVRoutePickerView {
        let v = AVRoutePickerView(frame: .zero)
        v.prioritizesVideoDevices = true
        v.activeTintColor = UIColor.systemGreen
        v.tintColor = UIColor.white.withAlphaComponent(0.90)
        return v
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) { }
}

