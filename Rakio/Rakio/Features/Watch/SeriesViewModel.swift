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
    
    // Fetch YT episodes
    func getEpisodesYT(for seriesId: String) async -> [EpisodeYT] {
        do {
            return try await seriesService.fetchEpisodesYT(for: seriesId)
        } catch {
            print("❌ Error fetching YT episodes: \(error.localizedDescription)")
            return []
        }
    }
    
    // Fetch DM episodes (episodes 2)
    func getEpisodesDM(for seriesId: String) async -> [EpisodeDM] {
        do {
            return try await seriesService.fetchEpisodesDM(for: seriesId)
        } catch {
            print("❌ Error fetching DM episodes: \(error.localizedDescription)")
            return []
        }
    }
    
    // Optional: Combined episodes (if you ever need both)
    func getAllEpisodes(for seriesId: String) async -> ([EpisodeYT], [EpisodeDM]) {
        async let yt = getEpisodesYT(for: seriesId)
        async let dm = getEpisodesDM(for: seriesId)
        return await (try! yt, try! dm)
    }
}
