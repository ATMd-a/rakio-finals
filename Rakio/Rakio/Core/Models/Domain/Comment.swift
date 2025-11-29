import Foundation
import FirebaseFirestore

struct Comment: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let username: String
    let userProfileImageUrl: String?
    let text: String
    let timestamp: Timestamp
    let likes: Int
    let replies: [Reply]?
    
    enum CodingKeys: String, CodingKey {
        case userId, username, userProfileImageUrl, text, timestamp, likes, replies
    }
    
    // Computed property for display
    var timeAgo: String {
        let date = timestamp.dateValue()
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct Reply: Identifiable, Codable {
    var id: String { userId + timestamp.description }
    let userId: String
    let username: String
    let text: String
    let timestamp: Timestamp
}
