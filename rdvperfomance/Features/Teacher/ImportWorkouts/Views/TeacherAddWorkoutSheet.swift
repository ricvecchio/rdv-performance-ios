import SwiftUI

struct TeacherAddWorkoutSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.appTheme) private var appTheme

    // Paleta do Tema Claro (mesmos valores da `LightColors` da TrainingWeeksView)
    private enum LightColors {
        static let cardSurface = Color(red: 0xDD / 255, green: 0xED / 255, blue: 0xDC / 255)  // #DDEDDC
        static let innerSurface = Color(red: 0xF0 / 255, green: 0xF7 / 255, blue: 0xEF / 255) // #F0F7EF
        static let iconSurface = Color(red: 0x85 / 255, green: 0xC9 / 255, blue: 0x95 / 255)  // #85C995
        static let iconInk = Color(red: 0x25 / 255, green: 0x48 / 255, blue: 0x2B / 255)      // #25482B
        static let primaryText = Color(red: 0x17 / 255, green: 0x1C / 255, blue: 0x17 / 255)  // #171C17
        static let chevron = Color(red: 0x29 / 255, green: 0x4A / 255, blue: 0x2F / 255)      // #294A2F
        static let border = Color(red: 0xC9 / 255, green: 0xDF / 255, blue: 0xC9 / 255)       // #C9DFC9
    }
    
    @State private var title: String = ""
    @State private var sheetMessage: String? = nil
    @State private var sheetMessageIsError: Bool = false
    
    let onSave: (_ title: String) -> Void
    
    private let contentMaxWidth: CGFloat = 380
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppThemeBackgroundImage()
                
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Theme.Colors.divider)
                        .frame(height: 1)
                    
                    ScrollView(showsIndicators: false) {
                        HStack {
                            Spacer(minLength: 0)
                            
                            VStack(alignment: .leading, spacing: 14) {
                                Text("ui.enter_a_workout_title")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Theme.Colors.ink(0.65))
                                
                                formCard
                                
                                HStack(spacing: 10) {
                                    Button {
                                        let t = title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                                        if t.isEmpty {
                                            sheetMessage = AppLocalization.string("ui.enter_the_workout_title",
                                                locale: locale
                                            )
                                            sheetMessageIsError = true
                                            return
                                        }
                                        
                                        onSave(t)
                                        dismiss()
                                    } label: {
                                        HStack(spacing: 10) {
                                            Image(systemName: "checkmark")
                                                .appThemeIconForeground()
                                            Text("common.save")
                                        }
                                        .padding(.horizontal, 14)
                                        .primaryGreenActionButton()
                                        // Tema Claro: contorno #294A2F sobre a borda original (mesmo raio e espessura). Tema Escuro: inalterado.
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(appTheme == .light ? LightColors.chevron : Color.clear, lineWidth: 1)
                                        )
                                        .shadow(
                                            color: appTheme == .light ? .black.opacity(0.25) : .clear,
                                            radius: appTheme == .light ? 10 : 0,
                                            y: appTheme == .light ? 6 : 0
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Spacer(minLength: 0)
                                }
                                
                                if let msg = sheetMessage {
                                    sheetMessageCard(text: msg, isError: sheetMessageIsError)
                                }
                                
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
            .navigationTitle("ui.add_workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.close") { dismiss() }
                }
            }
            .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .appThemeNavigationBarColorScheme()
        }
    }
    
    private var formCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("ui.workout_title")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.ink(0.55))
                
                ZStack(alignment: .leading) {
                    if title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
                        Text("ui.e_g_workout_a_chest_and_triceps")
                            .foregroundStyle(Theme.Colors.ink(0.45))
                            .padding(.horizontal, 12)
                    }
                    
                    TextField("", text: $title)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(false)
                        .foregroundStyle(Theme.Colors.ink(0.92))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                }
                .background(Theme.Colors.ink(0.10))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppThemeColor(dark: Theme.Colors.ink(0.12).dark, light: LightColors.chevron), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.cardSurface))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.chevron), lineWidth: 1)
        )
        .shadow(
            color: appTheme == .light ? .black.opacity(0.25) : .clear,
            radius: appTheme == .light ? 10 : 0,
            y: appTheme == .light ? 6 : 0
        )
    }
    
    private func sheetMessageCard(text: String, isError: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundColor(isError ? .yellow.opacity(0.85) : .green.opacity(0.85))
            
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.ink(0.75))
            
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.cardSurface))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    appTheme == .light
                        ? AnyShapeStyle(LightColors.chevron)
                        : AnyShapeStyle(AppThemeAdaptiveColor(isError ? Color.white.opacity(0.10) : Theme.Colors.primaryGreen.opacity(0.28))),
                    lineWidth: 1
                )
        )
        .shadow(
            color: appTheme == .light ? .black.opacity(0.25) : .clear,
            radius: appTheme == .light ? 10 : 0,
            y: appTheme == .light ? 6 : 0
        )
    }
}
