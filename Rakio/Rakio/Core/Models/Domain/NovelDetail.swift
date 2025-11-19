//
//  NovelDetail.swift
//  Test3
//
//  Created by STUDENT on 9/24/25.
//


import Foundation
import FirebaseFirestore

struct NovelDetail: Identifiable, Codable {
    @DocumentID var id: String?
    let title: String
    let author: String
    let description: String
    let genre: [String]
    let imageName: String?
    let txtFileName: String?
    let relatedSeriesId: DocumentReference?

    var chapters: [Chapter]? = nil
}
