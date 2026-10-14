// Define o tema visual do aplicativo (Escuro / Claro) e os estilos dinâmicos usados pelas telas
import SwiftUI

// Tema visual escolhido pelo usuário. Preferência salva localmente (AppStorage), sem Firebase.
// `nonisolated`: tipo de valor puro, lido também em contextos não isolados (ShapeStyle.resolve / EnvironmentKey).
nonisolated enum AppTheme: String, CaseIterable, Identifiable {
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

    // Esquema de cores aplicado à barra de navegação nas telas que já o definiam.
    // No Tema Claro o cabeçalho é verde-escuro, por isso a barra usa esquema escuro
    // (títulos, botões e Status Bar claros).
    var navigationBarColorScheme: ColorScheme {
        switch self {
        case .dark: .dark
        case .light: .dark
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
// No Tema Claro, conteúdos exibidos sobre as barras verde-escuras (cabeçalho com esquema
// escuro e rodapé) usam os mesmos valores do Tema Escuro (texto branco, verde original),
// exceto as cores de fundo das próprias barras (`followsBarColorScheme: false`).
nonisolated struct AppThemeColor: ShapeStyle {
    let dark: Color
    let light: Color
    var followsBarColorScheme: Bool = true

    func resolve(in environment: EnvironmentValues) -> Color.Resolved {
        switch environment.appTheme {
        case .dark:
            dark.resolve(in: environment)
        case .light:
            if followsBarColorScheme && environment.colorScheme == .dark {
                dark.resolve(in: environment)
            } else {
                light.resolve(in: environment)
            }
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
        // Sobre as barras verde-escuras do Tema Claro mantém a cor original (igual ao Tema Escuro)
        if environment.colorScheme == .dark { return resolved }

        let opacity = Double(resolved.opacity)
        let isWhite = resolved.red > 0.95 && resolved.green > 0.95 && resolved.blue > 0.95
        let isBlack = resolved.red < 0.05 && resolved.green < 0.05 && resolved.blue < 0.05

        if isWhite {
            return AppThemePalette.lightInk.opacity(AppThemePalette.lightOpacity(for: opacity)).resolve(in: environment)
        }
        if isBlack {
            return AppThemePalette.lightSurface.opacity(AppThemePalette.lightOpacity(for: opacity)).resolve(in: environment)
        }
        return resolved
    }
}

// Valores base da paleta clara compartilhados pelos estilos dinâmicos
nonisolated enum AppThemePalette {
    // Cor de texto principal do Tema Claro (preto suave esverdeado, #101714)
    static let lightInk = Color(red: 0x10 / 255, green: 0x17 / 255, blue: 0x14 / 255)

    // Superfície dos cards do Tema Claro (verde pastel, #D5F1DC)
    static let lightSurface = Color(red: 0xD5 / 255, green: 0xF1 / 255, blue: 0xDC / 255)

    // Cabeçalho e rodapé do Tema Claro (verde militar, #29452C)
    static let lightBar = Color(red: 0x29 / 255, green: 0x45 / 255, blue: 0x2C / 255)

    // Verde de destaque para textos/ícones/setas do Tema Claro (#008C43)
    static let lightAccent = Color(red: 0x00 / 255, green: 0x8C / 255, blue: 0x43 / 255)

    // Verde vibrante dos itens selecionados no rodapé do Tema Claro (#5AFF98)
    static let lightSelected = Color(red: 0x5A / 255, green: 0xFF / 255, blue: 0x98 / 255)

    // Superfície dos ícones dentro dos cards do Tema Claro (#AAF0C5)
    static let lightIconSurface = Color(red: 0xAA / 255, green: 0xF0 / 255, blue: 0xC5 / 255)

    // Borda fina dos cards do Tema Claro (#ABDABC)
    static let lightCardBorder = Color(red: 0xAB / 255, green: 0xDA / 255, blue: 0xBC / 255)

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
    // Substitui `.toolbarColorScheme(.dark, for: .navigationBar)`: esquema escuro em ambos os temas
    // (no Tema Claro o cabeçalho é verde-escuro)
    func appThemeNavigationBarColorScheme() -> some View {
        modifier(AppThemeNavigationBarColorSchemeModifier())
    }

    // Para telas que não definiam esquema de cores na barra: no Tema Escuro mantém o
    // comportamento padrão (nil); no Tema Claro aplica esquema escuro ao cabeçalho verde-escuro.
    func appThemeLightHeaderColorScheme() -> some View {
        modifier(AppThemeLightHeaderColorSchemeModifier())
    }
}

private struct AppThemeLightHeaderColorSchemeModifier: ViewModifier {
    @Environment(\.appTheme) private var appTheme

    func body(content: Content) -> some View {
        content
            .toolbarColorScheme(appTheme == .light ? .dark : nil, for: .navigationBar)
    }
}

// MARK: - Rodapé

private struct AppThemeFooterColorSchemeModifier: ViewModifier {
    @Environment(\.appTheme) private var appTheme
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .environment(\.colorScheme, appTheme == .light ? .dark : colorScheme)
    }
}

extension View {
    // No Tema Claro o rodapé é verde-escuro: o conteúdo usa os valores do Tema Escuro
    // (ícones/textos brancos). No Tema Escuro o ambiente permanece inalterado.
    func appThemeFooterColorScheme() -> some View {
        modifier(AppThemeFooterColorSchemeModifier())
    }
}

