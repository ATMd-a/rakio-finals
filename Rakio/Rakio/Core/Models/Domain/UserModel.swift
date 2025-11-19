import FirebaseFirestore

struct UserModel: Codable, Identifiable {
    @DocumentID var id: String?
    let uid: String
    let email: String
    let username: String
    let createdAt: Date?
    var watchHistory: [String: WatchHistoryItem]
    var favorites: [String]

    struct WatchHistoryItem: Codable {
        let lastWatchedAt: Date
        let progress: Double
    }
}
