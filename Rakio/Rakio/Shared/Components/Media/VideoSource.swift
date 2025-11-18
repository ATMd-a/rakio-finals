//
//  VideoSource.swift
//  Rakio
//

import Foundation

enum VideoSource: String {
    case youtube, dailymotion, unknown
}

struct ThumbnailData {
    let url: String
    let source: VideoSource
    
    private static let youtubePattern = #"^[a-zA-Z0-9_-]{11}$"#
    private static let dailymotionPattern = #"^x[a-zA-Z0-9]{6,10}$"#

    static func identifySource(_ videoID: String) -> VideoSource {
        if videoID.range(of: dailymotionPattern, options: .regularExpression) != nil {
            return .dailymotion
        }
        if videoID.range(of: youtubePattern, options: .regularExpression) != nil {
            return .youtube
        }
        return .unknown
    }

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
