import SwiftUI

// MARK: - Tela 6 (Aluno): Agenda (Treinos)
struct StudentAgendaView: View {

    @Binding var path: [AppRoute]

    private let contentMaxWidth: CGFloat = 380

    /// ✅ MVP estável:
    /// - Mantém o tipo correto (TrainingWeek)
    /// - NÃO depende de propriedades específicas (title/progress/category)
    /// - Você pode injetar weeks futuramente (backend ou mock real)
    private let weeks: [TrainingWeek]

    init(path: Binding<[AppRoute]>, weeks: [TrainingWeek] = []) {
        self._path = path
        self.weeks = weeks
    }

    var body: some View {
        ZStack {

            Image("rdv_fundo")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {

                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)

                ScrollView(showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 0)

                        VStack(spacing: 12) {

                            if weeks.isEmpty {
                                emptyState()
                            } else {
                                ForEach(weeks, id: \.self) { week in
                                    weekRow(week: week)
                                }
                            }

                            Color.clear.frame(height: Theme.Layout.footerHeight + 20)
                        }
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        Spacer(minLength: 0)
                    }
                }

                // ✅ Aluno: Agenda | Sobre | Perfil (Agenda selecionado)
                FooterBar(
                    path: $path,
                    kind: .agendaSobrePerfil(
                        isAgendaSelected: true,
                        isSobreSelected: false,
                        isPerfilSelected: false
                    )
                )
                .frame(height: Theme.Layout.footerHeight)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.footerBackground)
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {

            // ✅ Sem botão voltar aqui (pois veio do login)
            ToolbarItem(placement: .principal) {
                Text("Agenda")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                MiniProfileHeader(imageName: "rdv_eu", size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    // MARK: - UI

    private func emptyState() -> some View {
        VStack(spacing: 10) {
            Text("Nenhum treino disponível")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))

            Text("Assim que seu professor liberar, sua agenda aparecerá aqui.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.65))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func weekRow(week: TrainingWeek) -> some View {
        let title = weekText(week, keys: ["title", "name", "weekTitle", "label"], fallback: "Treino da Semana")
        let category = weekText(week, keys: ["category", "treinoTipo", "program", "tipo"], fallback: "—")
        let progress = weekDouble(week, keys: ["progress", "completion", "percent", "completionRate"], fallback: 0.0)

        return Button {
            // ✅ Aqui é o mais importante: AppRoute espera TrainingWeek
            path.append(.studentWeekDetail(week))
        } label: {
            VStack(alignment: .leading, spacing: 10) {

                HStack {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.95))

                    Spacer()

                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                }

                Text("Categoria: \(category)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.green.opacity(0.85))

                ProgressView(value: progress)
                    .tint(.green.opacity(0.85))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Reflection helpers (não quebra build se campos mudarem)

    private func weekText(_ week: TrainingWeek, keys: [String], fallback: String) -> String {
        let dict = mirrorDictionary(week)
        for k in keys {
            if let v = dict[k] {
                if let s = v as? String, !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return s }
                // se for enum/objeto, tenta converter para string
                let str = String(describing: v)
                if !str.isEmpty, str != "nil" { return str }
            }
        }
        return fallback
    }

    private func weekDouble(_ week: TrainingWeek, keys: [String], fallback: Double) -> Double {
        let dict = mirrorDictionary(week)
        for k in keys {
            if let v = dict[k] {
                if let d = v as? Double { return clamp01(d) }
                if let f = v as? Float { return clamp01(Double(f)) }
                if let i = v as? Int { return clamp01(Double(i) / 100.0) } // se vier como 0..100
                if let s = v as? String {
                    let cleaned = s.replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    if let d = Double(cleaned) {
                        return d > 1 ? clamp01(d / 100.0) : clamp01(d)
                    }
                }
            }
        }
        return clamp01(fallback)
    }

    private func clamp01(_ value: Double) -> Double {
        min(max(value, 0.0), 1.0)
    }

    private func mirrorDictionary(_ value: Any) -> [String: Any] {
        var result: [String: Any] = [:]
        let mirror = Mirror(reflecting: value)

        for child in mirror.children {
            if let label = child.label {
                result[label] = child.value
            }
        }
        return result
    }
}

