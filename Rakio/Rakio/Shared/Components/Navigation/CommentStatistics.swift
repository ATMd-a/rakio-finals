import Foundation
import SwiftUI

// Comment Statistics
struct CommentStatistics {
    let totalComments: Int
    let totalLikes: Int
    let mostRecentComment: Date?
    
    static func from(comments: [Comment]) -> CommentStatistics {
        let totalLikes = comments.reduce(0) { $0 + $1.likes }
        let mostRecent = comments.map { $0.timestamp.dateValue() }.max()
        
        return CommentStatistics(
            totalComments: comments.count,
            totalLikes: totalLikes,
            mostRecentComment: mostRecent
        )
    }
}

// MARK: - Comment Validation
struct CommentValidator {
    static let minLength = 1
    static let maxLength = 500
    
    static func validate(_ text: String) -> ValidationResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .invalid("Comment cannot be empty")
        }
        
        if trimmed.count < minLength {
            return .invalid("Comment is too short")
        }
        
        if trimmed.count > maxLength {
            return .invalid("Comment is too long (max \(maxLength) characters)")
        }
        
        // Check for spam patterns
        if containsSpam(trimmed) {
            return .invalid("Comment appears to be spam")
        }
        
        return .valid
    }
    
    private static func containsSpam(_ text: String) -> Bool {
        let lowerText = text.lowercased()
        let words = lowerText.components(separatedBy: .whitespaces)
        let uniqueWords = Set(words)
        
        if words.count > 5 && uniqueWords.count == 1 {
            return true
        }
        
        let capsCount = text.filter { $0.isUppercase }.count
        if Double(capsCount) / Double(text.count) > 0.7 && text.count > 10 {
            return true
        }
        
        return false
    }
    
    enum ValidationResult {
        case valid
        case invalid(String)
        
        var isValid: Bool {
            if case .valid = self {
                return true
            }
            return false
        }
        
        var errorMessage: String? {
            if case .invalid(let message) = self {
                return message
            }
            return nil
        }
    }
}

// MARK: - Comment Sorting
enum CommentSortOption: String, CaseIterable {
    case newest = "Newest First"
    case oldest = "Oldest First"
    case mostLiked = "Most Liked"
    
    func sort(_ comments: [Comment]) -> [Comment] {
        switch self {
        case .newest:
            return comments.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
        case .oldest:
            return comments.sorted { $0.timestamp.dateValue() < $1.timestamp.dateValue() }
        case .mostLiked:
            return comments.sorted { $0.likes > $1.likes }
        }
    }
}

// MARK: - Comment Filter
enum CommentFilter {
    case all
    case userComments(userId: String)
    case withReplies
    case withMinimumLikes(Int)
    
    func filter(_ comments: [Comment]) -> [Comment] {
        switch self {
        case .all:
            return comments
        case .userComments(let userId):
            return comments.filter { $0.userId == userId }
        case .withReplies:
            return comments.filter { ($0.replies?.isEmpty ?? true) == false }
        case .withMinimumLikes(let minimum):
            return comments.filter { $0.likes >= minimum }
        }
    }
}

// MARK: - Comment Formatting
extension Comment {
    var formattedTimestamp: String {
        let date = timestamp.dateValue()
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    var isRecent: Bool {
        let date = timestamp.dateValue()
        let hoursSince = Date().timeIntervalSince(date) / 3600
        return hoursSince < 24
    }
    
    var hasReplies: Bool {
        return (replies?.isEmpty ?? true) == false
    }
    
    var replyCount: Int {
        return replies?.count ?? 0
    }
}

// MARK: - User Comment Permissions
struct CommentPermissions {
    let canComment: Bool
    let canDelete: Bool
    let canEdit: Bool
    let canLike: Bool
    let canReply: Bool
    
    static func forUser(userId: String?, commentOwnerId: String) -> CommentPermissions {
        guard let userId = userId else {
            return CommentPermissions(
                canComment: false,
                canDelete: false,
                canEdit: false,
                canLike: false,
                canReply: false
            )
        }
        
        let isOwner = userId == commentOwnerId
        
        return CommentPermissions(
            canComment: true,
            canDelete: isOwner,
            canEdit: isOwner,
            canLike: !isOwner,
            canReply: true
        )
    }
}
