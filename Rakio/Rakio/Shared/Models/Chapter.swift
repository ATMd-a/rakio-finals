import Foundation
import FirebaseFirestore

// --- Chapter (LATEST, CORRECT VERSION) ---
struct Chapter: Identifiable, Codable {
    @DocumentID var id: String?
    let title: String
    let heartCount: Int
    let content: String
    let type: String          // "synopsis", "chapter", "special chapter", etc.
    let number: Int?          // The extracted chapter number (e.g., 1, 2, 3)
    let sortOrder: Int        // CRITICAL: The chronological position in the TXT file.
}
