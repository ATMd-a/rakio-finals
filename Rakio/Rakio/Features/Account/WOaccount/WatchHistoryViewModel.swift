//import SwiftUI
//import FirebaseAuth
//import FirebaseFirestore
//
//@MainActor
//class WatchHistoryViewModel: ObservableObject {
//    @Published var recentWatchedVideos: [WatchedContent] = []
//    @Published var isLoading = false
//    @Published var errorMessage: String?
//
//    func fetchRecentHistory() async {
//        guard let uid = Auth.auth().currentUser?.uid else {
//            print("⚠️ No user logged in")
//            self.recentWatchedVideos = []
//            self.errorMessage = nil
//            return
//        }
//
//        self.isLoading = true
//        self.errorMessage = nil
//
//        do {
//            // ✅ Fetch videos directly from subcollection
//            let snapshot = try await Firestore.firestore()
//                .collection("users")
//                .document(uid)
//                .collection("watchedContent")
//                .order(by: "lastWatchedAt", descending: true)
//                .getDocuments()
//
//            var tempHistory: [WatchedContent] = []
//
//            for doc in snapshot.documents {
//                let data = doc.data()
//
//                // ✅ Expect each doc to represent a video item
//                let videoId = data["videoId"] as? String ?? doc.documentID
//                let title = data["title"] as? String ?? "Untitled Video"
//                let thumbnailURL = data["thumbnailURL"] as? String
//                let progress = data["progress"] as? Double ?? 0.0
//                let lastWatchedAt = (data["lastWatchedAt"] as? Timestamp)?.dateValue() ?? Date()
//
//                // Optional episode/series context if you still store it
//                let seriesTitle = data["seriesTitle"] as? String
//                let episodeTitle = data["episodeTitle"] as? String
//                let isEpisode = data["isEpisode"] as? Bool ?? false
//
//                let watchedItem = WatchedContent(
//                    videoId: videoId,
//                    title: title,
//                    thumbnailURL: thumbnailURL,
//                    lastWatchedAt: lastWatchedAt,
//                    progress: progress,
//                    seriesTitle: seriesTitle,
//                    episodeTitle: episodeTitle,
//                    isEpisode: isEpisode
//                )
//
//                tempHistory.append(watchedItem)
//            }
//
//            // ✅ Keep only the most recent 5
//            self.recentWatchedVideos = Array(tempHistory.prefix(5))
//            print("✅ Loaded \(self.recentWatchedVideos.count) recent watched videos")
//
//        } catch {
//            print("❌ Failed to fetch watch history: \(error.localizedDescription)")
//            self.errorMessage = "Unable to load watch history"
//            self.recentWatchedVideos = []
//        }
//
//        self.isLoading = false
//    }
//
//    func refresh() async {
//        await fetchRecentHistory()
//    }
//}
