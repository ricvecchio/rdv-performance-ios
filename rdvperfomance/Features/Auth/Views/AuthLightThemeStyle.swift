// Estilos visuais exclusivos das telas de autenticação (Login, Tipo de Conta e Cadastros) no Tema Claro.
// Responsabilidade apenas visual: no Tema Escuro todos os valores originais são preservados.
import SwiftUI

// Paleta local do Tema Claro das telas de autenticação (valores de referência da TrainingWeeksView)
enum AuthLightPalette {
    // Fundo dos cards (área abaixo do cabeçalho) (#F0F7EF)
    static let cardSurface = Color(red: 0xF0 / 255, green: 0xF7 / 255, blue: 0xEF / 255)
    // Borda externa dos cards (#C9DFC9)
    static let cardBorder = Color(red: 0xC9 / 255, green: 0xDF / 255, blue: 0xC9 / 255)
    // Texto principal dos cards (#171C17)
    static let primaryText = Color(red: 0x17 / 255, green: 0x1C / 255, blue: 0x17 / 255)
    // Setas e indicadores internos (#294A2F)
    static let indicator = Color(red: 0x29 / 255, green: 0x4A / 255, blue: 0x2F / 255)
    // Fundo dos botões principais: verde militar do cabeçalho/rodapé (#29452C)
    static let buttonSurface = AppThemePalette.lightBar
}

// Botão principal das telas de autenticação.
// Escuro: aplica exatamente `primaryGreenActionButton()` (sem alterações).
// Claro: mesmo formato/tamanho/raio, com fundo verde militar sólido, texto claro e sombra.
private struct AuthPrimaryActionButtonModifier: ViewModifier {
    @Environment(\.appTheme) private var appTheme
    @Environment(\.isEnabled) private var isEnabled

    func body(content: Content) -> some View {
        if appTheme == .light {
            content
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isEnabled ? Color.white.opacity(0.92) : Color.white.opacity(0.55))
                .padding(.vertical, 14)
                .background(AuthLightPalette.buttonSurface)
                .cornerRadius(12)
                .overlay(
                    // Contorno verde-escuro #294A2F (mesmo tom do card "Acesso rápido" da TeacherDashboardView)
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AuthLightPalette.indicator, lineWidth: 1)
                )
                .shadow(color: .black.opacity(isEnabled ? 0.25 : 0.12), radius: 10, y: 6)
                .authLightOnMilitaryGreen()
        } else {
            content
                .primaryGreenActionButton()
        }
    }
}

// Conteúdo exibido sobre o verde militar no Tema Claro usa os valores claros (iguais ao Tema Escuro),
// como já ocorre no cabeçalho/rodapé. No Tema Escuro o ambiente permanece inalterado.
private struct AuthLightOnMilitaryGreenModifier: ViewModifier {
    @Environment(\.appTheme) private var appTheme
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .environment(\.colorScheme, appTheme == .light ? .dark : colorScheme)
    }
}

extension View {
    // Uso exclusivo das telas de autenticação
    func authPrimaryActionButton() -> some View {
        modifier(AuthPrimaryActionButtonModifier())
    }

    // Uso exclusivo das telas de autenticação
    func authLightOnMilitaryGreen() -> some View {
        modifier(AuthLightOnMilitaryGreenModifier())
    }
}

