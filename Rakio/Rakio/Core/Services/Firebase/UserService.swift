import FirebaseFirestore
import FirebaseAuth

enum AuthError: Error {
    case userNotLoggedIn
}

class UserService {
    static let shared = UserService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    //Fetch Current User
    func fetchCurrentUser() async throws -> UserModel? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        let doc = try await db.collection("users").document(uid).getDocument()
        if let data = doc.data() {
            return try Firestore.Decoder().decode(UserModel.self, from: data)
        }
        return nil
    }
    
    //Fetch Favorites
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
    
    //Favorites Management
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
    
    
    func backfillMissingSeriesIds() async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userRef = db.collection("users").document(uid)
        let doc = try await userRef.getDocument()
        
        guard let watchHistory = doc.data()?["watchHistory"] as? [String: [String: Any]] else { return }
        
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
    }
    
    //Watch History Management
    func updateWatchHistory(
        for videoId: String,
        episodeTitle: String,
        seriesId: String? = nil,
        lastWatchedAt: Date,
        progress: Double
    ) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw AuthError.userNotLoggedIn
        }
        
        let userRef = db.collection("users").document(uid)
        let doc = try await userRef.getDocument()
        var watchHistory = doc.data()?["watchHistory"] as? [String: [String: Any]] ?? [:]
        
        var existingEntry = watchHistory[episodeTitle] ?? [:]
        var videoIds = existingEntry["videoIds"] as? [String] ?? []
        if !videoIds.contains(videoId) {
            videoIds.append(videoId)
        }
        
        if existingEntry["seriesId"] == nil, let seriesId = seriesId {
            existingEntry["seriesId"] = seriesId
        }
        
        existingEntry["lastWatchedAt"] = Timestamp(date: lastWatchedAt)
        existingEntry["progress"] = progress
        existingEntry["videoIds"] = videoIds
        
        watchHistory[episodeTitle] = existingEntry
        
        try await userRef.updateData(["watchHistory": watchHistory])
        print("✅ Watch history updated for '\(episodeTitle)' with videoId \(videoId)")
    }
    
    
    func markEpisodeWatched(videoId: String, episodeTitle: String, seriesId: String, progress: Double) async {
        do {
            try await updateWatchHistory(
                for: videoId,
                episodeTitle: episodeTitle,
                seriesId: seriesId,
                lastWatchedAt: Date(),
                progress: progress
            )
        } catch {
            print("❌ Failed to mark episode watched: \(error)")
        }
    }

    //Fetch Watched Series
    func fetchWatchedVideos() async throws -> [WatchedContent] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthError.userNotLoggedIn
        }
        
        let userDoc = try await db.collection("users").document(userId).getDocument()
        guard let watchHistory = userDoc.data()?["watchHistory"] as? [String: [String: Any]],
              !watchHistory.isEmpty else {
            return []
        }
        
        var watchedVideos: [WatchedContent] = []
        
        for (videoId, data) in watchHistory {
            let timestamp = (data["lastWatchedAt"] as? Timestamp)?.dateValue() ?? Date()
            let progress = data["progress"] as? Double ?? 0.0
            let thumbnailData = ThumbnailData.generate(for: videoId)
            let querySnapshot = try await db.collectionGroup("episodes")
                .whereField("code", arrayContains: videoId)
                .limit(to: 1)
                .getDocuments()
            
            let episodeTitle: String
            if let episodeDoc = querySnapshot.documents.first,
               let episode = try? episodeDoc.data(as: Episode.self) {
                episodeTitle = episode.title
            } else {
                episodeTitle = "Episode"
            }
            
            let watchedItem = WatchedContent(
                videoId: videoId,
                title: episodeTitle,
                thumbnailURL: thumbnailData.url,
                lastWatchedAt: timestamp,
                progress: progress,
                seriesTitle: nil,
                episodeTitle: episodeTitle,
                isEpisode: true
            )
            
            watchedVideos.append(watchedItem)
        }
        
        return watchedVideos.sorted { $0.lastWatchedAt > $1.lastWatchedAt }
    }
}
