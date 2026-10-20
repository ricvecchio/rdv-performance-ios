import SwiftUI
import FirebaseAuth

// MARK: - Controle de exibição única (versão 1.0.25)

// Persistência local (UserDefaults) do aviso de novidade de temas, por usuário (UID).
// Não usa Firestore e não é apagada no logout: cada UID do aparelho tem seu próprio registro.
enum ThemeAnnouncementStore {
    // Versão de referência do anúncio
    static let announcementVersion = "1.0.25"

    // Data/hora da primeira abertura desta versão (ou superior) no aparelho.
    // Contas criadas depois desse instante já passaram pelo cadastro com seleção de tema.
    private static let releaseCutoffKey = "themeAnnouncementFirstLaunch_\(announcementVersion)"

    private static func seenKey(uid: String) -> String {
        "themeAnnouncementSeen_\(announcementVersion)_\(uid)"
    }

    // Chamado na inicialização do app: grava o instante somente na primeira abertura
    static func recordReleaseCutoffIfNeeded(defaults: UserDefaults = .standard) {
        guard defaults.object(forKey: releaseCutoffKey) == nil else { return }
        defaults.set(Date().timeIntervalSince1970, forKey: releaseCutoffKey)
    }

    static func hasSeen(uid: String, defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: seenKey(uid: uid))
    }

    // Registrado somente quando o usuário dispensa o aviso ou escolhe abrir a tela Tema
    static func markSeen(uid: String, defaults: UserDefaults = .standard) {
        guard !uid.isEmpty else { return }
        defaults.set(true, forKey: seenKey(uid: uid))
    }

    // Elegível: usuário autenticado (mesmo UID da sessão), ainda não viu o aviso e com conta criada
    // (metadado `creationDate` do Firebase Authentication) antes da primeira abertura desta versão.
    // Sem data de criação confiável ou sem a data de corte, o aviso não é exibido (estratégia segura).
    @MainActor
    static func isEligible(uid: String, defaults: UserDefaults = .standard) -> Bool {
        guard !uid.isEmpty, !hasSeen(uid: uid, defaults: defaults) else { return false }
        guard let user = Auth.auth().currentUser, user.uid == uid else { return false }
        guard let creationDate = user.metadata.creationDate else { return false }
        guard let cutoff = defaults.object(forKey: releaseCutoffKey) as? Double else { return false }
        return creationDate < Date(timeIntervalSince1970: cutoff)
    }
}

// MARK: - Apresentação nas Homes

private struct ThemeAnnouncementModifier: ViewModifier {
    @EnvironmentObject private var session: AppSession
    @Environment(\.appTheme) private var appTheme
    @Environment(\.locale) private var locale

    let onChooseTheme: () -> Void

    @State private var isPresented = false
    @State private var opensThemeAfterDismiss = false

    func body(content: Content) -> some View {
        content
            // Avaliado somente com sessão restaurada, perfil resolvido e UID disponível
            // (reavaliado se o UID ou o estado de restauração mudarem)
            .task(id: "\(session.uid ?? "")|\(session.isRestoringSession)|\(session.isLoggedIn)") {
                presentIfEligible()
            }
            .fullScreenCover(isPresented: $isPresented, onDismiss: {
                // Navega somente após o modal ser fechado (evita push durante a apresentação)
                guard opensThemeAfterDismiss else { return }
                opensThemeAfterDismiss = false
                onChooseTheme()
            }) {
                ThemeAnnouncementView(
                    onChooseTheme: { close(openingTheme: true) },
                    onNotNow: { close(openingTheme: false) }
                )
                .environment(\.appTheme, appTheme)
                .environment(\.locale, locale)
                .presentationBackground {
                    // Home visível ao fundo, desfocada e levemente escurecida
                    ZStack {
                        Rectangle().fill(.ultraThinMaterial)
                        Color.black.opacity(0.25)
                    }
                    .ignoresSafeArea()
                }
            }
    }

