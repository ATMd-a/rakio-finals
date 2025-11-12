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
    
    private let novelService = NovelService()
    private let seriesService = SeriesService()

    init(series: Series) {
        self.series = series
    }
    
    // New convenience init for DocumentReference if you want to extend later
    init(documentReference: DocumentReference) {
        self.series = Series(title: "", description: "", genre: [], isSeries: false, isYT: false, dateReleased: Timestamp(date: Date()), trailerURL: "", imageName: "", relatedNovelId: nil)
        Task {
            await fetchFullSeries(from: documentReference)
        }
    }

    func loadData() async {
        // If partial, fetch full first
        if series.id == nil || series.genre.isEmpty {
            if let id = series.id {
                await fetchFullSeriesData(by: id)
            } else {
                errorMessage = "Series ID missing. Cannot fetch episodes."
                return
            }
        }
        
        await fetchEpisodes()
        await fetchRelatedNovelDetail()
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
    
    // Fetch episodes after series is loaded and id is set
    func fetchEpisodes() async {
        guard let seriesId = series.id else {
            print("🔴 Series ID nil, can't fetch episodes.")
            return
        }
        isLoadingEpisodes = true
        do {
            let fetchedEpisodes = try await seriesService.fetchEpisodes(for: seriesId)
            await MainActor.run {
                self.episodes = fetchedEpisodes
            }
            print("✅ Loaded episodes for series \(seriesId)")
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load episodes: \(error.localizedDescription)"
            }
        }
        isLoadingEpisodes = false
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
