//
//  VideoSource.swift
//  Rakio
//

import Foundation

// 1. Define the enum for source type
enum VideoSource: String {
    case youtube, dailymotion, unknown
}

// 2. Define the struct for the resulting data + unified detection
struct ThumbnailData {
    let url: String
    let source: VideoSource
    
    // Correct YouTube ID: 11 characters (letters, numbers, underscore, dash)
    private static let youtubePattern = #"^[a-zA-Z0-9_-]{11}$"#

    // Correct Dailymotion ID:
    // Always starts with "x", followed by 6–10 alphanumeric chars
    private static let dailymotionPattern = #"^x[a-zA-Z0-9]{6,10}$"#

    /// Unified source identification
    static func identifySource(_ videoID: String) -> VideoSource {
        if videoID.range(of: dailymotionPattern, options: .regularExpression) != nil {
            return .dailymotion
        }
        if videoID.range(of: youtubePattern, options: .regularExpression) != nil {
            return .youtube
        }
        return .unknown
    }

    /// Factory method: Infers the video source and generates the complete thumbnail data.
    static func generate(for videoID: String) -> ThumbnailData {
        let source = identifySource(videoID)
        let urlString: String

        switch source {
        case .youtube:
            urlString = "https://img.youtube.com/vi/\(videoID)/hqdefault.jpg"

        case .dailymotion:
            urlString = "https://www.dailymotion.com/thumbnail/video/\(videoID)"

        case .unknown:
            urlString = ""
        }

        return ThumbnailData(url: urlString, source: source)
    }
}
