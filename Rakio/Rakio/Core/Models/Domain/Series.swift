import Foundation
import FirebaseFirestore

struct Series: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var genre: [String]
    var isSeries: Bool
    var dateReleased: Timestamp
    var trailerURL: String
    var imageName: String
    var relatedNovelId: DocumentReference?

    enum CodingKeys: String, CodingKey {
        case title, description, genre, isSeries, trailerURL, imageName, dateReleased, relatedNovelId
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dateReleased.dateValue())
    }
    
    
}
extension Series {
    func strippedForSaving() -> Series {
        return Series(
            id: self.id,
            title: self.title,
            description: self.description,
            genre: self.genre,
            isSeries: self.isSeries,
            dateReleased: self.dateReleased,
            trailerURL: self.trailerURL,
            imageName: self.imageName,
            relatedNovelId: nil
        )
    }
}
