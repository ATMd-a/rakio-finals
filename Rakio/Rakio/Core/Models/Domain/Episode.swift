import Foundation
import FirebaseFirestore

struct Episode: Identifiable, Codable {
    @DocumentID var id: String?
    let title: String
    let code: [String]
    let epNumber: Int 
    

    enum CodingKeys: String, CodingKey {
        case title, code, epNumber
    }
}
