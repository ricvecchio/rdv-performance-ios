// Tela de perfil com informações do usuário e opções
import SwiftUI
import PhotosUI
import UIKit
import FirebaseFirestore

struct ProfileView: View {

    @Binding var path: [AppRoute]
    let onBack: () -> Void
    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss

    private let contentMaxWidth: CGFloat = 380

    @AppStorage("ultimoTreinoSelecionado")
    private var ultimoTreinoSelecionado: String = TreinoTipo.crossfit.rawValue

    private var categoriaAtualProfessor: TreinoTipo {
        TreinoTipo(rawValue: ultimoTreinoSelecionado) ?? .crossfit
    }

    @AppStorage("profile_photo_data")
    private var profilePhotoBase64: String = ""

    private let repository: FirestoreRepository = .shared

    private var currentUid: String {
        (session.currentUid ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @State private var userName: String = ""
    @State private var unitName: String = ""
    @State private var isLoading: Bool = false

    @State private var studentDefaultCategoryRaw: String = ""
    @State private var studentEmail: String = ""
    @State private var userPhone: String = ""
    @State private var userCref: String = ""
    @State private var userBio: String = ""


    private var categoriaAtualAluno: TreinoTipo {
        let raw = studentDefaultCategoryRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let t = TreinoTipo(rawValue: raw), !raw.isEmpty {
            return t
        }
        return TreinoTipo(rawValue: ultimoTreinoSelecionado) ?? .crossfit
    }

    private var preferredWeightUnit: WeightUnit {
        WeightUnit(rawValue: preferredWeightUnitRawState) ?? .kg
    }


    @State private var showTrocarUnidadeAlert: Bool = false
    @State private var unidadeDraft: String = ""

    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String? = nil

    @State private var showMeusIconesModal: Bool = false
    @State private var copiedIconName: String? = nil
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showPhotoPicker: Bool = false
    @State private var showAvatarPicker: Bool = false

    @State private var preferredWeightUnitRawState: String = WeightUnit.kg.rawValue
    @State private var draftWeightUnitRawState: String = WeightUnit.kg.rawValue
    @State private var showWeightUnitSheet: Bool = false

    @State private var unreadMessagesCount: Int = 0
    @State private var unreadFeedbacksCount: Int = 0
    @State private var teacherActivitiesCount: Int = 0
    @State private var hasAppeared: Bool = false

    private let studentActivityCategories: [TreinoTipo] = [.crossfit, .academia, .emCasa]
    private let preferredWeightUnitKey: String = "preferredWeightUnit"

    private var shouldBlurBackground: Bool {
        showWeightUnitSheet || showAvatarPicker
    }

    private let treinoIcons = [
        "dumbbell",
        "figure.run",
        "figure.walk",
        "figure.strengthtraining.traditional",
        "heart.fill",
        "flame.fill",
        "bolt.fill",
        "stopwatch",
        "calendar",
        "checkmark.seal.fill",
        "chart.bar.fill",
        "person.2.fill",
        "figure.cross.training",
        "figure.cross.training.circle",
        "figure.flexibility",
        "figure.gymnastics",
        "figure.highintensity.intervaltraining",
        "figure.mixed.cardio",
        "figure.yoga",
        "figure.pilates",
        "figure.strengthtraining.functional",
        "figure.strengthtraining.functional.circle",
        "figure.cooldown",
        "figure.core.training",
        "figure.arms.open",
        "figure.stand",
        "figure.squat",
        "figure.lunge",
        "figure.rower",
        "figure.stair.stepper",
        "figure.outdoor.cycle",
        "figure.indoor.cycle",
        "figure.jumprope",
        "figure.hiking",
        "dumbbell.fill",
        "backpack.fill",
        "waterbottle.fill",
        "timer",
        "speedometer",
        "target",
        "scope",
        "line.diagonal.arrow",
        "arrow.triangle.2.circlepath",
        "lungs.fill",
        "waveform.path.ecg",
        "heart.text.square.fill",
        "figure.mind.and.body",
        "chart.line.uptrend.xyaxis",
        "chart.pie.fill",
        "medal.fill",
        "trophy.fill",
        "star.fill",
        "crown.fill",
        "flag.checkered",
        "figure.boxing",
        "figure.climbing",
        "figure.fall",
        "figure.handball",
        "figure.rolling",
        "figure.surfing",
        "bolt.badge.a.fill",
        "bolt.trianglebadge.exclamationmark.fill",
        "cablecar.fill",
        "chevron.up.square.fill",
        "cylinder.split.1x2.fill",
        "figure.2.arms.open",
        "figure.seated.seatbelt",
        "hand.raised.square.fill",
        "heart_square.fill",
        "lanyardcard.fill",
        "macpro.gen3.fill",
        "oval.fill",
        "oval.portrait.fill",
        "pill.fill",
        "play.square.fill",
        "powerplug.fill",
        "restart.circle.fill",
        "road.lanes.curved.left",
        "squareshape.dotted.squareshape",
        "trapezoid.and.line.horizontal.fill",
        "triangle.fill",
        "wrench.adjustable.fill",
        "arrow.up.and.down.circle.fill",
        "arrow.uturn.up.circle.fill",
        "circle.grid.cross.fill",
        "figure.core.training.circle.fill",
        "figure.open.water.swim",
        "rotate.3d.fill",
        "bandage.fill",
        "bell.and.waves.left.and.right.fill",
        "handbag.fill",
        "headphones.circle.fill",
        "lock.shield.fill",
        "shoe.circle.fill",
        "wave.3.backward.circle.fill",
        "gauge.with.dots.needle.bottom.0percent",
        "gauge.with.dots.needle.bottom.50percent",
        "gauge.with.dots.needle.bottom.100percent",
        "barometer",
        "thermometer",
        "wind",
        "list.bullet.rectangle.fill",
        "list.clipboard.fill",
        "menucard.fill",
        "tablecells.fill",
        "tag.fill",
        "text.page",
        "wifi.router.fill",
        "flag.2.crossed.fill",
        "hourglass",
        "lines.measurement.horizontal",
        "sportscourt",
        "stairs",
        "bed.double.fill",
        "drop.fill",
        "fork.knife",
        "tshirt.fill",
        "wind.snow.circle.fill",
        "person.3.fill",
        "megaphone.fill",
        "plus.bubble.fill",
        "quote.bubble.fill",
        "video.fill"
    ]

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
                            profileCard()
                            optionsCard()
                            logoutButton()
                            Color.clear.frame(height: 18)
                        }
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        Spacer(minLength: 0)
                    }
                }

                footerForUser()
                    .frame(height: Theme.Layout.footerHeight)
                    .frame(maxWidth: .infinity)
                    .background(Theme.Colors.footerBackground)
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
        .blur(radius: shouldBlurBackground ? 4 : 0)
        .animation(.easeInOut(duration: 0.20), value: shouldBlurBackground)
        .navigationBarBackButtonHidden(true)
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
                Text("Perfil")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    path.append(.configuracoes)
                } label: {
                    ZStack {
                        Color.clear
                            .frame(width: 44, height: 44)

                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.green)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Trocar unidade", isPresented: $showTrocarUnidadeAlert) {
            TextField("Ex.: CROSSFIT MURALHA", text: $unidadeDraft)

            Button("Cancelar", role: .cancel) { }

            Button("Salvar") {
                Task { await salvarUnidade() }
            }
        } message: {
            Text("Digite a unidade onde você treina. Se deixar em branco, a unidade será removida do perfil.")
        }
        .alert("Erro", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {
                showErrorAlert = false
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
        .sheet(isPresented: $showMeusIconesModal) {
            meusIconesModal()
        }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedPhotoItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task { await saveSelectedPhoto(from: newItem) }
        }
        .sheet(isPresented: $showAvatarPicker) {
            EditProfileView.AvatarPickerView { image in
                showAvatarPicker = false
                Task { await saveProfileAvatar(image) }
            }
        }
        .sheet(isPresented: $showWeightUnitSheet) {
            WeightUnitSheetView(
                selectedUnitRaw: $draftWeightUnitRawState,
                onCancel: {
                    showWeightUnitSheet = false
                },
                onSave: {
                    preferredWeightUnitRawState = draftWeightUnitRawState
                    showWeightUnitSheet = false
                }
            )
            .presentationDetents([.fraction(0.50)])
        }
        .task(id: currentUid) {
            if session.isStudent || session.isTrainer {
                preferredWeightUnitRawState = UserDefaults.standard.string(
                    forKey: preferredWeightUnitKey
                ) ?? WeightUnit.kg.rawValue
            }
            await loadUserData()
            await loadProfileActivityCounts()
        }
        .onChange(of: preferredWeightUnitRawState) { _, newValue in
            if session.isStudent || session.isTrainer {
                UserDefaults.standard.set(newValue, forKey: preferredWeightUnitKey)
                saveMeasurementUnit(newValue)
            }
        }
        .onAppear {
            guard hasAppeared else {
                hasAppeared = true
                return
            }
            Task {
                await loadUserData()
                await loadProfileActivityCounts()
            }
        }
    }

    @ViewBuilder
    private func footerForUser() -> some View {
        if session.isStudent {
            FooterBar(
                path: $path,
                kind: .studentHomeTreinosRecordsProfile(
                    isHomeSelected: false,
                    isTreinosSelected: false,
                    isRecordsSelected: false,
                    isPerfilSelected: true
                )
            )
        } else {
            FooterBar(
                path: $path,
                kind: .teacherHomeAlunosSobrePerfil(
                    selectedCategory: categoriaAtualProfessor,
                    isHomeSelected: false,
                    isAlunosSelected: false,
                    isSobreSelected: false,
                    isPerfilSelected: true
                )
            )
        }
    }

    private func pop() {
        onBack()
    }

    private func loadUserData() async {
        let uid = currentUid
        guard !uid.isEmpty else {
            userName = ""
            unitName = ""
            studentDefaultCategoryRaw = ""
            studentEmail = ""
            userPhone = ""
            userCref = ""
            userBio = ""
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            if let user = try await repository.getUser(uid: uid) {
                userName = user.name.trimmingCharacters(in: .whitespacesAndNewlines)
                unitName = (user.unitName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                studentDefaultCategoryRaw = (user.defaultCategory ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                studentEmail = user.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                userPhone = BrazilianPhoneFormatter.normalize(user.phone ?? "")
                userCref = (user.cref ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                userBio = (user.bio ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                userName = ""
                unitName = ""
                studentDefaultCategoryRaw = ""
                studentEmail = ""
                userPhone = ""
                userCref = ""
                userBio = ""
            }

        } catch {
            userName = ""
            unitName = ""
            studentDefaultCategoryRaw = ""
            studentEmail = ""
            userPhone = ""
            userCref = ""
            userBio = ""
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    private func loadProfileActivityCounts() async {
        let uid = currentUid
        guard session.isStudent, !uid.isEmpty else {
            unreadMessagesCount = 0
            unreadFeedbacksCount = 0
            teacherActivitiesCount = 0
            return
        }

        async let remoteState = fetchProfileNotificationState(for: uid)
        async let messages = messagesByCategory(for: uid, categories: studentActivityCategories)
        async let feedbacks = feedbacksByCategory(for: uid, categories: studentActivityCategories)
        async let teacherActivities = teacherActivityData(for: uid, email: studentEmail)

        let (state, messagesByCategory, feedbacksByCategory, activityData) = await (
            remoteState,
            messages,
            feedbacks,
            teacherActivities
        )
        guard currentUid == uid, session.isStudent else { return }

        let notificationState = state ?? ProfileNotificationState(
            messagesLastSeenByCategory: [:],
            feedbacksLastSeenByCategory: [:],
            teacherActivitiesLastSeen: nil
        )

        unreadMessagesCount = unreadMessages(
            messagesByCategory,
            for: uid,
            remoteState: notificationState
        )
        unreadFeedbacksCount = unreadFeedbacks(
            feedbacksByCategory,
            for: uid,
            remoteState: notificationState
        )
        teacherActivitiesCount = unreadTeacherActivities(
            activityData,
            for: uid,
            remoteState: notificationState
        )

        if let state {
            persistLocalNotificationStateIfNewer(for: uid, than: state)
        }
    }

    private func fetchProfileNotificationState(for uid: String) async -> ProfileNotificationState? {
        do {
            return try await repository.getProfileNotificationState(uid: uid)
        } catch {
            return nil
        }
    }

    private func messagesByCategory(
        for uid: String,
        categories: [TreinoTipo]
    ) async -> [String: [TeacherMessageFS]] {
        let repo = repository
        return await withTaskGroup(of: (String, [TeacherMessageFS]).self, returning: [String: [TeacherMessageFS]].self) { group in
            for category in categories {
                let categoryRaw = category.rawValue
                group.addTask {
                    do {
                        return (
                            categoryRaw,
                            try await repo.getMessagesForStudent(
                                studentId: uid,
                                categoryRaw: categoryRaw,
                                limit: 100
                            )
                        )
                    } catch {
                        return (categoryRaw, [])
                    }
                }
            }

            var messagesByCategory: [String: [TeacherMessageFS]] = [:]
            for await (category, messages) in group {
                messagesByCategory[category] = messages
            }
            return messagesByCategory
        }
    }

    private func feedbacksByCategory(
        for uid: String,
        categories: [TreinoTipo]
    ) async -> [String: [StudentFeedbackFS]] {
        let repo = repository
        return await withTaskGroup(of: (String, [StudentFeedbackFS]).self, returning: [String: [StudentFeedbackFS]].self) { group in
            for category in categories {
                let categoryRaw = category.rawValue
                group.addTask {
                    do {
                        return (
                            categoryRaw,
                            try await repo.getFeedbacksForStudent(
                                studentId: uid,
                                categoryRaw: categoryRaw,
                                limit: 100
                            )
                        )
                    } catch {
                        return (categoryRaw, [])
                    }
                }
            }

            var feedbacksByCategory: [String: [StudentFeedbackFS]] = [:]
            for await (category, feedbacks) in group {
                feedbacksByCategory[category] = feedbacks
            }
            return feedbacksByCategory
        }
    }

    private func teacherActivityData(
        for uid: String,
        email: String
    ) async -> (invites: [TeacherStudentInviteFS], requests: [TeacherStudentLinkRequestFS]) {
        do {
            async let invites = repository.getInvitesForStudent(studentEmail: email)
            async let requests = repository.getRequestsForStudent(studentId: uid)
            return try await (invites, requests)
        } catch {
            return ([], [])
        }
    }

    private func unreadMessages(
        _ messagesByCategory: [String: [TeacherMessageFS]],
        for uid: String,
        remoteState: ProfileNotificationState
    ) -> Int {
        studentActivityCategories.reduce(into: 0) { count, category in
            let categoryRaw = category.rawValue
            let lastSeen = effectiveLastSeen(
                local: UserDefaults.standard.object(
                    forKey: "profileMessagesLastSeen.\(uid).\(categoryRaw)"
                ) as? Date,
                remote: remoteState.messagesLastSeenByCategory[categoryRaw]
            )
            let messages = messagesByCategory[categoryRaw] ?? []
            if let lastSeen {
                count += messages.filter { ($0.createdAt ?? .distantPast) > lastSeen }.count
            } else {
                count += messages.count
            }
        }
    }

    private func unreadFeedbacks(
        _ feedbacksByCategory: [String: [StudentFeedbackFS]],
        for uid: String,
        remoteState: ProfileNotificationState
    ) -> Int {
        studentActivityCategories.reduce(into: 0) { count, category in
            let categoryRaw = category.rawValue
            let lastSeen = effectiveLastSeen(
                local: UserDefaults.standard.object(
                    forKey: "profileFeedbacksLastSeen.\(uid).\(categoryRaw)"
                ) as? Date,
                remote: remoteState.feedbacksLastSeenByCategory[categoryRaw]
            )
            let feedbacks = feedbacksByCategory[categoryRaw] ?? []
            if let lastSeen {
                count += feedbacks.filter { ($0.createdAt ?? .distantPast) > lastSeen }.count
            } else {
                count += feedbacks.count
            }
        }
    }

    private func unreadTeacherActivities(
        _ activityData: (invites: [TeacherStudentInviteFS], requests: [TeacherStudentLinkRequestFS]),
        for uid: String,
        remoteState: ProfileNotificationState
    ) -> Int {
        let lastSeen = effectiveLastSeen(
            local: UserDefaults.standard.object(forKey: "profileTeachersLastSeen.\(uid)") as? Date,
            remote: remoteState.teacherActivitiesLastSeen
        )
        let inviteCount = activityData.invites.filter {
            let status = $0.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard let lastSeen else { return status == "pending" }
            return (status == "pending" && ($0.createdAt?.dateValue() ?? .distantPast) > lastSeen)
                || ((status == "accepted" || status == "declined")
                    && ($0.updatedAt?.dateValue() ?? .distantPast) > lastSeen)
        }.count
        let requestCount = activityData.requests.filter {
            let status = $0.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard let lastSeen else {
                return status == "accepted" || status == "declined"
            }
            return (status == "accepted" || status == "declined")
                && ($0.updatedAt?.dateValue() ?? .distantPast) > lastSeen
        }.count

        return inviteCount + requestCount
    }

    private func effectiveLastSeen(local: Date?, remote: Date?) -> Date? {
        switch (local, remote) {
        case let (local?, remote?):
            return max(local, remote)
        case let (local?, nil):
            return local
        case let (nil, remote?):
            return remote
        case (nil, nil):
            return nil
        }
    }

    private func persistLocalNotificationStateIfNewer(
        for uid: String,
        than remoteState: ProfileNotificationState
    ) {
        var messages: [String: Date] = [:]
        var feedbacks: [String: Date] = [:]

        for category in studentActivityCategories {
            let categoryRaw = category.rawValue
            if let local = UserDefaults.standard.object(
                forKey: "profileMessagesLastSeen.\(uid).\(categoryRaw)"
            ) as? Date,
               local > (remoteState.messagesLastSeenByCategory[categoryRaw] ?? .distantPast) {
                messages[categoryRaw] = local
            }
            if let local = UserDefaults.standard.object(
                forKey: "profileFeedbacksLastSeen.\(uid).\(categoryRaw)"
            ) as? Date,
               local > (remoteState.feedbacksLastSeenByCategory[categoryRaw] ?? .distantPast) {
                feedbacks[categoryRaw] = local
            }
        }

        let teacherActivities = UserDefaults.standard.object(
            forKey: "profileTeachersLastSeen.\(uid)"
        ) as? Date
        let newerTeacherActivities = teacherActivities.flatMap {
            $0 > (remoteState.teacherActivitiesLastSeen ?? .distantPast) ? $0 : nil
        }

        persistNotificationState(
            for: uid,
            messages: messages,
            feedbacks: feedbacks,
            teacherActivities: newerTeacherActivities
        )
    }

    private func markMessagesAsSeen() {
        let uid = currentUid
        guard !uid.isEmpty else { return }
        let seenAt = Date()
        for category in studentActivityCategories {
            UserDefaults.standard.set(
                seenAt,
                forKey: "profileMessagesLastSeen.\(uid).\(category.rawValue)"
            )
        }
        unreadMessagesCount = 0
        persistNotificationState(
            for: uid,
            messages: Dictionary(uniqueKeysWithValues: studentActivityCategories.map { ($0.rawValue, seenAt) })
        )
    }

    private func markFeedbacksAsSeen() {
        let uid = currentUid
        guard !uid.isEmpty else { return }
        let seenAt = Date()
        for category in studentActivityCategories {
            UserDefaults.standard.set(
                seenAt,
                forKey: "profileFeedbacksLastSeen.\(uid).\(category.rawValue)"
            )
        }
        unreadFeedbacksCount = 0
        persistNotificationState(
            for: uid,
            feedbacks: Dictionary(uniqueKeysWithValues: studentActivityCategories.map { ($0.rawValue, seenAt) })
        )
    }

    private func markTeacherActivitiesAsSeen() {
        let uid = currentUid
        guard !uid.isEmpty else { return }
        let seenAt = Date()
        UserDefaults.standard.set(seenAt, forKey: "profileTeachersLastSeen.\(uid)")
        teacherActivitiesCount = 0
        persistNotificationState(for: uid, teacherActivities: seenAt)
    }

    private func persistNotificationState(
        for uid: String,
        messages: [String: Date] = [:],
        feedbacks: [String: Date] = [:],
        teacherActivities: Date? = nil
    ) {
        guard !uid.isEmpty else { return }
        let repo = repository
        Task {
            do {
                try await repo.mergeProfileNotificationState(
                    uid: uid,
                    messagesLastSeenByCategory: messages,
                    feedbacksLastSeenByCategory: feedbacks,
                    teacherActivitiesLastSeen: teacherActivities
                )
            } catch {
            }
        }
    }

    private func openTrocarUnidade() {
        unidadeDraft = unitName
        showTrocarUnidadeAlert = true
    }

    private func salvarUnidade() async {
        let uid = currentUid
        guard !uid.isEmpty else { return }

        let trimmed = unidadeDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        unitName = trimmed

        do {
            try await repository.setStudentUnitName(uid: uid, unitName: trimmed)
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    private func saveMeasurementUnit(_ rawValue: String) {
        guard !currentUid.isEmpty else {
            #if DEBUG
            print("[Profile] Não foi possível salvar a unidade de medida sem usuário autenticado.")
            #endif
            return
        }

        Task {
            do {
                try await repository.setMeasurementUnit(uid: currentUid, measurementUnit: rawValue)
                #if DEBUG
                print("[Profile] Unidade de medida salva remotamente.")
                #endif
            } catch {
                #if DEBUG
                print("[Profile] Falha ao salvar unidade de medida: \(error.localizedDescription)")
                #endif
            }
        }
    }

    private func saveSelectedPhoto(from item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data)
            else {
                errorMessage = "Não foi possível carregar a imagem selecionada."
                showErrorAlert = true
                return
            }

            _ = try await ProfilePhotoService.save(image, userId: currentUid)
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    private func saveProfileAvatar(_ image: UIImage) async {
        do {
            _ = try await ProfilePhotoService.save(image, userId: currentUid)
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    private func removePhoto() async {
        do {
            try await ProfilePhotoService.clear(userId: currentUid)
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    private func profileCard() -> some View {
        VStack(spacing: 10) {

            Menu {
                Button {
                    selectedPhotoItem = nil
                    showPhotoPicker = true
                } label: {
                    Label("Escolher foto", systemImage: "photo.fill")
                }

                Button {
                    showAvatarPicker = true
                } label: {
                    Label("Escolher Avatar", systemImage: "person.crop.circle")
                }

                Button(role: .destructive) {
                    Task { await removePhoto() }
                } label: {
                    Label("Remover foto", systemImage: "trash.fill")
                }
            } label: {
                HeaderAvatarView(size: 92, isNavigationEnabled: false)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.green)
                            .frame(width: 28, height: 28)
                            .background(Theme.Colors.cardBackground)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                            .offset(x: 2, y: 2)
                    }
            }
            .buttonStyle(.plain)

            Text(userName.isEmpty ? " " : userName)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)

            Text(unitName.isEmpty ? " " : unitName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.55))

            VStack(alignment: .leading, spacing: 4) {
                Color.clear.frame(height: 16)
                profileIconDetail(icon: "envelope.fill", value: studentEmail)
                profileIconDetail(
                    icon: "phone.circle.fill",
                    value: BrazilianPhoneFormatter.format(userPhone)
                )
                let trimmedCref = userCref.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedCref.isEmpty,
                   trimmedCref.caseInsensitiveCompare("N/A") != .orderedSame {
                    profileIconDetail(
                        icon: "person.text.rectangle.fill",
                        value: trimmedCref
                    )
                }
                let trimmedBio = userBio.trimmingCharacters(in: .whitespacesAndNewlines)
                profileIconDetail(icon: "text.quote", value: trimmedBio, alignment: .top)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 4)
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    @ViewBuilder
    private func profileDetail(_ title: String, _ value: String) -> some View {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            Text("\(title): \(trimmed)")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.65))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func profileIconDetail(
        icon: String,
        value: String,
        alignment: VerticalAlignment = .center
    ) -> some View {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            HStack(alignment: alignment, spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(.green)

                Text(trimmed)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.65))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func optionsCard() -> some View {
        VStack(spacing: 0) {

            if session.isAdmin {
                optionRow(
                    icon: "person.3.fill",
                    title: "Trocar perfil (Admin)",
                    trailing: .chevron,
                    iconColor: .red.opacity(0.85),
                    titleColor: .red.opacity(0.95)
                ) {
                    session.clearAdminProfileMode()
                }
                divider()
            }

            optionRow(icon: "ruler", title: "Trocar unidade", trailing: .chevron) {
                openTrocarUnidade()
            }

            if session.isStudent {
                divider()
                optionRow(
                    icon: "envelope.fill",
                    title: "Mensagens",
                    trailing: .chevron,
                    activityBadgeCount: unreadMessagesCount
                ) {
                    markMessagesAsSeen()
                    path.append(.studentMessages(category: categoriaAtualAluno))
                }

                divider()
                optionRow(
                    icon: "text.bubble.fill",
                    title: "Feedbacks",
                    trailing: .chevron,
                    activityBadgeCount: unreadFeedbacksCount
                ) {
                    markFeedbacksAsSeen()
                    path.append(.studentFeedbacks(category: categoriaAtualAluno))
                }

                divider()
                optionRow(
                    icon: "person.2.fill",
                    title: "Meus professores",
                    trailing: .chevron,
                    activityBadgeCount: teacherActivitiesCount
                ) {
                    markTeacherActivitiesAsSeen()
                    path.append(.studentTeachers(studentEmail: studentEmail))
                }

                divider()
                optionRow(
                    icon: "ruler.fill",
                    title: "Unidade de Medida",
                    trailing: .textWithChevron(preferredWeightUnit.shortLabel)
                ) {
                    draftWeightUnitRawState = preferredWeightUnitRawState
                    showWeightUnitSheet = true
                }
            }

            if session.isTrainer {
                divider()
                optionRow(
                    icon: "ruler.fill",
                    title: "Unidade de Medida",
                    trailing: .textWithChevron(preferredWeightUnit.shortLabel)
                ) {
                    draftWeightUnitRawState = preferredWeightUnitRawState
                    showWeightUnitSheet = true
                }
            }

            if session.isAdmin {
                divider()
                optionRow(icon: "square.grid.2x2.fill", title: "Meus Ícones", trailing: .chevron) {
                    showMeusIconesModal = true
                }
            }
        }
        .padding(.vertical, 8)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    private func divider() -> some View {
        Divider()
            .background(Theme.Colors.divider)
            .padding(.leading, 56)
    }

    private enum Trailing {
        case chevron
        case text(String)
        case badge(String)
        case coloredBadge(String, fg: Color, bg: Color)
        case coloredBadgeWithChevron(String, fg: Color, bg: Color)
        case textWithChevron(String)
        case settings
    }

    private func optionRow(
        icon: String,
        title: String,
        trailing: Trailing,
        activityBadgeCount: Int = 0,
        iconColor: Color = .green.opacity(0.85),
        titleColor: Color = .white.opacity(0.95),
        onTap: (() -> Void)? = nil
    ) -> some View {
        Group {
            if let onTap {
                Button(action: onTap) {
                    optionRowContent(
                        icon: icon,
                        title: title,
                        trailing: trailing,
                        activityBadgeCount: activityBadgeCount,
                        iconColor: iconColor,
                        titleColor: titleColor
                    )
                }
                .buttonStyle(.plain)
            } else {
                optionRowContent(
                    icon: icon,
                    title: title,
                    trailing: trailing,
                    activityBadgeCount: activityBadgeCount,
                    iconColor: iconColor,
                    titleColor: titleColor
                )
            }
        }
    }

    private func optionRowContent(
        icon: String,
        title: String,
        trailing: Trailing,
        activityBadgeCount: Int,
        iconColor: Color,
        titleColor: Color
    ) -> some View {
        HStack(spacing: 14) {

            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 28)
                .overlay(alignment: .topTrailing) {
                    if activityBadgeCount > 0 {
                        Text(verbatim: String(activityBadgeCount))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.red))
                            .offset(x: 4, y: -5)
                    }
                }

            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(titleColor)

            Spacer()

            switch trailing {
            case .chevron:
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.35))

            case .text(let value):
                Text(value)
                    .foregroundColor(.green.opacity(0.85))

            case .badge(let value):
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.green.opacity(0.9))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.green.opacity(0.16)))

            case .coloredBadge(let value, let fg, let bg):
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(fg)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(bg))

            case .coloredBadgeWithChevron(let value, let fg, let bg):
                HStack(spacing: 10) {
                    Text(value)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(fg)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(bg))

                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.35))
                }

            case .textWithChevron(let value):
                HStack(spacing: 10) {
                    Text(value)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.55))

                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.35))
                }

            case .settings:
                Image(systemName: "gearshape.fill")
                    .foregroundColor(.white.opacity(0.60))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private func logoutButton() -> some View {
        Button {
            session.logout()
        } label: {
            HStack {
                Spacer()
                Text("Sair")
                Spacer()
            }
            .primaryGreenActionButton()
        }
        .buttonStyle(.plain)
    }


    private func meusIconesModal() -> some View {
        NavigationStack {
            ZStack {
                Theme.Colors.headerBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 0)

                        VStack(alignment: .leading, spacing: 14) {
                            Text("Toque em um ícone para copiar o nome.")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.65))
                                .padding(.top, 12)

                            let columns: [GridItem] = [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ]

                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(treinoIcons, id: \.self) { iconName in
                                    Button {
                                        UIPasteboard.general.string = iconName
                                        copiedIconName = iconName
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                                            if copiedIconName == iconName {
                                                copiedIconName = nil
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: iconName)
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(.green.opacity(0.9))
                                                .frame(width: 28)

                                            Text(iconName)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.white.opacity(0.92))
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.85)

                                            Spacer(minLength: 0)
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity)
                                        .background(Theme.Colors.cardBackground)
                                        .cornerRadius(14)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            Color.clear.frame(height: 18)
                        }
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.horizontal, 16)

                        Spacer(minLength: 0)
                    }
                }

                if let copied = copiedIconName {
                    VStack {
                        Spacer()
                        Text("Copiado: \(copied)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.92))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.35))
                                    .overlay(
                                        Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1)
                                    )
                            )
                            .padding(.bottom, 18)
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.18), value: copiedIconName)
                }
            }
            .navigationTitle("Meus Ícones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") {
                        showMeusIconesModal = false
                    }
                    .foregroundColor(.green)
                }
            }
        }
    }
}
