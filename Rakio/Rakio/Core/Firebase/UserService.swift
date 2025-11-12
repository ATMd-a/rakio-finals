import FirebaseFirestore
import FirebaseAuth

enum AuthError: Error {
    case userNotLoggedIn
}

class UserService {
    static let shared = UserService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Fetch Current User
    func fetchCurrentUser() async throws -> UserModel? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        let doc = try await db.collection("users").document(uid).getDocument()
        if let data = doc.data() {
            return try Firestore.Decoder().decode(UserModel.self, from: data)
        }
        return nil
    }
    
    // MARK: - Fetch Favorites
    func fetchFavoriteSeries(for user: UserModel) async throws -> [Series] {
        let favorites = user.favorites
        guard !favorites.isEmpty else { return [] }
        
        var allSeries: [Series] = []
        let batchSize = 10
        let batches = stride(from: 0, to: favorites.count, by: batchSize).map {
            Array(favorites[$0..<min($0 + batchSize, favorites.count)])
        }
        
        for batch in batches {
            let querySnapshot = try await db.collection("shows")
                .whereField(FieldPath.documentID(), in: batch)
                .getDocuments()
            
            for doc in querySnapshot.documents {
                print("📄 Attempting to decode series document: \(doc.documentID)")
                print("📦 Raw data: \(doc.data())")
                
                do {
                    let series = try doc.data(as: Series.self)
                    allSeries.append(series)
                } catch let error as DecodingError {
                    print("❌ Decoding error for document \(doc.documentID): \(error)")
                    
                    switch error {
                    case .typeMismatch(let type, let context):
                        print("⚠️ Type mismatch for \(type): \(context.debugDescription)")
                        print("   Coding path: \(context.codingPath)")
                    case .valueNotFound(let type, let context):
                        print("⚠️ Value not found for \(type): \(context.debugDescription)")
                        print("   Coding path: \(context.codingPath)")
                    case .keyNotFound(let key, let context):
                        print("⚠️ Key '\(key.stringValue)' not found: \(context.debugDescription)")
                        print("   Coding path: \(context.codingPath)")
                    case .dataCorrupted(let context):
                        print("⚠️ Data corrupted: \(context.debugDescription)")
                        print("   Coding path: \(context.codingPath)")
                    @unknown default:
                        print("⚠️ Unknown decoding error")
                    }
                } catch {
                    print("❗Unexpected error decoding document \(doc.documentID): \(error.localizedDescription)")
                }
            }
        }
        
        return allSeries
    }
    
    // MARK: - Favorites Management
    func addSeriesToFavorites(seriesId: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userRef = db.collection("users").document(uid)
        try await userRef.updateData([
            "favorites": FieldValue.arrayUnion([seriesId])
        ])
    }
    
    func removeSeriesFromFavorites(seriesId: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userRef = db.collection("users").document(uid)
        try await userRef.updateData([
            "favorites": FieldValue.arrayRemove([seriesId])
        ])
    }
    
    func isSeriesFavorited(seriesId: String) async -> Bool {
        do {
            if let user = try await fetchCurrentUser() {
                return user.favorites.contains(seriesId)
            }
        } catch {
            print("Error checking favorite: \(error)")
        }
        return false
    }
    
    //to be removed
    
    func backfillMissingSeriesIds() async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userRef = db.collection("users").document(uid)
        let doc = try await userRef.getDocument()
        
        guard var watchHistory = doc.data()?["watchHistory"] as? [String: [String: Any]] else { return }
        
        for (contentId, data) in watchHistory {
            if data["seriesId"] == nil {
                let querySnapshot = try await db.collectionGroup("episodes")
                    .whereField("videoIds", arrayContains: contentId)
                    .getDocuments()
                
                guard let doc = querySnapshot.documents.first,
                      let seriesId = doc.reference.parent.parent?.documentID else {
                    print("⚠️ Could not find seriesId for contentId \(contentId)")
                    continue
                }

                try await userRef.updateData([
                    "watchHistory.\(contentId).seriesId": seriesId
                ])
                print("✅ Backfilled seriesId \(seriesId) for contentId \(contentId)")
            }
        
        }
        
        try await userRef.updateData(["watchHistory": watchHistory])
    }
 
    // MARK: - Watch History Management
    func updateWatchHistory(
        for contentId: String,
        seriesId: String? = nil, // optional
        lastWatchedAt: Date,
        progress: Double
    ) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw AuthError.userNotLoggedIn
        }
        
        var seriesIdToSave = seriesId
        
        // Lookup seriesId if not provided
        if seriesIdToSave == nil {
            let querySnapshot = try await db.collectionGroup("episodes")
                .whereField("videoIds", arrayContains: contentId)
                .getDocuments()
            
            if let doc = querySnapshot.documents.first {
                seriesIdToSave = doc.reference.parent.parent?.documentID
            }
        }

        
        guard let finalSeriesId = seriesIdToSave else {
            print("⚠️ Could not determine seriesId for content \(contentId)")
            return
        }
        
        let watchHistoryData: [String: Any] = [
            "lastWatchedAt": Timestamp(date: lastWatchedAt),
            "progress": progress,
            "seriesId": finalSeriesId
        ]
        
        try await db.collection("users").document(uid).updateData([
            "watchHistory.\(contentId)": watchHistoryData
        ])
    }

    func markEpisodeWatched(contentId: String, seriesId: String, progress: Double) async {
        do {
            try await UserService.shared.updateWatchHistory(
                for: contentId,
                seriesId: seriesId, // ⚠️ Must pass the series ID here
                lastWatchedAt: Date(),
                progress: progress
            )
            print("✅ Watch history updated")
        } catch {
            print("❌ Failed to update watch history: \(error)")
        }
    }


    // MARK: - Fetch Watched Series
    // MARK: - Fetch Watched Videos (by videoId, not seriesId)
    // MARK: - Fetch Watched Videos (using videoId instead of seriesId)
    func fetchWatchedVideos() async throws -> [WatchedContent] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthError.userNotLoggedIn
        }

        print("🔄 Fetching watched videos for user \(userId)...")

        let userDoc = try await db.collection("users").document(userId).getDocument()

        guard let watchHistory = userDoc.data()?["watchHistory"] as? [String: [String: Any]],
              !watchHistory.isEmpty else {
            print("❌ No watch history found.")
            return []
        }

        var watchedVideos: [WatchedContent] = []

        for (videoId, data) in watchHistory {
            let timestamp = (data["lastWatchedAt"] as? Timestamp)?.dateValue() ?? Date()
            let progress = data["progress"] as? Double ?? 0.0
            let title = data["title"] as? String ?? "Untitled Video"
            let thumbnailURL = data["thumbnailURL"] as? String

            let seriesTitle = data["seriesTitle"] as? String
            let episodeTitle = data["episodeTitle"] as? String
            let isEpisode = data["isEpisode"] as? Bool ?? false

            let watchedItem = WatchedContent(
                videoId: videoId,
                title: title,
                thumbnailURL: thumbnailURL,
                lastWatchedAt: timestamp,
                progress: progress,
                seriesTitle: seriesTitle,
                episodeTitle: episodeTitle,
                isEpisode: isEpisode
            )

            watchedVideos.append(watchedItem)
        }

        let sortedVideos = watchedVideos.sorted { $0.lastWatchedAt > $1.lastWatchedAt }
        print("✅ Loaded \(sortedVideos.count) watched videos.")
        return sortedVideos
    }


}
