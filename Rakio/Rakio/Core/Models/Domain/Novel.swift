//
//  Novel.swift
//  Test3
//
//  Created by STUDENT on 8/29/25.
//


import Foundation
import FirebaseFirestore

struct Novel: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var author: String
    var genre: [String]
    var imageName: String?
    var pdfURL: String?
    let relatedSeriesId: DocumentReference?
    
    enum CodingKeys: String, CodingKey {
        case title, description, author, genre, imageName, pdfURL, relatedSeriesId
    }
    
    
}
