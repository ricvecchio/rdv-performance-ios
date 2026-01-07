import Foundation
import Combine

@MainActor
final class ProgressGameViewModel: ObservableObject {

    @Published var metrics: ProgressMetrics = .empty
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let provider: ProgressMetricsProvider
    private let mode: ProgressGameMode

    init(
        mode: ProgressGameMode,
        provider: ProgressMetricsProvider = ProgressMetricsProvider()
    ) {
        self.mode = mode
        self.provider = provider
    }

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

    func randomizePreview() async {
        guard case .preview = mode else { return }
        metrics = await provider.loadPreview()
    }
}

