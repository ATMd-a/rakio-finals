import SwiftUI
import FirebaseAuth

struct EnhancedCommentsView: View {
    let contentId: String
    let contentType: ContentType
    
    @StateObject private var viewModel: CommentViewModel
    @State private var commentText: String = ""
    @State private var showLoginPrompt: Bool = false
    @FocusState private var isInputFocused: Bool
    
    init(contentId: String, contentType: ContentType) {
        self.contentId = contentId
        self.contentType = contentType
        _viewModel = StateObject(wrappedValue: CommentViewModel(
            contentId: contentId,
            contentType: contentType
        ))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Comments")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if !viewModel.comments.isEmpty {
                    Text("(\(viewModel.comments.count))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            // Comment Input
            commentInputSection
            
            // Comments List
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if viewModel.comments.isEmpty {
                emptyStateView
            } else {
                commentsListView
            }
        }
    }
    
    // MARK: - Comment Input Section
    @ViewBuilder
    private var commentInputSection: some View {
        if viewModel.isUserLoggedIn {
            loggedInInputView
        } else {
            loggedOutInputView
        }
    }
    
    private var loggedInInputView: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // User Avatar
                Circle()
                    .fill(Color.rakioPrimary.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(viewModel.username?.prefix(1).uppercased() ?? "U")
                            .font(.headline)
                            .foregroundColor(.white)
                    )
                
                // Text Input
                VStack(spacing: 8) {
                    TextEditor(text: $commentText)
                        .focused($isInputFocused)
                        .frame(minHeight: 60, maxHeight: 120)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                        .scrollContentBackground(.hidden)
                        .overlay(
                            Group {
                                if commentText.isEmpty {
                                    Text("Share your thoughts...")
                                        .foregroundColor(.gray)
                                        .padding(.leading, 12)
                                        .padding(.top, 16)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                    
                    // Action Buttons
                    HStack {
                        Button(action: { isInputFocused = false }) {
                            Image(systemName: "face.smiling")
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Button(action: { commentText = "" }) {
                            Text("Cancel")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .disabled(commentText.isEmpty)
                        
                        Button(action: postComment) {
                            HStack(spacing: 4) {
                                if viewModel.isPostingComment {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "paperplane.fill")
                                    Text("Post")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(commentText.isEmpty ? .gray : .white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(commentText.isEmpty ? Color.gray.opacity(0.3) : Color.rakioPrimary)
                            .cornerRadius(20)
                        }
                        .disabled(commentText.isEmpty || viewModel.isPostingComment)
                    }
                }
            }
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var loggedOutInputView: some View {
        Button(action: { showLoginPrompt = true }) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
                
                Text("Log in to join the conversation")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.subheadline)
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(.rakioPrimary)
                    .font(.title2)
            }
            .padding(12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .sheet(isPresented: $showLoginPrompt) {
            LoginPromptSheet()
        }
    }
    
    // MARK: - Comments List
    private var commentsListView: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.comments) { comment in
                CommentRow(
                    comment: comment,
                    onDelete: {
                        Task {
                            await viewModel.deleteComment(commentId: comment.id ?? "")
                        }
                    },
                    onLike: {
                        Task {
                            await viewModel.toggleLike(commentId: comment.id ?? "")
                        }
                    },
                    canDelete: viewModel.canDeleteComment(comment)
                )
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No comments yet")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
            
            Text("Be the first to share your thoughts!")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Actions
    private func postComment() {
        let trimmedText = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        Task {
            await viewModel.postComment(text: trimmedText)
            commentText = ""
            isInputFocused = false
        }
    }
}

// MARK: - Comment Row
struct CommentRow: View {
    let comment: Comment
    let onDelete: () -> Void
    let onLike: () -> Void
    let canDelete: Bool
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                // Avatar
                Circle()
                    .fill(Color.rakioPrimary.opacity(0.3))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(comment.username.prefix(1).uppercased())
                            .font(.subheadline)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    // Username and timestamp
                    HStack {
                        Text(comment.username)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("•")
                            .foregroundColor(.gray)
                        
                        Text(comment.timeAgo)
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        if canDelete {
                            Button(action: { showDeleteAlert = true }) {
                                Image(systemName: "trash")
                                    .font(.caption)
                                    .foregroundColor(.red.opacity(0.7))
                            }
                        }
                    }
                    
                    // Comment text
                    Text(comment.text)
                        .font(.body)
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Actions
                    HStack(spacing: 16) {
                        Button(action: onLike) {
                            HStack(spacing: 4) {
                                Image(systemName: "heart")
                                    .font(.caption)
                                if comment.likes > 0 {
                                    Text("\(comment.likes)")
                                        .font(.caption)
                                }
                            }
                            .foregroundColor(.gray)
                        }
                        
                        Button(action: {}) {
                            HStack(spacing: 4) {
                                Image(systemName: "bubble.right")
                                    .font(.caption)
                                Text("Reply")
                                    .font(.caption)
                            }
                            .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
        .alert("Delete Comment", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive, action: onDelete)
        } message: {
            Text("Are you sure you want to delete this comment? This action cannot be undone.")
        }
    }
}

// MARK: - Login Prompt Sheet
struct LoginPromptSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.rakioPrimary)
                
                VStack(spacing: 12) {
                    Text("Join the Conversation")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Log in to share your thoughts, like comments, and connect with other fans")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                NavigationLink(destination: LoginView(selectedTab: .constant(.account))) {
                    Text("Log In")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.rakioPrimary)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                NavigationLink(destination: SignupView(selectedTab: .constant(.account))) {
                    Text("Create Account")
                        .font(.headline)
                        .foregroundColor(.rakioPrimary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.rakioPrimary, lineWidth: 2)
                        )
                }
                .padding(.horizontal)
                
                Button("Maybe Later") {
                    dismiss()
                }
                .foregroundColor(.gray)
                .padding()
                
                Spacer()
            }
            .background(Color.rakioBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}
