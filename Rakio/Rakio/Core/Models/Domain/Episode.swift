////
////  Episode.swift
////  Test3
////
////  Created by STUDENT on 9/19/25.
////
//
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
