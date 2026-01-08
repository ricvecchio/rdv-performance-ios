import Foundation

/// Define o modo de exibição do jogo de progresso e origem das métricas
enum ProgressGameMode: Hashable {
    /// Modo preview com dados simulados
    case preview
    /// Modo professor visualizando aluno específico
    case teacherStudent(studentId: String, displayName: String?)
    /// Modo aluno visualizando próprio progresso
    case studentMe(studentId: String, displayName: String?)
}
