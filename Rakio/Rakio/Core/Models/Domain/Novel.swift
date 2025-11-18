//
//  Novel.swift
//  Test3
//
//  Created by STUDENT on 8/29/25.
//

//import Foundation
//import FirebaseFirestore
//
//struct Novel: Identifiable, Codable {
//    @DocumentID var id: String?
//    let coverImageName: String?
//    let coverImageURL: String?
//    let title: String
//    let author: String
//    let description: String
//    let genre: [String]
////    let rating: Double?
////    let totalChapters: Int
//    let isCompleted: Bool
//    let isActive: Bool
//    let createdAt: Timestamp?
//    let updatedAt: Timestamp?
//    
//    enum CodingKeys: String, CodingKey {
//        case coverImageName = "cover_image_name"
//        case coverImageURL = "cover_image_url"
//        case title
//        case author
//        case description
//        case genre
//        case rating
//        case totalChapters = "total_chapters"
//        case isCompleted = "is_completed"
//        case isActive = "is_active"
//        case createdAt = "created_at"
//        case updatedAt = "updated_at"
//    }
//    
//    // Computed property for display image
//    var displayImageName: String {
//        return coverImageName ?? "placeholder"
//    }
//}


import Foundation
import FirebaseFirestore

struct Novel: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var author: String // Added from your UI code
    var genre: [String]
    var imageName: String?
    var pdfURL: String? // Added for the "Read" button
    let relatedSeriesId: DocumentReference?  // Added to link to a series
    
    // Make sure to add the new properties to the CodingKeys if you use them
    enum CodingKeys: String, CodingKey {
        case title, description, author, genre, imageName, pdfURL, relatedSeriesId
    }
    
    
}
