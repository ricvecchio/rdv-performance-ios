import Foundation
import Combine

/// ViewModel que gerencia estado e carregamento de métricas de progresso
@MainActor
final class ProgressGameViewModel: ObservableObject {

    /// Métricas de progresso atuais exibidas na view
    @Published var metrics: ProgressMetrics = .empty
    /// Indica se está carregando dados
    @Published var isLoading: Bool = false
    /// Mensagem de erro caso ocorra falha no carregamento
    @Published var errorMessage: String? = nil

    /// Provider responsável por buscar métricas
    private let provider: ProgressMetricsProvider
    /// Modo de operação que determina qual fonte de dados usar
    private let mode: ProgressGameMode

    /// Inicializa o ViewModel com modo e provider específicos
    init(
        mode: ProgressGameMode,
        provider: ProgressMetricsProvider = ProgressMetricsProvider()
    ) {
        self.mode = mode
        self.provider = provider
    }

    /// Carrega métricas baseado no modo configurado
    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        switch mode {
        case .preview:
            metrics = await provider.loadPreview()

        case .teacherStudent(let studentId, let displayName):
            metrics = await provider.loadForTeacher(studentId: studentId, displayName: displayName)

        case .studentMe(let studentId, let displayName):
            metrics = await provider.loadForStudentMe(studentId: studentId, displayName: displayName)
        }
    }

    /// Gera novas métricas aleatórias apenas em modo preview
    func randomizePreview() async {
        guard case .preview = mode else { return }
        metrics = await provider.loadPreview()
    }
}
