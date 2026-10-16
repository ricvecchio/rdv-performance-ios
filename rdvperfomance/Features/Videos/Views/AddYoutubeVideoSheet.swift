import SwiftUI

struct AddYoutubeVideoSheet: View {
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

    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var url: String = ""
    @State private var selectedCategory: YoutubeVideoCategory = .crossfit
    @State private var sheetMessage: LocalizedStringKey? = nil
    @State private var sheetMessageIsError: Bool = false

    let onSave: (_ title: String, _ url: String, _ category: YoutubeVideoCategory) -> Void

    var body: some View {
        ZStack {
            Theme.Colors.sheetBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        Capsule()
                            .fill(Theme.Colors.ink(0.18))
                            .frame(width: 44, height: 5)
                            .padding(.top, 10)

                        Text("ui.add_video")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Theme.Colors.ink())
                            .padding(.top, 4)

                        VStack(alignment: .leading, spacing: 14) {
                            Text("ui.paste_the_youtube_link_and_add_a_title_to_make_it_easier_to_find")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.Colors.ink(0.45))

                            formFields

                            if let msg = sheetMessage {
                                sheetMessageCard(text: msg, isError: sheetMessageIsError)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.cardSurface))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.border), lineWidth: 1)
                        )
                        .shadow(
                            color: appTheme == .light ? .black.opacity(0.25) : .clear,
                            radius: appTheme == .light ? 10 : 0,
                            y: appTheme == .light ? 6 : 0
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
                                .appThemeIconForeground()
                            Text("ui.open_youtube")
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.85), light: LightColors.primaryText))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppThemeColor(dark: Color.white.opacity(0.10), light: LightColors.cardSurface))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppThemeColor(dark: Color.white.opacity(0.10), light: LightColors.border), lineWidth: 1)
                        )
                        .shadow(
                            color: appTheme == .light ? .black.opacity(0.25) : .clear,
                            radius: appTheme == .light ? 10 : 0,
                            y: appTheme == .light ? 6 : 0
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
                                .appThemeIconForeground()
                            Text("common.save")
                        }
                        .frame(maxWidth: .infinity)
                        .primaryGreenActionButton()
                        .shadow(
                            color: appTheme == .light ? .black.opacity(0.25) : .clear,
                            radius: appTheme == .light ? 10 : 0,
                            y: appTheme == .light ? 6 : 0
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 16)
            }
        }
        .presentationDetents([.fraction(2.0 / 3.0)])
    }
    
    private var formFields: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 8) {
                Text("ui.title_optional")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink(0.75))
                
                ZStack(alignment: .leading) {
                    TextField("", text: $title)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(false)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink(0.92))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                }
                .background(Theme.Colors.ink(0.10))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Theme.Colors.ink(0.10), lineWidth: 1)
                )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("ui.youtube_link")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink(0.75))
                
                ZStack(alignment: .leading) {
                    TextField("", text: $url)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink(0.92))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                }
                .background(Theme.Colors.ink(0.10))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Theme.Colors.ink(0.10), lineWidth: 1)
                )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("ui.video_category")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink(0.75))
                
                Picker("", selection: $selectedCategory) {
                    ForEach(YoutubeVideoCategory.allCases) { c in
                        Text(c.localizedTitle).tag(c)
                    }
                }
                .pickerStyle(.segmented)
                .padding(14)
                .background(Theme.Colors.ink(0.10))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Theme.Colors.ink(0.10), lineWidth: 1)
                )
            }
        }
    }
    
    private func sheetMessageCard(text: LocalizedStringKey, isError: Bool) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(isError ? .yellow.opacity(0.85) : .green.opacity(0.85))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func handleCopyYoutubeLink() {
        sheetMessage = nil
        sheetMessageIsError = false
        
        let clipboard = (UIPasteboard.general.string ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        if YouTubeVideoImporter.isValidYoutubeUrl(clipboard) {
            url = clipboard
            sheetMessage = "video.link.pasted"
            sheetMessageIsError = false
            return
        }
        
        openYoutubeExternal()
        sheetMessage = "video.youtube.opened"
        sheetMessageIsError = false
    }
    
    private func openYoutubeExternal() {
        guard let youtubeUrl = URL(string: "https://m.youtube.com") else { return }
        UIApplication.shared.open(youtubeUrl, options: [:], completionHandler: nil)
    }
}
