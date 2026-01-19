import SwiftUI
import FirebaseAuth

struct TeacherImportVideosView: View {
    
    @Binding var path: [AppRoute]
    let category: TreinoTipo
    
    private let contentMaxWidth: CGFloat = 380
    
    @State private var videos: [TeacherYoutubeVideo] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var isAddSheetPresented: Bool = false
    @State private var activeLockedPlayer: LockedPlayerItem? = nil
    
    // ✅ Enviar vídeo para aluno (igual ao fluxo do Girls WODs)
    @State private var activeSheet: ActiveSheet? = nil
    
    private enum ActiveSheet: Identifiable {
        case send(TeacherYoutubeVideo)
        
        var id: String {
            switch self {
            case .send(let v):
                return "send-\(v.id)"
            }
        }
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
        .sheet(isPresented: $isAddSheetPresented) {
            TeacherAddYoutubeVideoSheet { title, url, videoCategory in
                Task { await addVideo(title: title, url: url, videoCategory: videoCategory) }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .send(let v):
                TeacherSendYoutubeVideoToStudentSheet(
                    video: v,
                    category: category
                )
            }
        }
        .fullScreenCover(item: $activeLockedPlayer) { item in
            TeacherYoutubeLockedPlayerSheet(title: item.title, videoId: item.videoId)
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
    
    private func openLockedPlayer(for video: TeacherYoutubeVideo) {
        activeLockedPlayer = LockedPlayerItem(
            title: video.title.isEmpty ? "Vídeo do YouTube" : video.title,
            videoId: video.videoId
        )
    }
    
    private func openSendToStudent(for video: TeacherYoutubeVideo) {
        errorMessage = nil
        activeSheet = .send(video)
    }
    
    private func videoRow(video v: TeacherYoutubeVideo) -> some View {
        HStack(spacing: 12) {
            thumbnailView(videoId: v.videoId)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(v.title.isEmpty ? "Vídeo do YouTube" : v.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(1)
                
                Text(v.category.rawValue)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(1)
            }
            
            Spacer()
            
            Menu {
                Button {
                    openSendToStudent(for: v)
                } label: {
                    Label("Enviar para aluno", systemImage: "paperplane.fill")
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
        .onTapGesture {
            openLockedPlayer(for: v)
        }
    }
    
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
            
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.45))
                Image(systemName: "play.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.95))
                    .padding(.leading, 1)
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
            
            Text("Toque em \"Adicionar Vídeo\" para salvar um link do YouTube.")
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
    
    private func loadVideos() async {
        errorMessage = nil
        
        guard let teacherId = TeacherYoutubeVideosRepository.getTeacherId() else {
            videos = []
            errorMessage = "Não foi possível identificar o professor logado."
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            videos = try await TeacherYoutubeVideosRepository.loadVideos(teacherId: teacherId)
        } catch {
            videos = []
            errorMessage = error.localizedDescription
        }
    }
    
    private func addVideo(title: String, url: String, videoCategory: TeacherYoutubeVideoCategory) async {
        errorMessage = nil
        
        guard let teacherId = TeacherYoutubeVideosRepository.getTeacherId() else {
            errorMessage = "Não foi possível identificar o professor logado."
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await TeacherYoutubeVideosRepository.addVideo(
                teacherId: teacherId,
                title: title,
                url: url,
                videoCategory: videoCategory
            )
            await loadVideos()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func deleteVideo(videoId: String) async {
        errorMessage = nil
        
        guard let teacherId = TeacherYoutubeVideosRepository.getTeacherId() else {
            errorMessage = "Não foi possível identificar o professor logado."
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await TeacherYoutubeVideosRepository.deleteVideo(teacherId: teacherId, videoId: videoId)
            await loadVideos()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

