import Foundation
import FirebaseFirestore

struct Chapter: Identifiable, Codable {
    @DocumentID var id: String?
    let title: String
    let heartCount: Int
    let content: String
    let type: String
    let number: Int?
    let sortOrder: Int
}
