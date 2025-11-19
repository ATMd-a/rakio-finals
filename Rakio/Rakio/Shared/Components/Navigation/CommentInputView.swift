//
//  CommentInputView.swift
//  Rakio
//
//  Created by STUDENT on 11/19/25.
//


//
//  CommentInputView.swift
//  Rakio
//
//  Created by STUDENT on 11/19/25.
//

import SwiftUI

struct CommentInputView: View {
    @Binding var text: String
    @Binding var isPosting: Bool
    let username: String?
    let onPost: () -> Void
    let onCancel: () -> Void
    
    @FocusState private var isFocused: Bool
    @State private var validationError: String?
    @State private var showEmojiPicker = false
    
    private var characterCount: Int {
        text.trimmingCharacters(in: .whitespacesAndNewlines).count
    }
    
    private var isValidComment: Bool {
        let validation = CommentValidator.validate(text)
        validationError = validation.errorMessage
        return validation.isValid
    }
    
    private var characterLimit: Int {
        CommentValidator.maxLength
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                // User Avatar
                Circle()
                    .fill(Color.rakioPrimary.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(username?.prefix(1).uppercased() ?? "U")
                            .font(.headline)
                            .foregroundColor(.white)
                    )
                
                // Input Area
                VStack(alignment: .leading, spacing: 8) {
                    // Text Editor
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $text)
                            .focused($isFocused)
                            .frame(minHeight: 80, maxHeight: 150)
                            .padding(12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .scrollContentBackground(.hidden)
                            .onChange(of: text) { oldValue, newValue in
                                // Enforce character limit
                                if newValue.count > characterLimit {
                                    text = String(newValue.prefix(characterLimit))
                                }
                            }
                        
                        // Placeholder
                        if text.isEmpty {
                            Text("Share your thoughts...")
                                .foregroundColor(.gray)
                                .padding(.leading, 16)
                                .padding(.top, 20)
                                .allowsHitTesting(false)
                        }
                    }
                    
                    // Character Counter
                    HStack {
                        if characterCount > 0 {
                            Text("\(characterCount)/\(characterLimit)")
                                .font(.caption2)
                                .foregroundColor(characterCount > characterLimit * 9/10 ? .orange : .gray)
                        }
                        
                        Spacer()
                    }
                    
                    // Validation Error
                    if let error = validationError, !text.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                            Text(error)
                                .font(.caption2)
                        }
                        .foregroundColor(.orange)
                    }
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        // Emoji/Tools
                        Button(action: { showEmojiPicker.toggle() }) {
                            Image(systemName: "face.smiling")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        // Cancel Button
                        Button(action: handleCancel) {
                            Text("Cancel")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(20)
                        }
                        .disabled(isPosting)
                        
                        // Post Button
                        Button(action: handlePost) {
                            HStack(spacing: 6) {
                                if isPosting {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "paperplane.fill")
                                        .font(.subheadline)
                                    Text("Post")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(isValidComment && !isPosting ? Color.rakioPrimary : Color.gray.opacity(0.3))
                            .cornerRadius(20)
                        }
                        .disabled(!isValidComment || isPosting)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - Actions
    
    private func handlePost() {
        guard isValidComment else { return }
        isFocused = false
        onPost()
    }
    
    private func handleCancel() {
        text = ""
        isFocused = false
        validationError = nil
        onCancel()
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.rakioBackground.ignoresSafeArea()
        
        CommentInputView(
            text: .constant(""),
            isPosting: .constant(false),
            username: "JohnDoe",
            onPost: {},
            onCancel: {}
        )
        .padding()
    }
}