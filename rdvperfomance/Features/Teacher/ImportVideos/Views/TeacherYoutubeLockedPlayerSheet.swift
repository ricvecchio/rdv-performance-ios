import SwiftUI
import AVKit

struct TeacherYoutubeLockedPlayerSheet: View {
    
    let title: String
    let videoId: String
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            LockedYoutubeWebView(videoId: videoId)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Fechar") { dismiss() }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        AirPlayRoutePicker()
                            .frame(width: 34, height: 34)
                            .accessibilityLabel("Reproduzir com AirPlay")
                    }
                }
                .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
