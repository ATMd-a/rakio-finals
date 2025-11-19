//
//  CommentsSectionView.swift
//  Rakio
//
//  Created by STUDENT on 11/19/25.
//

import SwiftUI
import FirebaseAuth

/// A complete, reusable comments section that can be added to any content
struct CommentsSectionView: View {
    let contentId: String
    let contentType: ContentType
    
    @StateObject private var viewModel: CommentViewModel
    @State private var commentText = ""
    @State private var showLoginPrompt = false
    @State private var sortOption: CommentSortOption = .newest
    @State private var showSortMenu = false
    
    private var sortedComments: [Comment] {
        sortOption.sort(viewModel.comments)
    }
    
    init(contentId: String, contentType: ContentType) {
        self.contentId = contentId
        self.contentType = contentType
        _viewModel = StateObject(wrappedValue: CommentViewModel(
            contentId: contentId,
            contentType: contentType
        ))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            headerSection
            
            // Sort and Stats
            if !viewModel.comments.isEmpty {
                sortAndStatsSection
            }
            
            // Comment Input
            if viewModel.isUserLoggedIn {
                CommentInputView(
                    text: $commentText,
                    isPosting: $viewModel.isPostingComment,
                    username: viewModel.username,
                    onPost: postComment,
                    onCancel: { commentText = "" }
                )
            } else {
                loginPromptButton
            }
            
            // Comments List
            commentsContent
        }
        .onAppear {
            viewModel.checkAuthStatus()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Comments")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if !viewModel.comments.isEmpty {
                    Text("\(viewModel.comments.count) comment\(viewModel.comments.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Refresh Button
            Button(action: { Task { await viewModel.fetchComments() } }) {
                Image(systemName: "arrow.clockwise")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    // MARK: - Sort and Stats Section
    private var sortAndStatsSection: some View {
        HStack {
            // Sort Menu
            Menu {
                ForEach(CommentSortOption.allCases, id: \.self) { option in
                    Button(action: { sortOption = option }) {
                        HStack {
                            Text(option.rawValue)
                            if sortOption == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.caption)
                    Text(sortOption.rawValue)
                        .font(.subheadline)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1))
                .cornerRadius(20)
            }
            
            Spacer()
            
            // Stats
            let stats = CommentStatistics.from(comments: viewModel.comments)
            if stats.totalLikes > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                    Text("\(stats.totalLikes)")
                        .font(.caption)
                }
                .foregroundColor(.gray)
            }
        }
    }
    
    // MARK: - Login Prompt
    private var loginPromptButton: some View {
        Button(action: { showLoginPrompt = true }) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Join the conversation")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Log in to comment")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(.rakioPrimary)
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .sheet(isPresented: $showLoginPrompt) {
            LoginPromptSheet()
        }
    }
    
    // MARK: - Comments Content
    @ViewBuilder
    private var commentsContent: some View {
        if viewModel.isLoading {
            loadingView
        } else if viewModel.comments.isEmpty {
            emptyStateView
        } else {
            commentsList
        }
        
        // Error Message
        if let error = viewModel.errorMessage {
            errorView(error)
        }
    }
    
    private var loadingView: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                Text("Loading comments...")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 40)
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No comments yet")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
            
            Text(viewModel.isUserLoggedIn 
                 ? "Be the first to share your thoughts!"
                 : "Log in to start the conversation")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }
    
    private var commentsList: some View {
        VStack(spacing: 16) {
            ForEach(sortedComments) { comment in
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
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
    }
    
    private func errorView(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .font(.caption)
                .foregroundColor(.orange)
            Spacer()
            Button("Dismiss") {
                viewModel.errorMessage = nil
            }
            .font(.caption)
            .foregroundColor(.white)
        }
        .padding(12)
        .background(Color.orange.opacity(0.2))
        .cornerRadius(8)
    }
    
    // MARK: - Actions
    private func postComment() {
        let trimmed = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        Task {
            await viewModel.postComment(text: trimmed)
            commentText = ""
        }
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        CommentsSectionView(
            contentId: "test123",
            contentType: .shows
        )
        .padding()
    }
    .background(Color.rakioBackground)
}
