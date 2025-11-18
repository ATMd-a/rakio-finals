import FirebaseFirestore

struct UserModel: Codable, Identifiable {
    @DocumentID var id: String?  // Firestore document ID, same as uid
    let uid: String
    let email: String
    let username: String
    let createdAt: Date?
    var watchHistory: [String: WatchHistoryItem]  // Changed to dictionary
    var favorites: [String]
//    var reminders: [Reminder]
//    var settings: UserSettings

    struct WatchHistoryItem: Codable {
        let lastWatchedAt: Date
        let progress: Double
    }
}
