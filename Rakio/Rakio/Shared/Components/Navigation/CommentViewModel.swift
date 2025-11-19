import Foundation
import SwiftUI
import FirebaseAuth

@MainActor
class CommentViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var isLoading = false
    @Published var isPostingComment = false
    @Published var errorMessage: String?
    @Published var isUserLoggedIn = false
    @Published var username: String?
    
    private let contentId: String
    private let contentType: ContentType
    private let commentService = CommentService.shared
    
    init(contentId: String, contentType: ContentType) {
        self.contentId = contentId
        self.contentType = contentType
        checkAuthStatus()
        Task {
            await fetchComments()
        }
    }
    
    // MARK: - Auth Check
    func checkAuthStatus() {
        if let currentUser = Auth.auth().currentUser {
            isUserLoggedIn = true
            // Get username from Firestore or use email
            username = currentUser.displayName ?? currentUser.email?.components(separatedBy: "@").first
        } else {
            isUserLoggedIn = false
            username = nil
        }
    }
    
    // MARK: - Fetch Comments
    func fetchComments() async {
        isLoading = true
        errorMessage = nil
        
        do {
            comments = try await commentService.fetchComments(
                for: contentId,
                contentType: contentType
            )
        } catch {
            errorMessage = "Failed to load comments: \(error.localizedDescription)"
            print("❌ Error fetching comments: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Post Comment
    func postComment(text: String) async {
        guard isUserLoggedIn, let username = username else {
            errorMessage = "You must be logged in to comment"
            return
        }
        
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Comment cannot be empty"
            return
        }
        
        isPostingComment = true
        errorMessage = nil
        
        do {
            try await commentService.postComment(
                contentId: contentId,
                contentType: contentType,
                text: text,
                username: username
            )
            
            // Refresh comments
            await fetchComments()
            
            // Show success feedback
            withAnimation {
                // Could add a success message here
            }
            
        } catch {
            errorMessage = "Failed to post comment: \(error.localizedDescription)"
            print("❌ Error posting comment: \(error)")
        }
        
        isPostingComment = false
    }
    
    // MARK: - Delete Comment
    func deleteComment(commentId: String) async {
        guard isUserLoggedIn else { return }
        
        do {
            try await commentService.deleteComment(
                contentId: contentId,
                contentType: contentType,
                commentId: commentId
            )
            
            // Remove from local array immediately for better UX
            withAnimation {
                comments.removeAll { $0.id == commentId }
            }
            
        } catch {
            errorMessage = "Failed to delete comment: \(error.localizedDescription)"
            print("❌ Error deleting comment: \(error)")
        }
    }
    
    // MARK: - Like Comment
    func toggleLike(commentId: String) async {
        guard isUserLoggedIn else {
            errorMessage = "You must be logged in to like comments"
            return
        }
        
        // Optimistic update
        if let index = comments.firstIndex(where: { $0.id == commentId }) {
            // Note: This is simplified. In production, track user's likes separately
            comments[index] = Comment(
                id: comments[index].id,
                userId: comments[index].userId,
                username: comments[index].username,
                userProfileImageUrl: comments[index].userProfileImageUrl,
                text: comments[index].text,
                timestamp: comments[index].timestamp,
                likes: comments[index].likes + 1,
                replies: comments[index].replies
            )
        }
        
        do {
            try await commentService.toggleLike(
                contentId: contentId,
                contentType: contentType,
                commentId: commentId
            )
        } catch {
            // Revert on error
            await fetchComments()
            errorMessage = "Failed to like comment"
            print("❌ Error liking comment: \(error)")
        }
    }
    
    // MARK: - Permissions
    func canDeleteComment(_ comment: Comment) -> Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            return false
        }
        return comment.userId == currentUserId
    }
    
    // MARK: - Refresh
    func refresh() async {
        checkAuthStatus()
        await fetchComments()
    }
}
