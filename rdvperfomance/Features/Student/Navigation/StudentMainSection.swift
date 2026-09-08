import Foundation

/// Seções principais do aluno, controladas pelo rodapé (FooterBar).
///
/// IMPORTANTE: trocar de seção NÃO é push/pop de NavigationStack. É apenas a
/// seleção de qual das 3 raízes (Agenda / Recordes / Perfil) está visível no
/// momento. Cada seção possui sua própria pilha de navegação hierárquica
/// independente (ver `StudentRootView`).
enum StudentMainSection: Hashable {
    case agenda
    case records
    case profile
}
