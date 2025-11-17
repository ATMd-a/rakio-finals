//
//  EpisodeYT.swift
//  Rakio
//
//  Created by STUDENT on 11/14/25.
//


//
//  Episode.swift
//  Test3
//
//  Created by STUDENT on 9/19/25.
//

import Foundation
import FirebaseFirestore

struct EpisodeYT: Identifiable, Codable {
    @DocumentID var id: String?
    let title: String
    let code: [String]
    let epNumber: Int // Make sure this matches your Firestore data type
    

    enum CodingKeys: String, CodingKey {
        case title, code, epNumber
    }
}
