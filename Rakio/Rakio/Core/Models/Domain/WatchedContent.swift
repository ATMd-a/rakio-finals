import Foundation
import FirebaseFirestore

struct WatchedContent: Identifiable {
    let id = UUID()
    let videoId: String   
    let title: String
    let thumbnailURL: String?
    let lastWatchedAt: Date
    let progress: Double
    let seriesTitle: String?
    let episodeTitle: String?
    let isEpisode: Bool
    
    var displayTitle: String {
        if let episodeTitle = episodeTitle, isEpisode {
            return episodeTitle
        }
        return title
    }
    
    var progressPercentage: String {
        return String(format: "%.0f%%", progress * 100)
    }
}
