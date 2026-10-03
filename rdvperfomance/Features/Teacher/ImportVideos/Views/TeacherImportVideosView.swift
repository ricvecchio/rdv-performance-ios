import SwiftUI
import FirebaseAuth
import FirebaseFirestore

enum TeacherImportVideosContext {
    case teacher(category: TreinoTipo)
    case student(studentId: String)
}

struct TeacherImportVideosView: View {
    @Environment(\.locale) private var locale
    
    @Binding var path: [AppRoute]
    let context: TeacherImportVideosContext
    
    private let contentMaxWidth: CGFloat = 380
    
    @State private var videos: [TeacherYoutubeVideo] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var isAddSheetPresented: Bool = false
    @State private var activeLockedPlayer: LockedPlayerItem? = nil
    @State private var isEditTitleSheetOpen = false
    @State private var editingVideo: TeacherYoutubeVideo? = nil
    @State private var editingVideoTitle = ""
    @State private var isSavingVideoTitle = false
    @State private var editTitleErrorMessage: String? = nil
    
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
                
                footer
                .frame(height: Theme.Layout.footerHeight)
                .background(Theme.Colors.footerBackground)
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
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
                Text("workout.my_videos")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await loadVideos() }
        .sheet(isPresented: $isAddSheetPresented) {
            TeacherAddYoutubeVideoSheet { title, url, videoCategory in
                Task { await addVideo(title: title, url: url, videoCategory: videoCategory) }
            }
        }
        .sheet(isPresented: $isEditTitleSheetOpen) {
            editVideoTitleSheet
        }
        .fullScreenCover(item: $activeLockedPlayer) { item in
            TeacherYoutubeLockedPlayerSheet(title: item.title, videoId: item.videoId)
        }
    }

    @ViewBuilder
    private var footer: some View {
        switch context {
        case .teacher(let category):
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
        case .student(_):
            FooterBar(
                path: $path,
                kind: .studentHomeTreinosRecordsProfile(
                    isHomeSelected: false,
                    isTreinosSelected: false,
                    isRecordsSelected: true,
                    isPerfilSelected: false
                )
            )
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ui.save_youtube_links_to_view_later")
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
            HStack(spacing: 10) {
                Image(systemName: "plus")
                Text("ui.add_video")
            }
            .padding(.horizontal, 14)
            .compactPrimaryGreenActionButton()
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
            title: video.title.isEmpty
                ? String(localized: "workout.youtube_video", locale: locale)
                : video.title,
            videoId: video.videoId
        )
    }
    
    private func openSendToStudent(for video: TeacherYoutubeVideo) {
        errorMessage = nil
        path.append(
            .teacherSendWorkout(
                preselectedVideo: TeacherSendWorkoutVideo(video: video)
            )
        )
    }

    private func openEditTitle(for video: TeacherYoutubeVideo) {
        errorMessage = nil
        editTitleErrorMessage = nil
        editingVideo = video
        editingVideoTitle = video.title
        isEditTitleSheetOpen = true
    }

    private var editVideoTitleSheet: some View {
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

                        Text("ui.edit_title")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 4)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("ui.title")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.75))

                            TextField("", text: $editingVideoTitle)
                                .textInputAutocapitalization(.sentences)
                                .autocorrectionDisabled(false)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.92))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.10))
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                                )

                            if let editTitleErrorMessage {
                                Text(editTitleErrorMessage)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.yellow.opacity(0.85))
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
                    Button("common.cancel") {
                        isEditTitleSheetOpen = false
                    }
                    .buttonStyle(.plain)
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
                    .disabled(isSavingVideoTitle)

                    Button {
                        Task { await saveEditedVideoTitle() }
                    } label: {
                        HStack(spacing: 10) {
                            if isSavingVideoTitle {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "checkmark")
                                Text("common.save")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .primaryGreenActionButton()
                    }
                    .buttonStyle(.plain)
                    .disabled(isSavingVideoTitle)
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 16)
            }
        }
        .presentationDetents([.fraction(0.45)])
    }
    
    private func videoRow(video v: TeacherYoutubeVideo) -> some View {
        HStack(spacing: 12) {
            thumbnailView(videoId: v.videoId)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(v.title.isEmpty ? String(localized: "workout.youtube_video", locale: locale) : v.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(1)
                
                Text(v.category.localizedTitle)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(1)
            }
            
            Spacer()
            
            Menu {
                switch context {
                case .teacher:
                    Button {
                        openSendToStudent(for: v)
                    } label: {
                        Label(LocalizedStringKey("ui.send_to_student"), systemImage: "paperplane.fill")
                    }

                    Button {
                        openEditTitle(for: v)
                    } label: {
                        Label(LocalizedStringKey("ui.edit_title"), systemImage: "pencil")
                    }
                case .student:
                    Button {
                        openEditTitle(for: v)
                    } label: {
                        Label(LocalizedStringKey("ui.edit_video"), systemImage: "pencil")
                    }
                }

                Button(role: .destructive) {
                    Task { await deleteVideo(videoId: v.id) }
                } label: {
                    Label(LocalizedStringKey("ui.remove"), systemImage: "trash.fill")
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
            Text("ui.loading")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }
    
    private var emptyView: some View {
        VStack(spacing: 10) {
            Text("ui.no_video_registered")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))
            
            Text("ui.tap_add_video_to_save_youtube_link")
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
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            switch context {
            case .teacher:
                guard let teacherId = TeacherYoutubeVideosRepository.getTeacherId() else {
                    videos = []
                    errorMessage = String(localized: "ui.unable_to_identify_the_signed_in_trainer", locale: locale)
                    return
                }
                videos = try await TeacherYoutubeVideosRepository.loadVideos(teacherId: teacherId)
            case .student(let studentId):
                guard let authenticatedStudentId = validatedStudentId(studentId) else {
                    videos = []
                    return
                }
#if DEBUG
                print("[StudentVideos] Auth UID: \(Auth.auth().currentUser?.uid ?? "nil")")
                print("[StudentVideos] Student ID: \(studentId)")
                print("[StudentVideos] Firestore path: users/\(authenticatedStudentId)/youtubeVideos")
#endif
                videos = try await TeacherYoutubeVideosRepository.loadStudentVideos(
                    studentId: authenticatedStudentId
                )
            }
        } catch {
#if DEBUG
            if case .student = context {
                let ns = error as NSError
                print("[StudentVideos] Firestore error domain: \(ns.domain)")
                print("[StudentVideos] Firestore error code: \(ns.code)")
                print("[StudentVideos] Firestore error: \(ns.localizedDescription)")
            }
#endif
            videos = []
            errorMessage = mapImportPermissionError(error)
        }
    }

    private func addVideo(title: String, url: String, videoCategory: TeacherYoutubeVideoCategory) async {
        errorMessage = nil
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            switch context {
            case .teacher:
                guard let teacherId = TeacherYoutubeVideosRepository.getTeacherId() else {
                    errorMessage = String(localized: "ui.unable_to_identify_the_signed_in_trainer", locale: locale)
                    return
                }
                try await TeacherYoutubeVideosRepository.addVideo(
                    teacherId: teacherId,
                    title: title,
                    url: url,
                    videoCategory: videoCategory
                )
            case .student(let studentId):
                guard let authenticatedStudentId = validatedStudentId(studentId) else {
                    return
                }
#if DEBUG
                print("[StudentVideos] Auth UID: \(Auth.auth().currentUser?.uid ?? "nil")")
                print("[StudentVideos] Student ID: \(studentId)")
                print("[StudentVideos] Firestore path: users/\(authenticatedStudentId)/youtubeVideos")
#endif
                try await TeacherYoutubeVideosRepository.addStudentVideo(
                    studentId: authenticatedStudentId,
                    title: title,
                    url: url,
                    videoCategory: videoCategory
                )
            }
            await loadVideos()
        } catch {
#if DEBUG
            if case .student = context {
                let ns = error as NSError
                print("[StudentVideos] Firestore error domain: \(ns.domain)")
                print("[StudentVideos] Firestore error code: \(ns.code)")
                print("[StudentVideos] Firestore error: \(ns.localizedDescription)")
            }
#endif
            errorMessage = mapImportPermissionError(error)
        }
    }

    @MainActor
    private func saveEditedVideoTitle() async {
        editTitleErrorMessage = nil

        guard let video = editingVideo else { return }

        let cleanedTitle = editingVideoTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let updateTitle: () async throws -> Void
        switch context {
        case .teacher:
            guard let teacherId = TeacherYoutubeVideosRepository.getTeacherId() else {
                editTitleErrorMessage = String(localized: "ui.unable_to_identify_the_signed_in_trainer", locale: locale)
                return
            }
            updateTitle = {
                try await TeacherYoutubeVideosRepository.updateVideoTitle(
                    teacherId: teacherId,
                    videoId: video.id,
                    title: cleanedTitle
                )
            }
        case .student(let studentId):
            guard let authenticatedStudentId = validatedStudentId(studentId) else {
                editTitleErrorMessage = errorMessage
                return
            }
            updateTitle = {
                try await TeacherYoutubeVideosRepository.updateStudentVideoTitle(
                    studentId: authenticatedStudentId,
                    videoId: video.id,
                    title: cleanedTitle
                )
            }
        }

        isSavingVideoTitle = true
        defer { isSavingVideoTitle = false }

        do {
            try await updateTitle()

            if let index = videos.firstIndex(where: { $0.id == video.id }) {
                videos[index] = TeacherYoutubeVideo(
                    id: video.id,
                    title: cleanedTitle,
                    url: video.url,
                    videoId: video.videoId,
                    category: video.category
                )
            }

            isEditTitleSheetOpen = false
            editingVideo = nil
            editingVideoTitle = ""
        } catch {
            switch context {
            case .teacher:
                editTitleErrorMessage = error.localizedDescription
            case .student:
                editTitleErrorMessage = mapImportPermissionError(error)
            }
        }
    }
    
    private func deleteVideo(videoId: String) async {
        errorMessage = nil
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            switch context {
            case .teacher:
                guard let teacherId = TeacherYoutubeVideosRepository.getTeacherId() else {
                    errorMessage = String(localized: "ui.unable_to_identify_the_signed_in_trainer", locale: locale)
                    return
                }
                try await TeacherYoutubeVideosRepository.deleteVideo(
                    teacherId: teacherId,
                    videoId: videoId
                )
            case .student(let studentId):
                guard let authenticatedStudentId = validatedStudentId(studentId) else {
                    return
                }
#if DEBUG
                print("[StudentVideos] Auth UID: \(Auth.auth().currentUser?.uid ?? "nil")")
                print("[StudentVideos] Student ID: \(studentId)")
                print("[StudentVideos] Firestore path: users/\(authenticatedStudentId)/youtubeVideos")
#endif
                try await TeacherYoutubeVideosRepository.deleteStudentVideo(
                    studentId: authenticatedStudentId,
                    videoId: videoId
                )
            }
            await loadVideos()
        } catch {
#if DEBUG
            if case .student = context {
                let ns = error as NSError
                print("[StudentVideos] Firestore error domain: \(ns.domain)")
                print("[StudentVideos] Firestore error code: \(ns.code)")
                print("[StudentVideos] Firestore error: \(ns.localizedDescription)")
            }
#endif
            errorMessage = mapImportPermissionError(error)
        }
    }

    private func validatedStudentId(_ studentId: String) -> String? {
        let expectedStudentId = studentId.trimmingCharacters(in: .whitespacesAndNewlines)
        let authenticatedStudentId = (Auth.auth().currentUser?.uid ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !expectedStudentId.isEmpty,
              expectedStudentId == authenticatedStudentId
        else {
            errorMessage = String(localized: "ui.unable_to_validate_your_authentication_to_access_your_videos", locale: locale)
            return nil
        }

        return authenticatedStudentId
    }
    
    private func mapImportPermissionError(_ error: Error) -> String {
        let ns = error as NSError
        
        if ns.domain == FirestoreErrorDomain,
           ns.code == FirestoreErrorCode.permissionDenied.rawValue {
            return permissionErrorMessage
        }
        
        let msg = error.localizedDescription
        if msg.contains("Missing or insufficient permissions") {
            return permissionErrorMessage
        }
        
        return msg
    }

    private var permissionErrorMessage: String {
        switch context {
        case .teacher:
            return String(
                localized: "ui.no_permission_to_access_import_videos_verify_that_you_are_signed_in_and_that_your_user_type_is_coach_trainer",
                locale: locale
            )
        case .student:
            return String(
                localized: "ui.no_permission_to_access_your_videos_verify_your_authentication_and_try_again",
                locale: locale
            )
        }
    }
    
    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
