import SwiftUI

struct TeacherAddWorkoutSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    
    @State private var title: String = ""
    @State private var sheetMessage: String? = nil
    @State private var sheetMessageIsError: Bool = false
    
    let onSave: (_ title: String) -> Void
    
    private let contentMaxWidth: CGFloat = 380
    
    var body: some View {
        NavigationStack {
            ZStack {
                Image("rdv_fundo")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Theme.Colors.divider)
                        .frame(height: 1)
                    
                    ScrollView(showsIndicators: false) {
                        HStack {
                            Spacer(minLength: 0)
                            
                            VStack(alignment: .leading, spacing: 14) {
                                Text("ui.enter_a_workout_title")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.65))
                                
                                formCard
                                
                                HStack(spacing: 10) {
                                    Button {
                                        let t = title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                                        if t.isEmpty {
                                            sheetMessage = AppLocalization.string("ui.enter_the_workout_title",
                                                locale: locale
                                            )
                                            sheetMessageIsError = true
                                            return
                                        }
                                        
                                        onSave(t)
                                        dismiss()
                                    } label: {
                                        HStack(spacing: 10) {
                                            Image(systemName: "checkmark")
                                            Text("common.save")
                                        }
                                        .padding(.horizontal, 14)
                                        .primaryGreenActionButton()
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Spacer(minLength: 0)
                                }
                                
                                if let msg = sheetMessage {
                                    sheetMessageCard(text: msg, isError: sheetMessageIsError)
                                }
                                
                                Color.clear.frame(height: 18)
                            }
                            .frame(maxWidth: contentMaxWidth)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            
                            Spacer(minLength: 0)
                        }
                    }
                }
                .ignoresSafeArea(.container, edges: [.bottom])
            }
            .navigationTitle("ui.add_workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.close") { dismiss() }
                }
            }
            .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    private var formCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("ui.workout_title")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.55))
                
                ZStack(alignment: .leading) {
                    if title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
                        Text("ui.e_g_workout_a_chest_and_triceps")
                            .foregroundColor(.white.opacity(0.45))
                            .padding(.horizontal, 12)
                    }
                    
                    TextField("", text: $title)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(false)
                        .foregroundColor(.white.opacity(0.92))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                }
                .background(Color.white.opacity(0.10))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
    
    private func sheetMessageCard(text: String, isError: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundColor(isError ? .yellow.opacity(0.85) : .green.opacity(0.85))
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.75))
            
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.35))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }
}
