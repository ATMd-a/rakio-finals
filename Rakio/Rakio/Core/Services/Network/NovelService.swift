import Foundation
import FirebaseFirestore

@MainActor
class NovelService: ObservableObject {
    private let db = Firestore.firestore()
    private let collectionName = "novels"

    // Fetches  the essential data for the list view
    func fetchAllNovels() async throws -> [Novel] {
        print("🔄 Fetching essential novel data from Firestore...")
        let snapshot = try await db.collection(collectionName).getDocuments()
        
        var novelsList: [Novel] = []
        for document in snapshot.documents {
            do {
                var novel = try document.data(as: Novel.self)
                novel.id = document.documentID
                novelsList.append(novel)
            } catch {
                print("⚠️ Error decoding document '\(document.documentID)': \(error)")
            }
        }
        return novelsList
    }

    // Fetches the full novel details for the detail view
    func fetchNovelDetail(by id: String) async throws -> NovelDetail {
            let documentRef = db.collection(collectionName).document(id)
            let documentSnapshot = try await documentRef.getDocument()
            
            guard documentSnapshot.exists else {
                throw NSError(domain: "FirestoreError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Novel with ID \(id) not found."])
            }
            
            var novelDetail = try documentSnapshot.data(as: NovelDetail.self)
            novelDetail.id = documentSnapshot.documentID
            return novelDetail
        }
}
