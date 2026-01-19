import Foundation

enum TeacherYoutubeVideoCategory: String, CaseIterable, Identifiable {
    case crossfit = "Crossfit"
    case academia = "Academia"
    case treinosEmCasa = "Treinos em Casa"
    
    var id: String { rawValue }
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
