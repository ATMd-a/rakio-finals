import Foundation
import FirebaseFirestore

class SeriesService {
    private let db = Firestore.firestore()
    private let collectionName = "shows"

    // Fetch only series documents (no episodes)
    func fetchSeriesOnly() async throws -> [Series] {
        print("🔄 Fetching series only from Firestore...")
        let snapshot = try await db.collection(collectionName).getDocuments()
        print("📄 Documents fetched: \(snapshot.documents.count)")

        var seriesList: [Series] = []
        for document in snapshot.documents {
            do {
                var series = try document.data(as: Series.self)
                series.id = document.documentID
                seriesList.append(series)
                print("✅ Fetched series: \(series.title) with ID: \(series.id ?? "N/A")")
            } catch {
                print("⚠️ Error decoding document '\(document.documentID)': \(error)")
            }
        }
        print("🎯 Total series fetched: \(seriesList.count)")
        return seriesList
    }

    // Generic episode fetcher for any Codable type
    func fetchEpisodes<T: Codable & Identifiable>(for seriesId: String, subcollection: String) async throws -> [T] {
        print("🔄 Fetching '\(subcollection)' episodes for series ID: \(seriesId)")

        let snapshot = try await db.collection(collectionName)
            .document(seriesId)
            .collection(subcollection)
            .order(by: "epNumber")
            .getDocuments()

        print("🎯 Fetched \(snapshot.documents.count) documents from '\(subcollection)'.")

        var episodes: [T] = []

        for document in snapshot.documents {
            do {
                let episode = try document.data(as: T.self)
                episodes.append(episode)
            } catch {
                print("❌ Failed to decode document '\(document.documentID)' as \(T.self): \(error)")
            }
        }

        print("✅ Finished fetch. Total decoded episodes: \(episodes.count)")
        return episodes
    }

    // ✅ UPDATED: Both methods now return Episode (not separate types)
    func fetchYouTubeEpisodes(for seriesId: String) async throws -> [Episode] {
        try await fetchEpisodes(for: seriesId, subcollection: "episodes")
    }

    func fetchDailymotionEpisodes(for seriesId: String) async throws -> [Episode] {
        try await fetchEpisodes(for: seriesId, subcollection: "episodes 2")
    }

    // Fetch single series
    func fetchSeries(by id: String) async throws -> Series {
        let documentRef = db.collection(collectionName).document(id)
        let documentSnapshot = try await documentRef.getDocument()

        if documentSnapshot.exists {
            var series = try documentSnapshot.data(as: Series.self)
            series.id = documentSnapshot.documentID
            print("✅ Successfully fetched series: \(series.title)")
            return series
        } else {
            throw NSError(domain: "FirestoreError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Series with ID \(id) not found."])
        }
    }

    // Fetch novel
    func fetchNovel(by novelId: String) async throws -> Novel? {
        let novelRef = db.collection("novels").document(novelId)
        let document = try await novelRef.getDocument()
        return try? document.data(as: Novel.self)
    }
}
