import SwiftUI
import WebKit

struct YouTubePlayerView: UIViewRepresentable {
    let videos: [String]
    @Binding var isPlaying: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = false
        config.allowsAirPlayForMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.backgroundColor = .black
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let firstVideo = videos.first else { return }
        
        let cleanVideoID = extractVideoID(from: firstVideo)
        
        if context.coordinator.currentVideoID != cleanVideoID {
                print("🎬 Loading YouTube video: \(cleanVideoID)")
                
                let allVideoIDs = videos
                    .map { extractVideoID(from: $0) }
                    .joined(separator: ",")
                
                let playlistQuery = allVideoIDs.isEmpty ? "" : "&playlist=\(allVideoIDs)"
                
            let urlString = """
            https://www.youtube.com/embed/\(cleanVideoID)?playsinline=1&modestbranding=1&rel=0&controls=1&fs=1&enablejsapi=1
            """
                
                if let url = URL(string: urlString) {
                    uiView.load(URLRequest(url: url))
                    context.coordinator.currentVideoID = cleanVideoID
                    context.coordinator.isReady = false
                }
            } else if context.coordinator.isReady {
            let command = isPlaying ? "player.playVideo();" : "player.pauseVideo();"
            uiView.evaluateJavaScript(command) { result, error in
                if let error = error {
                    print("⚠️ JS error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Helper to extract video ID from various YouTube URL formats
    private func extractVideoID(from urlString: String) -> String {
        // If it's already just an ID (11 characters), return it
        if urlString.count == 11 && !urlString.contains("/") && !urlString.contains("?") {
            return urlString
        }
        
        // Extract from full URL formats
        if let url = URL(string: urlString) {
            if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
               let videoID = queryItems.first(where: { $0.name == "v" })?.value {
                return videoID
            }
            
            // youtu.be/VIDEO_ID
            if url.host?.contains("youtube") == true {
                return url.lastPathComponent
            }
            
            // youtube.com/embed/VIDEO_ID
            if url.pathComponents.contains("embed"), url.pathComponents.count > 2 {
                return url.pathComponents[2]
            }
        }
        // Fallback: return as-is
        return urlString
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var currentVideoID: String?
        var isReady = false
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Small delay to ensure YouTube player API is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isReady = true
                print("✅ YouTube player iframe ready for \(self.currentVideoID ?? "unknown")")
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ YouTube player failed to load: \(error.localizedDescription)")
        }
    }
}
