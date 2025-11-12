//
//  DailyMotionPlayerView.swift
//  Test3
//
//  Created by STUDENT on 8/29/25.
//

import SwiftUI
import WebKit

struct DailymotionPlayerView: UIViewRepresentable {
    
    /// The unique ID of the Dailymotion video to play.
    let videoID: String
    
    /// Creates and returns the WKWebView instance.
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []
        return webView
    }
    
    /// Updates the WKWebView with the correct Dailymotion URL.
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let urlString = "https://www.dailymotion.com/embed/video/\(videoID)"
        
        if let url = URL(string: urlString) {
            uiView.load(URLRequest(url: url))
        }
    }
}
