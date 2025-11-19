////
////  Content.swift
////  Rakio
////
////  Created by STUDENT on 11/19/25.
////
//
//import Foundation
//import FirebaseFirestore
//
//struct ContentType: Identifiable, Codable {
//
//    // Firestore document ID (manually assigned when loading)
//    var id: String?
//
////    let title: String
//    let description: String
//    let imageUrl: String?
//    let author: String?
//    let releaseDate: Date?
//    let type: ContentType
//
//    enum CodingKeys: String, CodingKey {
//        case title
//        case description
//        case imageUrl
//        case author
//        case releaseDate
//        case type
//    }
//
//    /// Manual initializer for loading from Firestore
//    init?(id: String?, data: [String: Any]) {
//        guard
//            let title = data["title"] as? String,
//            let description = data["description"] as? String,
//            let typeString = data["type"] as? String,
//            let type = ContentType(rawValue: typeString)
//        else { return nil }
//
//        self.id = id
//        self.title = title
//        self.description = description
//        self.imageUrl = data["imageUrl"] as? String
//        self.author = data["author"] as? String
//
//        // Handle Firestore timestamp
//        if let timestamp = data["releaseDate"] as? Timestamp {
//            self.releaseDate = timestamp.dateValue()
//        } else {
//            self.releaseDate = nil
//        }
//
//        self.type = type
//    }
//}
//
//// MARK: - Content Type
//enum ContentType: String, Codable {
//    case shows
//    case novels
//}
