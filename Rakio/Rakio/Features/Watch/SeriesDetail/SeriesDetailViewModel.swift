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
    @Published var episodeSourceIsYouTube: Bool = true
    
    private let novelService = NovelService()
    private let seriesService = SeriesService()

    init(series: Series) {
        self.series = series
    }

    init(documentReference: DocumentReference) {
            self.series = Series(title: "", description: "", genre: [], isSeries: false, dateReleased: Timestamp(date: Date()), trailerURL: "", imageName: "", relatedNovelId: nil)
            Task {
                await fetchFullSeries(from: documentReference)
            }
        }

    func loadData() async {
            // Fetch series detail if incomplete
            if series.id == nil || series.genre.isEmpty {
                guard let id = series.id else {
                    errorMessage = "Series ID missing. Cannot fetch data."
                    return
                }
                await fetchFullSeriesData(by: id)
            }
            
            await fetchEpisodes(isYouTube: episodeSourceIsYouTube)
            
            // Load novel detail
            await fetchRelatedNovelDetail()
        }
    
    func fetchEpisodes(isYouTube: Bool) async {
        guard let seriesId = series.id else { return }
        
        isLoadingEpisodes = true
        defer { isLoadingEpisodes = false }
        
        let subcollection = isYouTube ? "episodes" : "episodes 2"
        
        do {
            self.episodes = try await seriesService.fetchEpisodes(for: seriesId, subcollection: subcollection)
        } catch {
            self.episodes = []
            self.errorMessage = "Failed to load episodes: \(error.localizedDescription)"
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
