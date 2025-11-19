import Foundation
import FirebaseFirestore
import FirebaseAuth



// MARK: - Comment Service
class CommentService {
    static let shared = CommentService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Fetch Comments
    func fetchComments(for contentId: String, contentType: ContentType) async throws -> [Comment] {
        let collectionPath = "\(contentType.rawValue)/\(contentId)/comments"
        
        let snapshot = try await db.collection(collectionPath)
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            var comment = try? doc.data(as: Comment.self)
            comment?.id = doc.documentID
            return comment
        }
    }
    
    // MARK: - Post Comment
    func postComment(
        contentId: String,
        contentType: ContentType,
        text: String,
        username: String
    ) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw CommentError.userNotAuthenticated
        }
        
        let commentData: [String: Any] = [
            "userId": userId,
            "username": username,
            "text": text,
            "timestamp": FieldValue.serverTimestamp(),
            "likes": 0,
            "replies": []
        ]

        let collectionPath = "\(contentType.rawValue)/\(contentId)/comments"
        try await db.collection(collectionPath).addDocument(data: commentData)
    }
    
    // MARK: - Delete Comment
    func deleteComment(
        contentId: String,
        contentType: ContentType,
        commentId: String
    ) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw CommentError.userNotAuthenticated
        }
        
        let docRef = db.collection("\(contentType.rawValue)/\(contentId)/comments")
                        .document(commentId)
        
        let doc = try await docRef.getDocument()
        guard let comment = try? doc.data(as: Comment.self),
              comment.userId == userId else {
            throw CommentError.unauthorized
        }

        try await docRef.delete()
    }
    
    // MARK: - Like Comment
    func toggleLike(
        contentId: String,
        contentType: ContentType,
        commentId: String
    ) async throws {
        guard Auth.auth().currentUser != nil else {
            throw CommentError.userNotAuthenticated
        }
        
        let docRef = db.collection("\(contentType.rawValue)/\(contentId)/comments")
                        .document(commentId)
        
        try await docRef.updateData([
            "likes": FieldValue.increment(Int64(1))
        ])
    }
}

// MARK: - Supporting Types
enum ContentType: String, Codable {
    case shows
    case novels
}

enum CommentError: Error, LocalizedError {
    case userNotAuthenticated
    case unauthorized
    case invalidContent
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "You must be logged in to perform this action"
        case .unauthorized:
            return "You don't have permission to perform this action"
        case .invalidContent:
            return "Invalid content"
        }
    }
}