    private func presentIfEligible() {
        guard !isPresented,
              !session.isRestoringSession,
              session.isLoggedIn,
              let uid = session.uid,
              ThemeAnnouncementStore.isEligible(uid: uid)
        else { return }

        // Sem a transição de baixo para cima: o conteúdo do aviso faz o próprio fade
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            isPresented = true
        }
    }

    private func close(openingTheme: Bool) {
        if let uid = session.uid {
            ThemeAnnouncementStore.markSeen(uid: uid)
        }
        opensThemeAfterDismiss = openingTheme

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            isPresented = false
        }
    }
}

extension View {
    // Aviso único da novidade de temas (versão 1.0.25) para usuários já cadastrados.
    // `onChooseTheme`: navegação para a ThemeSettingsView na pilha da Home do perfil.
    func themeAnnouncement(onChooseTheme: @escaping () -> Void) -> some View {
        modifier(ThemeAnnouncementModifier(onChooseTheme: onChooseTheme))
    }
}

// MARK: - Layout do aviso

struct ThemeAnnouncementView: View {
    @Environment(\.appTheme) private var appTheme

    let onChooseTheme: () -> Void
    let onNotNow: () -> Void

    @State private var isVisible = false

    // Paleta do Tema Claro (valores já aprovados nas telas do app; Tema Escuro usa os valores originais)
    private enum LightColors {
        static let cardSurface = Color(red: 0xDD / 255, green: 0xED / 255, blue: 0xDC / 255)     // #DDEDDC
        static let primaryText = Color(red: 0x17 / 255, green: 0x1C / 255, blue: 0x17 / 255)     // #171C17
        static let darkGreenBorder = Color(red: 0x29 / 255, green: 0x4A / 255, blue: 0x2F / 255) // #294A2F
    }

    private let contentMaxWidth: CGFloat = 380

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                card
                    .frame(maxWidth: contentMaxWidth)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.96)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) {
                isVisible = true
            }
        }
        .interactiveDismissDisabled(true)
    }

    private var card: some View {
        VStack(spacing: 16) {
            Text("theme_announcement.title")
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.95), light: LightColors.primaryText))
                .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                Text("theme_announcement.message")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.Colors.ink(0.75))

                Text("theme_announcement.subtitle")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppThemeColor(dark: Color.green.opacity(0.85), light: LightColors.darkGreenBorder))
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                themePreview(imageName: "theme_preview_dark", title: AppTheme.dark.localizedTitle)
                themePreview(imageName: "theme_preview_light", title: AppTheme.light.localizedTitle)
            }
            .padding(.top, 4)

            VStack(spacing: 10) {
                Button(action: onChooseTheme) {
                    Text("theme_announcement.choose_theme")
                        .frame(maxWidth: .infinity)
                        .modifier(ThemeAnnouncementPrimaryButtonModifier())
                }
                .buttonStyle(.plain)

                Button(action: onNotNow) {
                    Text("theme_announcement.not_now")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink(0.75))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(AppThemeColor(dark: Color.black.opacity(0.88), light: LightColors.cardSurface))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.darkGreenBorder), lineWidth: 1)
        )
        .shadow(color: .black.opacity(appTheme == .light ? 0.25 : 0.45), radius: 16, y: 8)
    }

    private func themePreview(imageName: String, title: LocalizedStringKey) -> some View {
        VStack(spacing: 6) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.darkGreenBorder), lineWidth: 1)
                )
                .accessibilityHidden(true)

            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.Colors.ink(0.7))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// Botão principal: Tema Escuro usa o `primaryGreenActionButton()` original; Tema Claro usa o padrão
// aprovado dos botões de ação (verde militar 80%, texto branco e contorno #294A2F), com as mesmas medidas.
private struct ThemeAnnouncementPrimaryButtonModifier: ViewModifier {
    @Environment(\.appTheme) private var appTheme

    private static let darkGreenBorder = Color(red: 0x29 / 255, green: 0x4A / 255, blue: 0x2F / 255) // #294A2F

    @ViewBuilder
    func body(content: Content) -> some View {
        if appTheme == .light {
            content
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.white)
                .padding(.vertical, 14)
                .background(AppThemePalette.lightBar.opacity(0.80))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Self.darkGreenBorder, lineWidth: 1)
                )
        } else {
            content.primaryGreenActionButton()
        }
    }
}

