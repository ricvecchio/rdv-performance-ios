import SwiftUI

struct DebugAROverlay: View {
    let cameraStatusRaw: Int
    let hasARView: Bool
    let alertMessage: String
    let onCopyDiagnostic: () -> Void
    let onStartMinimal: () -> Void
    let onStartFull: () -> Void
    let onShareDiagnostic: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DEBUG AR").font(.caption).bold()
                .padding(6)
                .background(Color.black.opacity(0.6))
                .foregroundColor(.white)
                .cornerRadius(6)

            Text("cameraStatus: \(cameraStatusRaw)")
                .font(.caption2)
                .foregroundColor(.white)
                .padding(6)
                .background(Color.black.opacity(0.4))
                .cornerRadius(6)

            Text("arViewRef: \(hasARView ? "yes" : "no")")
                .font(.caption2)
                .foregroundColor(.white)
                .padding(6)
                .background(Color.black.opacity(0.4))
                .cornerRadius(6)

            Button("Copiar diagnóstico AR") { onCopyDiagnostic() }
                .buttonStyle(.bordered)
                .padding(.top, 6)

            Button("Salvar/Compartilhar log") { onShareDiagnostic() }
                .buttonStyle(.bordered)

            Button("Start session (manual - minimal)") { onStartMinimal() }
                .buttonStyle(.borderedProminent)

            Button("Start session (manual - full)") { onStartFull() }
                .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct DebugAROverlay_Previews: PreviewProvider {
    static var previews: some View {
        DebugAROverlay(cameraStatusRaw: 3, hasARView: true, alertMessage: "", onCopyDiagnostic: {}, onStartMinimal: {}, onStartFull: {}, onShareDiagnostic: {})
    }
}
