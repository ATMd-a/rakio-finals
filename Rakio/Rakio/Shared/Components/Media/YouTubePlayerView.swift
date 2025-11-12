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
        config.allowsPictureInPictureMediaPlayback = true
        config.allowsAirPlayForMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .black
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let firstVideo = videos.first else { return }
        
        // Only load once
        if !context.coordinator.didLoad {
            let playlistParam = videos.dropFirst().joined(separator: ",")
            let playlistQuery = playlistParam.isEmpty ? "" : "&playlist=\(playlistParam)"
            
            let urlString = "https://www.youtube.com/embed/\(firstVideo)?autoplay=1&playsinline=1&modestbranding=1&rel=0&enablejsapi=1\(playlistQuery)"
            
            if let url = URL(string: urlString) {
                uiView.load(URLRequest(url: url))
                context.coordinator.didLoad = true
            }
        } else if context.coordinator.isReady {
            // only evaluate JS when the player is ready
            let command = isPlaying ? "player.playVideo();" : "player.pauseVideo();"
            uiView.evaluateJavaScript(command) { result, error in
                if let error = error {
                    print("⚠️ JS error: \(error.localizedDescription)")
                }
            }
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var didLoad = false
        var isReady = false

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // YouTube iframe finished loading
            isReady = true
            print("✅ YouTube player iframe ready")
        }
    }
}
