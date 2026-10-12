import Foundation
import SwiftUI

enum TeacherYoutubeVideoCategory: String, CaseIterable, Identifiable {
    case crossfit = "Crossfit"
    case academia = "Academia"
    case treinosEmCasa = "Treinos em Casa"
    
    var id: String { rawValue }

    var localizedTitle: LocalizedStringKey {
        switch self {
        case .crossfit:
            "video.category.crossfit"
        case .academia:
            "video.category.gym"
        case .treinosEmCasa:
            "video.category.home"
        }
    }
}

struct TeacherYoutubeVideo: Identifiable, Equatable {
    let id: String
    let title: String
    let url: String
    let videoId: String
    let category: TeacherYoutubeVideoCategory
}

struct LockedPlayerItem: Identifiable {
    let id = UUID()
    let title: String
    let videoId: String
}
