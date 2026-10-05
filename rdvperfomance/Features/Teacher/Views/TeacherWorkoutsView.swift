import SwiftUI

struct TeacherWorkoutsView: View {

    @Binding var path: [AppRoute]
    let category: TreinoTipo
    @Environment(\.selectTeacherMainSection) private var selectTeacherMainSection

    private let contentMaxWidth: CGFloat = 380

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

                ScrollView(.vertical, showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 0)

                        VStack(alignment: .leading, spacing: 14) {
                            quickAccessCard(
                                title: "ui.send_workout",
                                subtitle: "ui.send_a_workout_to_your_students",
                                icon: "paperplane.fill"
                            ) {
                                path.append(
                                    .teacherSendWorkout(
                                        preselectedStudentID: nil,
                                        startsAtWorkout: false
                                    )
                                )
                            }

                            quickAccessCard(
                                title: "ui.create_workout",
                                subtitle: "ui.create_a_new_workout",
                                icon: "plus.circle.fill"
                            ) {
                                path.append(.teacherMyWorkouts(category: category, mode: .create))
                            }

                            quickAccessCard(
                                title: "ui.workout_library",
                                subtitle: "ui.use_ready_made_templates",
                                icon: "square.grid.2x2.fill"
                            ) {
                                path.append(.teacherMyWorkouts(category: category, mode: .library))
                            }

                            quickAccessCard(
                                title: "tecnofit_import.import_action",
                                subtitle: "ui.import_workouts_from_a_spreadsheet",
                                icon: "doc.text.fill"
                            ) {
                                path.append(.teacherImportWorkouts(category: category))
                            }

                            quickAccessCard(
                                title: "ui.my_records",
                                subtitle: "ui.track_and_record_your_results",
                                icon: "trophy.fill"
                            ) {
                                path.append(.teacherPersonalRecords(category: category))
                            }

                            quickAccessCard(
                                title: "workout.my_videos",
                                subtitle: "ui.organize_your_videos",
                                icon: "video.fill"
                            ) {
                                path.append(.teacherImportVideos(category: category))
                            }
                        }
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 16)

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

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
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.footerBackground)
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {

            ToolbarItem(placement: .topBarLeading) {
                Button { selectTeacherMainSection(.home) } label: {
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
                Text("ui.workouts")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .topBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func quickAccessCard(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Color.green.opacity(0.14))
                        .frame(width: 34, height: 34)

                    Image(systemName: icon)
                        .foregroundColor(.green.opacity(0.85))
                        .font(.system(size: 16, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                        .lineLimit(2)

                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.55))
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.35))
            }
            .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.72))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.Colors.primaryGreen.opacity(0.28), lineWidth: 1)
            )
            .shadow(color: Theme.Colors.primaryGreen.opacity(0.12), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}
