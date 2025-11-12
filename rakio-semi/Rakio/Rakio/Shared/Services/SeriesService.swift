import Foundation
import FirebaseFirestore

class SeriesService {
    private let db = Firestore.firestore()
    private let collectionName = "shows"

    // Fetch only series documents, NO episodes subcollection
    func fetchSeriesOnly() async throws -> [Series] {
        print("🔄 Fetching series only from Firestore...")

        let snapshot = try await db.collection(collectionName).getDocuments()
        print("📄 Documents fetched: \(snapshot.documents.count)")

        var seriesList: [Series] = []
        for document in snapshot.documents {
            do {
                var series = try document.data(as: Series.self)
                // CRITICAL CHANGE: Manually set the id
                series.id = document.documentID
                seriesList.append(series)
                print("✅ Successfully decoded series: \(series.title) with ID: \(series.id ?? "N/A")")
            } catch {
                print("⚠️ Error decoding document '\(document.documentID)': \(error)")
            }
        }
        
        print("🎯 Total series fetched: \(seriesList.count)")
        return seriesList
    }
    
    func fetchEpisodes(for seriesId: String) async throws -> [Episode] {
        print("🔄 Starting episode fetch for series ID: \(seriesId)")

        do {
            let snapshot = try await db.collection(collectionName)
                .document(seriesId)
                .collection("episodes")
                .order(by: "epNumber") // ✅ Match the exact Firestore field
                .getDocuments()


            print("🎯 Fetched \(snapshot.documents.count) documents from episodes subcollection.")

            var episodes: [Episode] = []
            
            // Loop through each document and attempt to decode it individually
            for document in snapshot.documents {
                do {
                    // Try to decode the document into an Episode struct
                    let episode = try document.data(as: Episode.self)
                    print("✅ Successfully decoded episode: \(episode.title)")
                    episodes.append(episode)
                } catch {
                    // Catch a specific decoding error and print its details
                    print("❌ Failed to decode document '\(document.documentID)'.")
                    print("   - Error: \(error.localizedDescription)")
                    
                    // Here's the key: printing the error directly often provides
                    // the exact reason, like a missing or misspelled key.
                    print("   - Debug Description: \(error)")
                }
            }
            
            print("✅ Finished episode fetch. Total decoded episodes: \(episodes.count)")
            return episodes
        } catch {
            print("❌ Firestore fetch error for series ID \(seriesId): \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchSeries(by id: String) async throws -> Series {
        let documentRef = db.collection(collectionName).document(id)
        let documentSnapshot = try await documentRef.getDocument()
        
        if documentSnapshot.exists {
            var series = try documentSnapshot.data(as: Series.self)
            series.id = documentSnapshot.documentID
            print("✅ Successfully fetched single series: \(series.title)")
            return series
        } else {
            throw NSError(domain: "FirestoreError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Series with ID \(id) not found."])
        }
    }
    
    func fetchNovel(by novelId: String) async throws -> Novel? {
        let novelRef = db.collection("novels").document(novelId)
        let document = try await novelRef.getDocument()
        
        guard let novel = try? document.data(as: Novel.self) else {
            return nil
        }
        
        return novel
    }
}
