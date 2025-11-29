import Foundation
import FirebaseFirestore
import SwiftUI
import Combine

@MainActor
class SeriesViewModel: ObservableObject {
    @Published var shows: [Series] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private let seriesService = SeriesService()
    
    func loadShows() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Only fetch series metadata, NO episodes
            shows = try await seriesService.fetchSeriesOnly()
        } catch {
            errorMessage = "Failed to fetch shows: \(error.localizedDescription)"
            print("❌ Error in loadShows: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func refresh() async {
        shows = []
        await loadShows()
    }
    
    //Both return Episode (unified type)
    func getYouTubeEpisodes(for seriesId: String) async -> [Episode] {
        do {
            return try await seriesService.fetchYouTubeEpisodes(for: seriesId)
        } catch {
            print("❌ Error fetching YouTube episodes: \(error.localizedDescription)")
            return []
        }
    }
    
    func getDailymotionEpisodes(for seriesId: String) async -> [Episode] {
        do {
            return try await seriesService.fetchDailymotionEpisodes(for: seriesId)
        } catch {
            print("❌ Error fetching Dailymotion episodes: \(error.localizedDescription)")
            return []
        }
    }
    
    func getAllEpisodes(for seriesId: String) async -> (youtube: [Episode], dailymotion: [Episode]) {
        async let yt = getYouTubeEpisodes(for: seriesId)
        async let dm = getDailymotionEpisodes(for: seriesId)
        return await (yt, dm)
    }
}
