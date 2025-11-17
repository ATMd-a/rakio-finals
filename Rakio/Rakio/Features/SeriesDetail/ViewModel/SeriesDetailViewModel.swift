import Foundation
import FirebaseFirestore
import SwiftUI

@MainActor
class SeriesDetailViewModel: ObservableObject {
    @Published var series: Series
    @Published var episodes: [Episode] = []
    @Published var isLoadingEpisodes = false
    @Published var errorMessage: String? = nil
    
    @Published var relatedNovelDetail: NovelDetail?
    @Published var episodeSourceIsYouTube: Bool = true // State for the toggle
    
    private let novelService = NovelService()
    private let seriesService = SeriesService()

    init(series: Series) {
        self.series = series
    }
    
    // New convenience init for DocumentReference if you want to extend later
    init(documentReference: DocumentReference) {
            self.series = Series(title: "", description: "", genre: [], isSeries: false, dateReleased: Timestamp(date: Date()), trailerURL: "", imageName: "", relatedNovelId: nil)
            Task {
                await fetchFullSeries(from: documentReference)
            }
        }

    func loadData() async {
            // 1. Fetch series detail if incomplete
            if series.id == nil || series.genre.isEmpty {
                guard let id = series.id else {
                    errorMessage = "Series ID missing. Cannot fetch data."
                    return
                }
                await fetchFullSeriesData(by: id)
            }
            
            // 2. Load the initial set of episodes (uses the correct function below)
            await fetchEpisodes(isYouTube: episodeSourceIsYouTube)
            
            // 3. Load novel detail
            await fetchRelatedNovelDetail()
        }
    
    func fetchEpisodes(isYouTube: Bool) async {
            guard let seriesId = series.id else { return }
            
            isLoadingEpisodes = true
            defer { isLoadingEpisodes = false }
            
            let subcollectionName = isYouTube ? "episodes" : "episodes 2"
            let sourceName = isYouTube ? "YouTube" : "Dailymotion"
            
            print("🔄 Fetching \(sourceName) episodes from subcollection: \(subcollectionName)")
            
            do {
                // T is correctly inferred as Episode here.
                let fetchedEpisodes: [Episode] = try await seriesService.fetchEpisodes(for: seriesId, subcollection: subcollectionName)
                
                self.episodes = fetchedEpisodes
                
                print("✅ Successfully loaded \(self.episodes.count) \(sourceName) episodes.")
            } catch {
                self.episodes = [] // Clear episodes on failure
                self.errorMessage = "Failed to load \(sourceName) episodes: \(error.localizedDescription)"
                print("❌ \(self.errorMessage!)")
            }
        }

    // Fetch full series using SeriesService, with explicit ID assignment after decoding
    func fetchFullSeriesData(by id: String) async {
        do {
            let fullSeries = try await seriesService.fetchSeries(by: id)
            await MainActor.run {
                self.series = fullSeries
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch full series data: \(error.localizedDescription)"
                print("❌ \(error.localizedDescription)")
            }
        }
    }
    
    // Similar to NovelDetailViewModel’s fetchSeries(by:)
    func fetchFullSeries(from documentReference: DocumentReference) async {
        do {
            let documentSnapshot = try await documentReference.getDocument()
            var decodedSeries = try documentSnapshot.data(as: Series.self)
            decodedSeries.id = documentSnapshot.documentID
            await MainActor.run {
                self.series = decodedSeries
            }
            await loadData()
        } catch {
            await MainActor.run {
                self.errorMessage = "Error fetching series: \(error.localizedDescription)"
                print("❌ \(error.localizedDescription)")
            }
        }
    }
    
//    // Fetch episodes after series is loaded and id is set
//    func fetchEpisodes(isYouTube: Bool) async {
//        guard let seriesId = series.id else { return [] }
//        isLoadingEpisodes = true
//        defer { isLoadingEpisodes = false }
//        
//        do {
//            let snapshot = try await seriesService.fetchEpisodes(for: seriesId, subcollection: subcollection)
//            return snapshot
//        } catch {
//            await MainActor.run {
//                self.errorMessage = "Failed to load episodes: \(error.localizedDescription)"
//            }
//            return []
//        }
//    }


    func fetchRelatedNovelDetail() async {
        guard let novelRef = series.relatedNovelId else {
            relatedNovelDetail = nil
            return
        }
        do {
            relatedNovelDetail = try await novelService.fetchNovelDetail(by: novelRef.documentID)
        } catch {
            relatedNovelDetail = nil
        }
    }
}
