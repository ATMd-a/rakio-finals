////
////  ContentService.swift
////  Rakio
////
////  Created by STUDENT on 11/19/25.
////
//
//
//import FirebaseFirestore
//
//class ContentService {
//    static let shared = ContentService()
//    private let db = Firestore.firestore()
//
//    private init() {}
//
//    func fetchContent(by id: String, type: ContentType) async throws -> Content {
//        let ref = db.collection(type.rawValue).document(id)
//        let snapshot = try await ref.getDocument()
//
//        guard let data = snapshot.data(),
//              let content = Content(id: snapshot.documentID, data: data)
//        else {
//            throw NSError(domain: "ContentError", code: 404, userInfo: nil)
//        }
//
//        return content
//    }
//}
