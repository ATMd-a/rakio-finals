import SwiftUI
import WebKit

struct YouTubePlayerView: UIViewRepresentable {
    let videos: [String]
    @Binding var isPlaying: Bool
    
    func makeCoordinator() -> Coordinator {
            // Pass 'self' to the coordinator
            Coordinator(parent: self)
        }
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = false // ✅ Match Dailymotion behavior
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
        
        // Extract clean video ID (in case full URL is provided)
        let cleanVideoID = extractVideoID(from: firstVideo)
        
        // Only load once or when video changes
        if context.coordinator.currentVideoID != cleanVideoID {
            print("🎬 Loading YouTube video: \(cleanVideoID)")
            
            // 🚀 FIX: Create a single list of ALL video IDs for the 'playlist' parameter
            let allVideoIDs = videos
                .map { extractVideoID(from: $0) }
                .joined(separator: ",")
            
            // 💡 Change: We no longer need to check if it's empty, as the list always exists.
            // We use the first video ID in the URL path and ALL IDs in the playlist parameter.
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
            // Control playback via JavaScript
            let command = isPlaying ? "player.playVideo();" : "player.pauseVideo();"
            uiView.evaluateJavaScript(command) { result, error in
                if let error = error {
                    print("⚠️ JS error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // ✅ Helper to extract video ID from various YouTube URL formats
    private func extractVideoID(from urlString: String) -> String {
        // If it's already just an ID (11 characters), return it
        if urlString.count == 11 && !urlString.contains("/") && !urlString.contains("?") {
            return urlString
        }
        
        // Extract from full URL formats
        if let url = URL(string: urlString) {
            // youtube.com/watch?v=VIDEO_ID
            if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
               let videoID = queryItems.first(where: { $0.name == "v" })?.value {
                return videoID
            }
            
            // youtu.be/VIDEO_ID
            if url.host?.contains("youtu.be") == true {
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
        
        private let parent: YouTubePlayerView
        
        init(parent: YouTubePlayerView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Step 1: Initialize the API and define a callback function.
            let initializationScript = """
                    var player;
                    function onYouTubeIframeAPIReady() {
                        player = new YT.Player('player_container', {
                            videoId: '\(self.currentVideoID ?? "")',
                            events: {
                                'onReady': onPlayerReady,
                                'onError': onPlayerError
                            }
                        });
                    }
                
                    function onPlayerReady(event) {
                        // Step 2: Once the player is ready, load the playlist explicitly.
                        var videoIds = '\(self.parent.videos.map { self.parent.extractVideoID(from: $0) }.joined(separator: ","))'.split(',');
                        
                        // Use loadPlaylist and start playing the first video
                        event.target.loadPlaylist({
                            'playlist': videoIds,
                            'index': 0,
                            'startSeconds': 0
                        });
                        
                        window.webkit.messageHandlers.playerReady.postMessage('ready');
                    }
                    
                    function onPlayerError(event) {
                        window.webkit.messageHandlers.playerError.postMessage(event.data);
                    }
                """
            
            // The HTML structure the player needs
            let htmlContent = """
                <!DOCTYPE html>
                <html>
                <head>
                    <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'>
                    <style>
                        body { margin: 0; background-color: #000; }
                        #player_container { width: 100%; height: 100%; }
                    </style>
                </head>
                <body>
                    <div id="player_container"></div> 
                    <script src="https://www.youtube.com/iframe_api"></script>
                    <script>
                        \(initializationScript)
                    </script>
                </body>
                </html>
                """
            
            // This is not standard navigation, but loading the API framework.
            // It's safer to load the HTML content directly and trigger the API lifecycle.
            
            // Use a short delay to ensure the DOM is ready for the iframe API script to load.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                webView.loadHTMLString(htmlContent, baseURL: URL(string: "https://www.youtube.com"))
            }
        }
    }
}
