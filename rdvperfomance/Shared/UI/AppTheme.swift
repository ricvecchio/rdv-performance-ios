// Define o tema visual do aplicativo (Escuro / Claro) e os estilos dinâmicos usados pelas telas
import SwiftUI

// Tema visual escolhido pelo usuário. Preferência salva localmente (AppStorage), sem Firebase.
enum AppTheme: String, CaseIterable, Identifiable {
    case dark
    case light

    // Chave usada com @AppStorage para persistir a preferência
    static let storageKey = "selectedAppTheme"

    // Tema padrão (usuários existentes e novas instalações iniciam no Escuro)
    static let defaultTheme: AppTheme = .dark

    var id: String { rawValue }

    // Converte o valor salvo em AppStorage, voltando ao Escuro para valores desconhecidos
    init(storedValue: String) {
        self = AppTheme(rawValue: storedValue) ?? AppTheme.defaultTheme
    }

    // Tema Escuro mantém o comportamento original (sem forçar esquema de cores do sistema)
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .dark: nil
        case .light: .light
        }
    }

    // Esquema de cores aplicado à barra de navegação nas telas que já o definiam
    var navigationBarColorScheme: ColorScheme {
        switch self {
        case .dark: .dark
        case .light: .light
        }
    }

    // Imagem de fundo decorativa padronizada do aplicativo
    var backgroundImageName: String {
        switch self {
        case .dark: "rdv_fundo"
        case .light: "rdv_fundo_claro"
        }
    }

    var iconName: String {
        switch self {
        case .dark: "moon.fill"
        case .light: "sun.max.fill"
        }
    }

    var localizedTitle: LocalizedStringKey {
        switch self {
        case .dark: "settings.theme.dark"
        case .light: "settings.theme.light"
        }
    }

    var localizedDescription: LocalizedStringKey {
        switch self {
        case .dark: "settings.theme.dark.description"
        case .light: "settings.theme.light.description"
        }
    }
}

// MARK: - Ambiente

private nonisolated struct AppThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppTheme = .dark
}

extension EnvironmentValues {
    // Tema atual propagado a partir da raiz do aplicativo
    nonisolated var appTheme: AppTheme {
        get { self[AppThemeEnvironmentKey.self] }
        set { self[AppThemeEnvironmentKey.self] = newValue }
    }
}

// MARK: - Estilo de cor dinâmico

// Cor que se resolve conforme o tema do app (não depende do tema configurado no iOS).
// No Tema Escuro retorna exatamente a cor original informada em `dark`.
nonisolated struct AppThemeColor: ShapeStyle {
    let dark: Color
    let light: Color

    func resolve(in environment: EnvironmentValues) -> Color.Resolved {
        switch environment.appTheme {
        case .dark:
            dark.resolve(in: environment)
        case .light:
            light.resolve(in: environment)
        }
    }
}

// Permite usar a cor dinâmica como View (mesmo comportamento de `Color` usado como View)
@MainActor
extension AppThemeColor: View {
    var body: some View {
        Rectangle().fill(self)
    }
}

// Adapta uma cor recebida como parâmetro (ex.: componentes compartilhados que recebem `Color`).
// No Tema Escuro retorna exatamente a cor original. No Tema Claro, apenas tons neutros
// são convertidos: branco -> cinza-escuro (texto/linhas) e preto -> branco (superfícies).
// Cores com matiz (verde, vermelho etc.) permanecem inalteradas.
nonisolated struct AppThemeAdaptiveColor: ShapeStyle {
    let base: Color

    init(_ base: Color) {
        self.base = base
    }

    func resolve(in environment: EnvironmentValues) -> Color.Resolved {
        let resolved = base.resolve(in: environment)
        guard environment.appTheme == .light else { return resolved }

        let opacity = Double(resolved.opacity)
        let isWhite = resolved.red > 0.95 && resolved.green > 0.95 && resolved.blue > 0.95
        let isBlack = resolved.red < 0.05 && resolved.green < 0.05 && resolved.blue < 0.05

        if isWhite {
            return AppThemePalette.lightInk.opacity(AppThemePalette.lightOpacity(for: opacity)).resolve(in: environment)
        }
        if isBlack {
            return Color.white.opacity(AppThemePalette.lightOpacity(for: opacity)).resolve(in: environment)
        }
        return resolved
    }
}

// Valores base da paleta clara compartilhados pelos estilos dinâmicos
nonisolated enum AppThemePalette {
    // Cor de texto principal do Tema Claro (cinza-escuro quase preto)
    static let lightInk = Color(red: 0.10, green: 0.12, blue: 0.11)

    // Reforça a opacidade no Tema Claro para manter legibilidade sobre o fundo branco
    static func lightOpacity(for opacity: Double) -> Double {
        let clamped = min(max(opacity, 0), 1)
        return 1 - (1 - clamped) * (1 - clamped)
    }
}

// MARK: - Fundo padronizado

// Fundo decorativo das telas: `rdv_fundo` no Tema Escuro e parede de tijolos brancos no Tema Claro
struct AppThemeBackgroundImage: View {
    @Environment(\.appTheme) private var appTheme

    var body: some View {
        Image(appTheme.backgroundImageName)
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    }
}

// MARK: - Gradiente neutro

// Mesmo uso de `LinearGradient(colors:startPoint:endPoint:)` para gradientes de cards.
// No Tema Escuro usa exatamente as cores informadas; no Tema Claro converte tons neutros
// (preto -> branco) para manter a superfície clara e o texto legível.
struct AppThemeNeutralGradient: View {
    @Environment(\.self) private var environment

    let colors: [Color]
    let startPoint: UnitPoint
    let endPoint: UnitPoint

    var body: some View {
        LinearGradient(
            colors: environment.appTheme == .light
                ? colors.map { Color(AppThemeAdaptiveColor($0).resolve(in: environment)) }
                : colors,
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
}

// MARK: - Barra de navegação

private struct AppThemeNavigationBarColorSchemeModifier: ViewModifier {
    @Environment(\.appTheme) private var appTheme

    func body(content: Content) -> some View {
        content
            .toolbarColorScheme(appTheme.navigationBarColorScheme, for: .navigationBar)
    }
}

extension View {
    // Substitui `.toolbarColorScheme(.dark, for: .navigationBar)`: Escuro no tema escuro, Claro no tema claro
    func appThemeNavigationBarColorScheme() -> some View {
        modifier(AppThemeNavigationBarColorSchemeModifier())
    }
}

