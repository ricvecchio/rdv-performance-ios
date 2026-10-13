import Foundation

struct YouTubeVideoImporter {
    
    static func extractYoutubeVideoId(from urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        
        if let host = url.host, host.contains("youtu.be") {
            let id = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return id.isEmpty ? nil : id
        }
        
        if let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let host = comps.host,
           host.contains("youtube.com") {
            
            if url.path.contains("/watch") {
                let v = comps.queryItems?.first(where: { $0.name == "v" })?.value
                return (v?.isEmpty == false) ? v : nil
            }
            
            if url.path.contains("/shorts/") {
                let parts = url.path.split(separator: "/")
                if let idx = parts.firstIndex(of: "shorts"), idx + 1 < parts.count {
                    return String(parts[idx + 1])
                }
            }
            
            if url.path.contains("/embed/") {
                let parts = url.path.split(separator: "/")
                if let idx = parts.firstIndex(of: "embed"), idx + 1 < parts.count {
                    return String(parts[idx + 1])
                }
            }
        }
        
        return nil
    }
    
    static func isValidYoutubeUrl(_ urlString: String) -> Bool {
        extractYoutubeVideoId(from: urlString) != nil
    }
}
