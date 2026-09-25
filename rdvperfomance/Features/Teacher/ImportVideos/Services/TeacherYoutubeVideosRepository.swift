import Foundation
import FirebaseAuth
import FirebaseFirestore

struct TeacherYoutubeVideosRepository {
    
    static func getTeacherId() -> String? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return uid.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    static func loadVideos(teacherId: String) async throws -> [TeacherYoutubeVideo] {
        try await loadVideos(ownerCollection: "teachers", ownerId: teacherId)
    }

    static func loadStudentVideos(studentId: String) async throws -> [TeacherYoutubeVideo] {
        try await loadVideos(ownerCollection: "users", ownerId: studentId)
    }

    private static func loadVideos(
        ownerCollection: String,
        ownerId: String
    ) async throws -> [TeacherYoutubeVideo] {
        let snap = try await Firestore.firestore()
            .collection(ownerCollection)
            .document(ownerId)
            .collection("youtubeVideos")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        let parsed: [TeacherYoutubeVideo] = snap.documents.compactMap { doc in
            let data = doc.data()
            
            let title = (data["title"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let url = (data["url"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let videoId = (data["videoId"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            
            let categoryRaw = (data["category"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let videoCategory = TeacherYoutubeVideoCategory(rawValue: categoryRaw) ?? .crossfit
            
            guard !url.isEmpty, !videoId.isEmpty else { return nil }
            
            return TeacherYoutubeVideo(
                id: doc.documentID,
                title: title,
                url: url,
                videoId: videoId,
                category: videoCategory
            )
        }
        
        return parsed
    }
    
    static func addVideo(teacherId: String, title: String, url: String, videoCategory: TeacherYoutubeVideoCategory) async throws {
        try await addVideo(
            ownerCollection: "teachers",
            ownerId: teacherId,
            title: title,
            url: url,
            videoCategory: videoCategory
        )
    }

    static func addStudentVideo(
        studentId: String,
        title: String,
        url: String,
        videoCategory: TeacherYoutubeVideoCategory
    ) async throws {
        try await addVideo(
            ownerCollection: "users",
            ownerId: studentId,
            title: title,
            url: url,
            videoCategory: videoCategory
        )
    }

    private static func addVideo(
        ownerCollection: String,
        ownerId: String,
        title: String,
        url: String,
        videoCategory: TeacherYoutubeVideoCategory
    ) async throws {
        let cleanedUrl = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let videoId = YouTubeVideoImporter.extractYoutubeVideoId(from: cleanedUrl) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Link inválido. Cole um link do YouTube (youtu.be/ ou youtube.com/watch)."])
        }
        
        let payload: [String: Any] = [
            "title": title.trimmingCharacters(in: .whitespacesAndNewlines),
            "url": cleanedUrl,
            "videoId": videoId,
            "category": videoCategory.rawValue,
            "createdAt": Timestamp(date: Date())
        ]
        
        try await Firestore.firestore()
            .collection(ownerCollection)
            .document(ownerId)
            .collection("youtubeVideos")
            .addDocument(data: payload)
    }
    
    static func deleteVideo(teacherId: String, videoId: String) async throws {
        try await deleteVideo(
            ownerCollection: "teachers",
            ownerId: teacherId,
            videoId: videoId
        )
    }

    static func deleteStudentVideo(studentId: String, videoId: String) async throws {
        try await deleteVideo(
            ownerCollection: "users",
            ownerId: studentId,
            videoId: videoId
        )
    }

    private static func deleteVideo(
        ownerCollection: String,
        ownerId: String,
        videoId: String
    ) async throws {
        try await Firestore.firestore()
            .collection(ownerCollection)
            .document(ownerId)
            .collection("youtubeVideos")
            .document(videoId)
            .delete()
    }
}
