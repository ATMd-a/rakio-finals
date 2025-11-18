import Foundation
import FirebaseFirestore

struct WatchedContent: Identifiable {
    let id = UUID()
    let videoId: String              // ✅ Replaces seriesDocumentID / episodeContentID
    let title: String                // ✅ Display title for the video
    let thumbnailURL: String?        // ✅ Optional image for display
    let lastWatchedAt: Date
    let progress: Double
    
    // Optional fallback for episodes (for backwards compatibility)
    let seriesTitle: String?         // e.g. "Breaking Bad"
    let episodeTitle: String?        // e.g. "Pilot"
    let isEpisode: Bool              // Helps the UI decide what to show
    
    // MARK: - Computed display helpers
    
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
