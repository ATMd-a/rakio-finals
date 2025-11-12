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
    
    // Method to get episodes for a specific series (call this from SeriesDetailView)
    func getEpisodes(for seriesId: String) async -> [Episode] {
        do {
            return try await seriesService.fetchEpisodes(for: seriesId)
        } catch {
            print("❌ Error fetching episodes: \(error.localizedDescription)")
            return []
        }
    }
}
